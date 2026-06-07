import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/router/app_router.dart';
import '../../design/theme.dart';
import '../../design/tokens.dart';
import 'utils/ean_validator.dart';

/// Local session-scoped scan history. Resets when the app is killed.
final _scanHistoryProvider = StateProvider<List<String>>((ref) => []);

/// Full-screen barcode scanner. A dimmed scrim with a clear centre cut-out
/// frames the live camera; orange corner brackets + an animated scan-line
/// guide the user. Flashlight toggle, "enter manually", and a scan-history
/// sheet round it out. On web (no camera API) it falls back to a manual EAN
/// entry screen.
class ScanScreen extends ConsumerStatefulWidget {
  const ScanScreen({super.key});

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends ConsumerState<ScanScreen> {
  MobileScannerController? _controller;
  bool _torchOn = false;
  bool _processing = false;

  final TextEditingController _webEanController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _controller = MobileScannerController(
        detectionSpeed: DetectionSpeed.normal,
        facing: CameraFacing.back,
      );
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _webEanController.dispose();
    super.dispose();
  }

  void _onBarcodeDetected(BarcodeCapture capture) {
    if (_processing) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode == null || barcode.rawValue == null) return;

    final code = barcode.rawValue!;
    if (!isValidEan(code)) return;

    _processing = true;
    HapticFeedback.mediumImpact();
    _controller?.stop();

    ref.read(_scanHistoryProvider.notifier).update((list) => [code, ...list]);

    context.push('/scan/result/$code').then((_) {
      if (mounted) {
        _processing = false;
        _controller?.start();
      }
    });
  }

  void _onWebLookup() {
    final code = _webEanController.text.trim();
    if (!isValidEan(code)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter a valid EAN-8, EAN-13, or UPC-A code'),
        ),
      );
      return;
    }
    HapticFeedback.mediumImpact();
    ref.read(_scanHistoryProvider.notifier).update((list) => [code, ...list]);
    context.push('/scan/result/$code');
  }

  void _toggleTorch() {
    HapticFeedback.selectionClick();
    _controller?.toggleTorch();
    setState(() => _torchOn = !_torchOn);
  }

  Future<void> _manualEntry() async {
    HapticFeedback.selectionClick();
    final code = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => const _ManualEntrySheet(),
    );
    if (code != null && code.isNotEmpty && mounted) {
      ref.read(_scanHistoryProvider.notifier).update((l) => [code, ...l]);
      if (mounted) context.push('/scan/result/$code');
    }
  }

  void _showHistory() {
    HapticFeedback.selectionClick();
    final history = ref.read(_scanHistoryProvider);
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => _ScanHistorySheet(history: history),
    );
  }

  void _openBulkAudit() {
    HapticFeedback.selectionClick();
    context.push(AppRoute.eanAudit);
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) return _buildWebFallback(context);
    return _buildCameraScanner(context);
  }

  Widget _buildCameraScanner(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: RadhaColors.ink,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Full-screen camera preview.
          MobileScanner(controller: _controller!, onDetect: _onBarcodeDetected),

          // Dimmed scrim with a clear centre cut-out + animated reticle.
          const Positioned.fill(child: _ScannerReticle()),

          // Translucent top bar: back, title, torch.
          Positioned(
            top: topPad + RadhaSpacing.space8,
            left: RadhaSpacing.space8,
            right: RadhaSpacing.space8,
            child: Row(
              children: [
                _CircularIconButton(
                  icon: Icons.arrow_back_rounded,
                  onTap: () {
                    if (context.canPop()) context.pop();
                  },
                ),
                Expanded(
                  child: Text(
                    'Scan a product',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: RadhaColors.onPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                _CircularIconButton(
                  icon: _torchOn
                      ? Icons.flash_on_rounded
                      : Icons.flash_off_rounded,
                  active: _torchOn,
                  onTap: _toggleTorch,
                ),
              ],
            ),
          ),

          // Helper pill below the frame.
          const Positioned(
            left: 0,
            right: 0,
            bottom: 188,
            child: Center(child: _HelperPill()),
          ),

          // Bottom controls: manual entry + bulk audit + scan history.
          Positioned(
            left: RadhaSpacing.space24,
            right: RadhaSpacing.space24,
            bottom: bottomPad + RadhaSpacing.space32,
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: RadhaSpacing.space12,
              runSpacing: RadhaSpacing.space12,
              children: [
                _PillTextButton(
                  icon: Icons.keyboard_rounded,
                  label: 'Enter manually',
                  onTap: _manualEntry,
                ),
                _PillTextButton(
                  icon: Icons.fact_check_outlined,
                  label: 'Bulk audit',
                  onTap: _openBulkAudit,
                ),
                _PillTextButton(
                  icon: Icons.history_rounded,
                  label: 'History',
                  onTap: _showHistory,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWebFallback(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Scan')),
      body: Padding(
        padding: const EdgeInsets.all(RadhaSpacing.space24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.qr_code_scanner_rounded,
              size: 64,
              color: RadhaColors.primary,
            ),
            const SizedBox(height: RadhaSpacing.space24),
            Text(
              'Camera scanning is not available on web.\nEnter a barcode manually:',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: RadhaSpacing.space24),
            TextField(
              controller: _webEanController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'EAN / UPC Code',
                hintText: 'e.g. 5901234123457',
              ),
              onSubmitted: (_) => _onWebLookup(),
            ),
            const SizedBox(height: RadhaSpacing.space16),
            SizedBox(
              height: kMinTouchTarget,
              width: double.infinity,
              child: FilledButton(
                onPressed: _onWebLookup,
                child: const Text('Lookup'),
              ),
            ),
            const SizedBox(height: RadhaSpacing.space16),
            TextButton.icon(
              onPressed: _showHistory,
              icon: const Icon(Icons.history),
              label: const Text('Scan history'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Reticle (scrim + cut-out + corners + scan line) ─────────────────────────

/// Paints a dark scrim over the camera with a clear rounded cut-out window,
/// orange corner brackets, and a vertical scan-line that sweeps up and down
/// inside the window. Honors `disableAnimations` (static line when reduced).
class _ScannerReticle extends StatefulWidget {
  const _ScannerReticle();

  @override
  State<_ScannerReticle> createState() => _ScannerReticleState();
}

class _ScannerReticleState extends State<_ScannerReticle>
    with SingleTickerProviderStateMixin {
  AnimationController? _ctrl;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduceMotion || _ctrl != null) return;
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = _ctrl;
    if (ctrl == null) {
      return IgnorePointer(
        child: CustomPaint(painter: _ReticlePainter(lineT: 0.5)),
      );
    }
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: ctrl,
        builder: (context, _) =>
            CustomPaint(painter: _ReticlePainter(lineT: ctrl.value)),
      ),
    );
  }
}

class _ReticlePainter extends CustomPainter {
  _ReticlePainter({required this.lineT});

  /// 0..1 vertical position of the scan line within the window.
  final double lineT;

  static const double _frame = 260;
  static const double _radius = 20;
  static const double _cornerLen = 30;
  static const double _cornerW = 4;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final rect = Rect.fromCenter(
      center: center,
      width: _frame,
      height: _frame,
    );
    final rrect = RRect.fromRectAndRadius(
      rect,
      const Radius.circular(_radius),
    );

    // Scrim with the window punched out.
    final scrim = Paint()..color = RadhaColors.ink.withValues(alpha: 0.62);
    final scrimPath = Path()
      ..addRect(Offset.zero & size)
      ..addRRect(rrect)
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(scrimPath, scrim);

    // Corner brackets.
    final corner = Paint()
      ..color = RadhaColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = _cornerW
      ..strokeCap = StrokeCap.round;
    final l = rect.left, t = rect.top, r = rect.right, b = rect.bottom;
    // top-left
    canvas.drawLine(Offset(l, t + _cornerLen), Offset(l, t + _radius), corner);
    canvas.drawLine(Offset(l + _radius, t), Offset(l + _cornerLen, t), corner);
    // top-right
    canvas.drawLine(Offset(r - _cornerLen, t), Offset(r - _radius, t), corner);
    canvas.drawLine(Offset(r, t + _radius), Offset(r, t + _cornerLen), corner);
    // bottom-left
    canvas.drawLine(Offset(l, b - _cornerLen), Offset(l, b - _radius), corner);
    canvas.drawLine(Offset(l + _radius, b), Offset(l + _cornerLen, b), corner);
    // bottom-right
    canvas.drawLine(Offset(r - _cornerLen, b), Offset(r - _radius, b), corner);
    canvas.drawLine(Offset(r, b - _cornerLen), Offset(r, b - _radius), corner);

    // Scan line — clipped to the window, with a soft gradient glow.
    canvas.save();
    canvas.clipRRect(rrect);
    final y = rect.top + 16 + (rect.height - 32) * lineT;
    final glow = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          RadhaColors.primary.withValues(alpha: 0.0),
          RadhaColors.primary.withValues(alpha: 0.28),
          RadhaColors.primary.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(rect.left, y - 18, rect.width, 36));
    canvas.drawRect(Rect.fromLTWH(rect.left, y - 18, rect.width, 36), glow);
    final line = Paint()
      ..color = RadhaColors.primary
      ..strokeWidth = 2;
    canvas.drawLine(Offset(rect.left + 8, y), Offset(rect.right - 8, y), line);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ReticlePainter old) => old.lineT != lineT;
}

// ─── Small UI pieces ─────────────────────────────────────────────────────────

class _HelperPill extends StatelessWidget {
  const _HelperPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: RadhaSpacing.space16,
        vertical: RadhaSpacing.space8,
      ),
      decoration: BoxDecoration(
        color: RadhaColors.ink.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(RadhaRadii.radiusFull),
      ),
      child: Text(
        'Align the barcode within the frame',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: RadhaColors.onPrimary,
        ),
      ),
    );
  }
}

/// 44pt+ circular icon button used in the top bar. Tints orange when active.
class _CircularIconButton extends StatelessWidget {
  const _CircularIconButton({
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
      color: active
          ? RadhaColors.primary
          : RadhaColors.ink.withValues(alpha: 0.5),
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

/// Translucent pill text-button for the bottom controls.
class _PillTextButton extends StatelessWidget {
  const _PillTextButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: RadhaColors.ink.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(RadhaRadii.radiusFull),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: RadhaSpacing.space16,
            vertical: RadhaSpacing.space12,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: RadhaColors.onPrimary, size: 18),
              const SizedBox(width: RadhaSpacing.space8),
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: RadhaColors.onPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Manual EAN entry bottom sheet — used as the "enter manually" path on the
/// camera scanner. Returns the entered code via `Navigator.pop`.
class _ManualEntrySheet extends StatefulWidget {
  const _ManualEntrySheet();

  @override
  State<_ManualEntrySheet> createState() => _ManualEntrySheetState();
}

class _ManualEntrySheetState extends State<_ManualEntrySheet> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final code = _controller.text.trim();
    if (!isValidEan(code)) {
      setState(() => _error = 'Enter a valid EAN-8, EAN-13, or UPC-A code');
      return;
    }
    Navigator.of(context).pop(code);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        RadhaSpacing.space24,
        RadhaSpacing.space24,
        RadhaSpacing.space24,
        RadhaSpacing.space24 + bottomInset,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Enter barcode', style: theme.textTheme.titleLarge),
          const SizedBox(height: RadhaSpacing.space16),
          TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'e.g. 5901234123457',
              errorText: _error,
            ),
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: RadhaSpacing.space16),
          SizedBox(
            width: double.infinity,
            height: kMinTouchTarget,
            child: FilledButton(
              onPressed: _submit,
              child: const Text('Look up'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bottom sheet listing this session's scan history.
class _ScanHistorySheet extends StatelessWidget {
  const _ScanHistorySheet({required this.history});

  final List<String> history;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: RadhaSpacing.space16,
          vertical: RadhaSpacing.space24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Scan history', style: theme.textTheme.titleLarge),
            const SizedBox(height: RadhaSpacing.space16),
            if (history.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: RadhaSpacing.space24,
                ),
                child: Center(
                  child: Text(
                    'No scans yet this session.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              )
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 320),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: history.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: RadhaSpacing.space8),
                  itemBuilder: (ctx, i) => Material(
                    color: theme.colorScheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(RadhaRadii.radiusMd),
                    child: ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(RadhaRadii.radiusMd),
                      ),
                      leading: const Icon(
                        Icons.qr_code_2_rounded,
                        color: RadhaColors.primary,
                      ),
                      title: Text(
                        history[i],
                        style: radhaMonoStyle(
                          fontSize: 14,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () {
                        Navigator.pop(ctx);
                        context.push('/scan/result/${history[i]}');
                      },
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
