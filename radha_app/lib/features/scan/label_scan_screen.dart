import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/entitlements/entitlement_provider.dart';
import '../../core/network/api_exception.dart';
import '../../core/network/dto/ai_dto.dart';
import '../../core/router/app_router.dart';
import '../../design/app_assets.dart';
import '../../design/tokens.dart';
import '../../design/widgets/mor_companion.dart';
import '../../design/widgets/primary_button.dart';
import '../../design/widgets/secondary_button.dart';
import 'data/label_analysis_cache.dart';
import 'data/label_analysis_repository.dart';
import 'data/label_ocr_service.dart';
import '../../l10n/generated/app_localizations.dart';
import 'label_camera_screen.dart';

/// "Scan the label" fallback (FE scanner-ocr).
///
/// Used when a barcode lookup misses or the bars won't read. The flow is the
/// layered, free-first fallback:
///
///   1. Capture a still (native camera → automatic flash/focus in low light)
///      or pick an existing photo from the gallery.
///   2. On-device OCR (ML Kit) — free, offline.
///   3. If the human-readable EAN digits are present, resolve via the normal
///      product lookup (a damaged barcode still wins).
///   4. Otherwise send the transcript to Gemini for a structured analysis —
///      the paid "AI label reading" payoff, gated behind the consumer plan.
class LabelScanScreen extends ConsumerStatefulWidget {
  const LabelScanScreen({super.key});

  @override
  ConsumerState<LabelScanScreen> createState() => _LabelScanScreenState();
}

enum _Stage { idle, processing, result, noText, locked, error }

class _LabelScanScreenState extends ConsumerState<LabelScanScreen> {
  final ImagePicker _picker = ImagePicker();

  _Stage _stage = _Stage.idle;
  String _processingLabel = 'Reading the label…';
  LabelTextAnalysis? _analysis;
  String? _requiredPlan;
  String _errorMessage = '';

  /// Auto-capture live camera (steady-detect) → process the captured still.
  Future<void> _takePhoto() async {
    HapticFeedback.selectionClick();
    final path = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(builder: (_) => const LabelCameraScreen()),
    );
    if (path == null || !mounted) return;
    await _processPath(path);
  }

  /// Pick an existing photo from the gallery → process it.
  Future<void> _pickFromGallery() async {
    HapticFeedback.selectionClick();
    final XFile? file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1600,
    );
    if (file == null || !mounted) return;
    await _processPath(file.path);
  }

  Future<void> _processPath(String path) async {
    setState(() {
      _stage = _Stage.processing;
      _processingLabel = 'Reading the label…';
    });

    try {
      final ocr = await ref.read(labelOcrServiceProvider).recognizeFile(path);
      if (!mounted) return;

      // (3) Damaged/unscannable barcode → resolve via its printed digits.
      if (ocr.candidateEans.isNotEmpty) {
        final ean = ocr.candidateEans.first;
        HapticFeedback.mediumImpact();
        context.pushReplacement('/scan/result/$ean');
        return;
      }

      // No readable text at all → honest "try again" state.
      if (!ocr.hasText) {
        setState(() => _stage = _Stage.noText);
        return;
      }

      // (4a) Instant + free if we've analyzed this label before this session.
      final cache = ref.read(labelAnalysisCacheProvider);
      final cached = cache.get(ocr.transcript);
      if (cached != null) {
        HapticFeedback.mediumImpact();
        setState(() {
          _analysis = cached;
          _stage = _Stage.result;
        });
        return;
      }

      // (4b) Text but no barcode → AI analysis, gated behind the consumer plan.
      final entitlement = ref.read(entitlementProvider).valueOrNull;
      final entitled =
          entitlement?.features.contains(Feature.ingredientExplainer) ?? false;
      if (!entitled) {
        setState(() {
          _stage = _Stage.locked;
          _requiredPlan = requiredPlanFor(Feature.ingredientExplainer);
        });
        return;
      }

      setState(() => _processingLabel = 'Analyzing ingredients…');
      final analysis = await ref
          .read(labelAnalysisRepositoryProvider)
          .analyzeTranscript(transcript: ocr.transcript);
      if (!mounted) return;

      if (!analysis.hasContent) {
        setState(() => _stage = _Stage.noText);
        return;
      }
      cache.put(ocr.transcript, analysis);
      HapticFeedback.mediumImpact();
      setState(() {
        _analysis = analysis;
        _stage = _Stage.result;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      // Backend also enforces the AI quota; a payment/forbidden status becomes
      // an upgrade nudge (the pre-call entitlement check is the primary gate).
      if (e.statusCode == 402 || e.statusCode == 403) {
        setState(() {
          _stage = _Stage.locked;
          _requiredPlan = requiredPlanFor(Feature.ingredientExplainer);
        });
      } else {
        setState(() {
          _stage = _Stage.error;
          _errorMessage = e.message;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _stage = _Stage.error;
        _errorMessage = 'Something went wrong. Please try again.';
      });
    }
  }

  void _reset() {
    setState(() {
      _stage = _Stage.idle;
      _analysis = null;
      _errorMessage = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        title: Text(
          'Scan the label',
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(child: _buildBody(theme)),
    );
  }

  Widget _buildBody(ThemeData theme) {
    switch (_stage) {
      case _Stage.processing:
        return _ProcessingView(label: _processingLabel);
      case _Stage.result:
        return _AnalysisResultView(analysis: _analysis!, onAgain: _reset);
      case _Stage.noText:
        return _MessageView(
          mood: MorMood.concern,
          title: AppLocalizations.of(context).labelScanReadError,
          message: AppLocalizations.of(context).labelScanReadErrorBody,
          primaryLabel: AppLocalizations.of(context).tryAgain,
          onPrimary: _reset,
        );
      case _Stage.locked:
        return _LockedView(plan: _requiredPlan ?? 'Plus', onBack: _reset);
      case _Stage.error:
        return _MessageView(
          mood: MorMood.concern,
          title: AppLocalizations.of(context).labelScanAnalysisFailed,
          message: _errorMessage,
          primaryLabel: AppLocalizations.of(context).tryAgain,
          onPrimary: _reset,
        );
      case _Stage.idle:
        return _IdleView(
          onCamera: _takePhoto,
          onGallery: _pickFromGallery,
        );
    }
  }
}

// ─── Idle: capture entry ─────────────────────────────────────────────────────

class _IdleView extends StatelessWidget {
  const _IdleView({required this.onCamera, required this.onGallery});

  final VoidCallback onCamera;
  final VoidCallback onGallery;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(RadhaSpacing.space24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: MorCompanion(
              mood: MorMood.greet,
              size: 104,
              semanticLabel: AppLocalizations.of(context).labelScanIntro,
            ),
          ),
          const SizedBox(height: RadhaSpacing.space24),
          Text(
            'No barcode? Read the label instead',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: RadhaSpacing.space8),
          Text(
            'Point at the ingredients panel — we\'ll read it and tell you what\'s '
            'inside. Works on products without a barcode.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: RadhaSpacing.space32),
          PrimaryButton(
            label: AppLocalizations.of(context).labelScanTakePhoto,
            icon: Icons.camera_alt_rounded,
            onPressed: onCamera,
          ),
          const SizedBox(height: RadhaSpacing.space12),
          SecondaryButton(
            label: AppLocalizations.of(context).labelScanChooseGallery,
            icon: Icons.photo_library_outlined,
            onPressed: onGallery,
          ),
          const SizedBox(height: RadhaSpacing.space20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.flash_auto_rounded,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: RadhaSpacing.space8),
              Flexible(
                child: Text(
                  'In low light your camera flash turns on automatically.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Processing ──────────────────────────────────────────────────────────────

class _ProcessingView extends StatelessWidget {
  const _ProcessingView({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: RadhaColors.primary),
          const SizedBox(height: RadhaSpacing.space24),
          Text(
            label,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Result ──────────────────────────────────────────────────────────────────

class _AnalysisResultView extends StatelessWidget {
  const _AnalysisResultView({required this.analysis, required this.onAgain});

  final LabelTextAnalysis analysis;
  final VoidCallback onAgain;

  bool get _lowConfidence => analysis.confidence > 0 && analysis.confidence < 0.4;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(RadhaSpacing.space20),
            children: [
              Text(
                analysis.productName?.isNotEmpty == true
                    ? analysis.productName!
                    : 'Label analysis',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (analysis.brand != null && analysis.brand!.isNotEmpty) ...[
                const SizedBox(height: RadhaSpacing.space4),
                Text(
                  analysis.brand!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              if (_lowConfidence) ...[
                const SizedBox(height: RadhaSpacing.space12),
                _Banner(
                  icon: Icons.info_outline_rounded,
                  text: 'Low confidence — a clearer photo may improve this.',
                ),
              ],
              if (analysis.summary != null && analysis.summary!.isNotEmpty) ...[
                const SizedBox(height: RadhaSpacing.space16),
                Container(
                  padding: const EdgeInsets.all(RadhaSpacing.space16),
                  decoration: BoxDecoration(
                    color: RadhaColors.primaryTint.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(RadhaRadii.radiusLg),
                  ),
                  child: Text(
                    analysis.summary!,
                    style: theme.textTheme.bodyLarge?.copyWith(height: 1.4),
                  ),
                ),
              ],
              if (analysis.healthFlags.isNotEmpty) ...[
                const SizedBox(height: RadhaSpacing.space24),
                _SectionTitle('What to watch'),
                const SizedBox(height: RadhaSpacing.space12),
                Wrap(
                  spacing: RadhaSpacing.space8,
                  runSpacing: RadhaSpacing.space8,
                  children: [
                    for (final flag in analysis.healthFlags) _FlagChip(flag),
                  ],
                ),
              ],
              if (analysis.allergens.isNotEmpty) ...[
                const SizedBox(height: RadhaSpacing.space24),
                _SectionTitle('Allergens'),
                const SizedBox(height: RadhaSpacing.space8),
                Text(
                  analysis.allergens.join(', '),
                  style: theme.textTheme.bodyMedium,
                ),
              ],
              if (analysis.ingredients.isNotEmpty) ...[
                const SizedBox(height: RadhaSpacing.space24),
                _SectionTitle('Ingredients'),
                const SizedBox(height: RadhaSpacing.space8),
                for (final ing in analysis.ingredients)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: RadhaSpacing.space4,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('•  '),
                        Expanded(
                          child: Text(ing, style: theme.textTheme.bodyMedium),
                        ),
                      ],
                    ),
                  ),
              ],
              const SizedBox(height: RadhaSpacing.space24),
              Text(
                'Read by RADHA AI from the label text. Always check the pack for '
                'the most accurate information.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(RadhaSpacing.space20),
          child: SecondaryButton(
            label: AppLocalizations.of(context).labelScanAnother,
            icon: Icons.refresh_rounded,
            onPressed: onAgain,
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _FlagChip extends StatelessWidget {
  const _FlagChip(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: RadhaSpacing.space12,
        vertical: RadhaSpacing.space8,
      ),
      decoration: BoxDecoration(
        color: RadhaColors.warning.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(RadhaRadii.radiusFull),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelMedium?.copyWith(
          color: RadhaColors.warning,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(RadhaSpacing.space12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(RadhaRadii.radiusMd),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: RadhaSpacing.space8),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Message / empty / error ─────────────────────────────────────────────────

class _MessageView extends StatelessWidget {
  const _MessageView({
    required this.mood,
    required this.title,
    required this.message,
    required this.primaryLabel,
    required this.onPrimary,
  });

  final MorMood mood;
  final String title;
  final String message;
  final String primaryLabel;
  final VoidCallback onPrimary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(RadhaSpacing.space24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          MorCompanion(mood: mood, size: 100, semanticLabel: title),
          const SizedBox(height: RadhaSpacing.space16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: RadhaSpacing.space8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: RadhaSpacing.space24),
          PrimaryButton(
            label: primaryLabel,
            icon: Icons.refresh_rounded,
            onPressed: onPrimary,
          ),
        ],
      ),
    );
  }
}

// ─── Locked (upgrade) ────────────────────────────────────────────────────────

class _LockedView extends StatelessWidget {
  const _LockedView({required this.plan, required this.onBack});

  final String plan;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(RadhaSpacing.space24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: RadhaColors.primaryTint.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(RadhaRadii.radiusLg),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              size: 34,
              color: RadhaColors.primaryDeep,
            ),
          ),
          const SizedBox(height: RadhaSpacing.space16),
          Text(
            'Unlock AI label reading',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: RadhaSpacing.space8),
          Text(
            'We read the label, but the full ingredient & health breakdown is part '
            'of $plan. Upgrade to see what\'s inside any product you photograph.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: RadhaSpacing.space24),
          PrimaryButton(
            label: AppLocalizations.of(context).labelScanSeePlans(plan),
            icon: Icons.workspace_premium_outlined,
            onPressed: () => context.push(AppRoute.subscription),
          ),
          const SizedBox(height: RadhaSpacing.space12),
          TextButton(
            onPressed: onBack,
            child: Text(AppLocalizations.of(context).labelScanMaybeLater),
          ),
        ],
      ),
    );
  }
}
