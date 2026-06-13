import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../design/tokens.dart';

/// Live-preview label camera with **auto-capture when steady**.
///
/// Streams frames and watches a cheap luminance signal; when the frame holds
/// still for a short window (the user has framed the label and stopped moving)
/// it auto-snaps a high-res still and pops it back to the caller. A manual
/// shutter and torch are always available. Returns the captured file path via
/// `Navigator.pop<String>`, or null if the user backs out.
///
/// Stability is approximated from the luminance plane (no ML Kit on the stream)
/// — robust across platforms and cheap enough to run every frame without jank.
class LabelCameraScreen extends StatefulWidget {
  const LabelCameraScreen({super.key});

  @override
  State<LabelCameraScreen> createState() => _LabelCameraScreenState();
}

class _LabelCameraScreenState extends State<LabelCameraScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  bool _ready = false;
  bool _capturing = false;
  bool _streaming = false;
  bool _torch = false;
  String? _error;

  // Stability detection.
  List<int>? _prevSample;
  int _steadyFrames = 0;
  DateTime? _startedAt;

  /// Consecutive steady frames required before auto-capture (~0.4s at 30fps).
  static const int _steadyNeeded = 12;

  /// Max mean per-sample luminance delta (0–255) still considered "steady".
  static const double _steadyThreshold = 4.0;

  /// Ignore the first moment so we don't fire before the user frames the label.
  static const Duration _warmup = Duration(milliseconds: 1200);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setup();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _teardownController();
    } else if (state == AppLifecycleState.resumed) {
      _setup();
    }
  }

  Future<void> _setup() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (mounted) setState(() => _error = 'No camera found on this device.');
        return;
      }
      final back = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        back,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );
      _controller = controller;
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      _startedAt = DateTime.now();
      _steadyFrames = 0;
      _prevSample = null;
      await controller.startImageStream(_onFrame);
      _streaming = true;
      setState(() {
        _ready = true;
        _error = null;
      });
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Camera unavailable. Go back and choose from gallery.',
        );
      }
    }
  }

  void _onFrame(CameraImage image) {
    if (_capturing || !_ready) return;
    if (_startedAt == null ||
        DateTime.now().difference(_startedAt!) < _warmup) {
      return;
    }
    final plane = image.planes.first.bytes;
    final n = plane.length;
    if (n == 0) return;

    final step = (n / 200).ceil();
    final sample = <int>[];
    for (var i = 0; i < n; i += step) {
      sample.add(plane[i]);
    }

    final prev = _prevSample;
    if (prev != null && prev.length == sample.length) {
      var sum = 0;
      for (var i = 0; i < sample.length; i++) {
        sum += (sample[i] - prev[i]).abs();
      }
      final diff = sum / sample.length;
      if (diff < _steadyThreshold) {
        _steadyFrames++;
      } else {
        _steadyFrames = 0;
      }
    }
    _prevSample = sample;

    if (_steadyFrames >= _steadyNeeded) {
      _capture();
    }
  }

  Future<void> _capture() async {
    final controller = _controller;
    if (_capturing || controller == null || !controller.value.isInitialized) {
      return;
    }
    _capturing = true;
    try {
      if (_streaming) {
        await controller.stopImageStream();
        _streaming = false;
      }
      HapticFeedback.mediumImpact();
      final file = await controller.takePicture();
      if (!mounted) return;
      Navigator.of(context).pop(file.path);
    } catch (_) {
      _capturing = false;
      _steadyFrames = 0;
      // Best-effort resume so the user can try again.
      if (mounted &&
          controller.value.isInitialized &&
          !_streaming) {
        try {
          await controller.startImageStream(_onFrame);
          _streaming = true;
        } catch (_) {
          /* leave manual shutter as the fallback */
        }
      }
    }
  }

  Future<void> _toggleTorch() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    HapticFeedback.selectionClick();
    _torch = !_torch;
    try {
      await controller.setFlashMode(_torch ? FlashMode.torch : FlashMode.off);
    } catch (_) {
      _torch = !_torch; // revert on failure
    }
    if (mounted) setState(() {});
  }

  Future<void> _teardownController() async {
    final controller = _controller;
    _controller = null;
    _ready = false;
    _streaming = false;
    if (controller != null) {
      try {
        if (controller.value.isStreamingImages) {
          await controller.stopImageStream();
        }
      } catch (_) {
        /* ignore */
      }
      await controller.dispose();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _teardownController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RadhaColors.ink,
      body: _error != null
          ? _ErrorView(message: _error!)
          : (!_ready || _controller == null)
              ? const Center(
                  child: CircularProgressIndicator(color: RadhaColors.primary),
                )
              : _buildPreview(context),
    );
  }

  Widget _buildPreview(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Stack(
      fit: StackFit.expand,
      children: [
        CameraPreview(_controller!),

        // Framing guide.
        IgnorePointer(
          child: Center(
            child: Container(
              width: 300,
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(color: RadhaColors.primary, width: 3),
                borderRadius: BorderRadius.circular(RadhaRadii.radiusLg),
              ),
            ),
          ),
        ),

        // Top bar: back + torch.
        Positioned(
          top: topPad + RadhaSpacing.space8,
          left: RadhaSpacing.space8,
          right: RadhaSpacing.space8,
          child: Row(
            children: [
              _RoundButton(
                icon: Icons.arrow_back_rounded,
                onTap: () => Navigator.of(context).maybePop(),
              ),
              const Spacer(),
              _RoundButton(
                icon: _torch ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                active: _torch,
                onTap: _toggleTorch,
              ),
            ],
          ),
        ),

        // Hint.
        Positioned(
          left: 0,
          right: 0,
          bottom: bottomPad + 132,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: RadhaSpacing.space16,
                vertical: RadhaSpacing.space8,
              ),
              decoration: BoxDecoration(
                color: RadhaColors.ink.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(RadhaRadii.radiusFull),
              ),
              child: Text(
                'Hold steady — it captures automatically',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: RadhaColors.onPrimary,
                ),
              ),
            ),
          ),
        ),

        // Manual shutter.
        Positioned(
          left: 0,
          right: 0,
          bottom: bottomPad + RadhaSpacing.space32,
          child: Center(
            child: Semantics(
              button: true,
              label: 'Capture',
              child: GestureDetector(
                onTap: _capture,
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: RadhaColors.onPrimary,
                    shape: BoxShape.circle,
                    border: Border.all(color: RadhaColors.primary, width: 4),
                  ),
                  child: const Icon(
                    Icons.camera_alt_rounded,
                    color: RadhaColors.primary,
                    size: 30,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.icon,
    required this.onTap,
    this.active = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? RadhaColors.primary : RadhaColors.ink.withValues(alpha: 0.5),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: kMinTouchTarget,
          height: kMinTouchTarget,
          child: Icon(icon, color: RadhaColors.onPrimary, size: 22),
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(RadhaSpacing.space24),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: _RoundButton(
                icon: Icons.arrow_back_rounded,
                onTap: () => Navigator.of(context).maybePop(),
              ),
            ),
            const Spacer(),
            const Icon(
              Icons.no_photography_outlined,
              size: 56,
              color: RadhaColors.paperMuted,
            ),
            const SizedBox(height: RadhaSpacing.space16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: RadhaColors.onPrimary,
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}
