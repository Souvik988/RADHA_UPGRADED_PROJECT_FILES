import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/network/api_exception.dart';
import '../../core/network/error_codes.dart';
import '../../core/router/app_router.dart';
import '../../design/app_assets.dart';
import '../../design/tokens.dart';
import '../../design/widgets/mor_companion.dart';
import '../../design/widgets/primary_button.dart';
import '../../l10n/generated/app_localizations.dart';

/// Formats a 10-digit Indian mobile number as `XXXXX XXXXX` for display.
class _IndianMobileFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final capped = digits.length > 10 ? digits.substring(0, 10) : digits;

    final buffer = StringBuffer();
    for (var i = 0; i < capped.length; i++) {
      if (i == 5) buffer.write(' ');
      buffer.write(capped[i]);
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// OTP request screen — first step in the auth flow. Collects a valid
/// 10-digit Indian mobile number and kicks off OTP delivery.
///
/// Polish + responsiveness:
///   * Content is wrapped in a `SingleChildScrollView` with a min-height
///     `ConstrainedBox` so the keyboard never overflows the layout and the
///     CTA stays reachable on short devices (the previous fixed `Column`
///     could overflow when the soft keyboard opened — a real bug).
///   * The phone field animates a 2px orange focus ring + soft `#FED7AA`
///     glow on focus, with a `+91` prefix separated by a hairline divider.
///   * Single orange accent; brand mark lockup; fine-print Terms/Privacy.
class OtpRequestScreen extends ConsumerStatefulWidget {
  const OtpRequestScreen({super.key});

  @override
  ConsumerState<OtpRequestScreen> createState() => _OtpRequestScreenState();
}

class _OtpRequestScreenState extends ConsumerState<OtpRequestScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  String? _errorText;
  bool _loading = false;
  bool _focused = false;

  String get _digits => _controller.text.replaceAll(RegExp(r'\D'), '');

  bool get _isValid =>
      _digits.length == 10 && RegExp(r'^[6-9]').hasMatch(_digits);

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChanged);
    _focusNode.addListener(_onFocusChanged);
  }

  void _onChanged() {
    if (_errorText != null) {
      setState(() => _errorText = null);
    }
    setState(() {});
  }

  void _onFocusChanged() {
    if (_focused == _focusNode.hasFocus) return;
    setState(() => _focused = _focusNode.hasFocus);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_isValid) {
      setState(() => _errorText = 'Enter a valid 10-digit mobile number');
      return;
    }

    HapticFeedback.lightImpact();
    setState(() {
      _loading = true;
      _errorText = null;
    });

    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations);

    try {
      final mobile = '+91$_digits';
      final result = await ref
          .read(authControllerProvider.notifier)
          .requestOtp(mobile);

      if (!mounted) return;

      context.push(
        AppRoute.authOtpVerify,
        extra: <String, String>{
          'mobile': mobile,
          'requestId': result.requestId,
          if (result.devOtp != null) 'devOtp': result.devOtp!,
        },
      );
    } on RateLimitException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorText = userMessageForCode(
          ErrorCodes.otpRateLimited,
          l10n: l10n,
          retryAfterSeconds: e.retryAfter,
        );
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorText = userMessageForCode(e.code, l10n: l10n, fallback: e.message);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorText = userMessageForCode(null, l10n: l10n);
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Use the local Navigator's pop state rather than GoRouter's
    // `context.canPop()`. Both are equivalent inside the app shell, but the
    // Navigator-based check also works when the screen is hosted directly in a
    // `MaterialApp` (e.g. widget tests) where no GoRouter is in scope.
    final canPop = Navigator.maybeOf(context)?.canPop() ?? false;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                RadhaSpacing.space24,
                RadhaSpacing.space16,
                RadhaSpacing.space24,
                RadhaSpacing.space24,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (canPop)
                        IconButton(
                          onPressed: _loading ? null : () => context.pop(),
                          icon: const Icon(Icons.arrow_back_rounded),
                          padding: EdgeInsets.zero,
                          alignment: Alignment.centerLeft,
                          color: theme.colorScheme.onSurface,
                        )
                      else
                        const SizedBox(height: RadhaSpacing.space8),
                      const SizedBox(height: RadhaSpacing.space24),
                      const _BrandLockup(),
                      const SizedBox(height: RadhaSpacing.space32),
                      Text(
                        'Sign in',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: RadhaColors.primary,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: RadhaSpacing.space8),
                      Text(
                        'Enter your\nmobile number',
                        style: theme.textTheme.displaySmall?.copyWith(
                          color: theme.colorScheme.onSurface,
                          height: 1.1,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: RadhaSpacing.space12),
                      Text(
                        "We'll send a 6-digit code to verify it's you.",
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: RadhaSpacing.space32),
                      Text('Mobile number', style: theme.textTheme.labelLarge),
                      const SizedBox(height: RadhaSpacing.space8),
                      _PhoneField(
                        controller: _controller,
                        focusNode: _focusNode,
                        focused: _focused,
                        enabled: !_loading,
                        hasError: _errorText != null,
                      ),
                      if (_errorText != null) ...[
                        const SizedBox(height: RadhaSpacing.space8),
                        Row(
                          children: [
                            Icon(
                              Icons.error_outline_rounded,
                              size: 16,
                              color: theme.colorScheme.error,
                            ),
                            const SizedBox(width: RadhaSpacing.space4),
                            Expanded(
                              child: Text(
                                _errorText!,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.error,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        const SizedBox(height: RadhaSpacing.space8),
                        Text(
                          'Standard SMS rates may apply.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                      const Spacer(),
                      const SizedBox(height: RadhaSpacing.space24),
                      PrimaryButton(
                        label: 'Send OTP',
                        expand: true,
                        loading: _loading,
                        onPressed: _isValid && !_loading ? _submit : null,
                      ),
                      const SizedBox(height: RadhaSpacing.space16),
                      const _LegalFinePrint(),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Compact brand lockup — orange mark tile + RADHA wordmark.
class _BrandLockup extends StatelessWidget {
  const _BrandLockup();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        const MorCompanion(
          mood: MorMood.greet,
          size: 40,
          animate: false,
          semanticLabel: 'RADHA',
        ),
        const SizedBox(width: RadhaSpacing.space12),
        Text(
          'RADHA',
          style: theme.textTheme.titleLarge?.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.0,
          ),
        ),
      ],
    );
  }
}

/// Phone input with an animated focus ring + soft glow and a `+91` prefix
/// separated by a hairline divider. Built as a custom container (rather than
/// relying solely on the theme's input border) so the focus halo can animate.
class _PhoneField extends StatelessWidget {
  const _PhoneField({
    required this.controller,
    required this.focusNode,
    required this.focused,
    required this.enabled,
    required this.hasError,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool focused;
  final bool enabled;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color borderColor = hasError
        ? theme.colorScheme.error
        : focused
        ? RadhaColors.primary
        : theme.colorScheme.outline;

    return AnimatedContainer(
      duration: RadhaMotion.fast,
      curve: RadhaMotion.easeOut,
      height: 56,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(RadhaRadii.radiusMd),
        border: Border.all(color: borderColor, width: focused || hasError ? 2 : 1),
        boxShadow: focused && !hasError
            ? [
                BoxShadow(
                  color: RadhaColors.primaryTint.withValues(alpha: 0.7),
                  blurRadius: 0,
                  spreadRadius: 3,
                ),
              ]
            : const <BoxShadow>[],
      ),
      child: Row(
        children: [
          const SizedBox(width: RadhaSpacing.space16),
          Text(
            '+91',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: RadhaSpacing.space12),
          Container(width: 1, height: 24, color: theme.colorScheme.outline),
          const SizedBox(width: RadhaSpacing.space12),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              enabled: enabled,
              keyboardType: TextInputType.phone,
              autofocus: true,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                _IndianMobileFormatter(),
              ],
              style: theme.textTheme.bodyLarge?.copyWith(
                letterSpacing: 1.0,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                isCollapsed: true,
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                hintText: '98765 43210',
                hintStyle: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  letterSpacing: 1.0,
                ),
              ),
            ),
          ),
          const SizedBox(width: RadhaSpacing.space16),
        ],
      ),
    );
  }
}

/// Bottom fine-print with tappable Terms / Privacy spans (orange).
class _LegalFinePrint extends StatelessWidget {
  const _LegalFinePrint();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
      height: 1.4,
    );
    final link = theme.textTheme.bodySmall?.copyWith(
      color: RadhaColors.primary,
      fontWeight: FontWeight.w600,
    );
    return Center(
      child: Text.rich(
        TextSpan(
          text: 'By continuing you agree to our ',
          style: muted,
          children: [
            TextSpan(text: 'Terms', style: link),
            TextSpan(text: ' & ', style: muted),
            TextSpan(text: 'Privacy', style: link),
            TextSpan(text: '.', style: muted),
          ],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
