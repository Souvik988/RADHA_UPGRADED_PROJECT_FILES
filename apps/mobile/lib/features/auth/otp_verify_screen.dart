import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pinput/pinput.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/auth/session_storage.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../../core/network/dto/onboarding_dto.dart';
import '../../core/network/error_codes.dart';
import '../../core/router/app_router.dart';
import '../../design/app_assets.dart';
import '../../design/tokens.dart';
import '../../design/widgets/mor_celebration.dart';
import '../../design/widgets/mor_companion.dart';
import '../../design/widgets/primary_button.dart';
import '../../l10n/generated/app_localizations.dart';

/// OTP verification screen — second step of the auth flow. Accepts a 6-digit
/// OTP, handles verification, resend cooldown, and post-login onboarding
/// segment submission.
///
/// Polish + responsiveness:
///   * Keyboard-safe `SingleChildScrollView` + min-height constraint so the
///     six boxes and the verify CTA stay reachable when the keypad opens.
///   * Premium Pinput theme: orange focus ring + soft `#FED7AA` glow, a
///     success-green border on submit, error shake feedback.
///   * Live resend countdown rendered in mono; haptic on auto-submit.
///   * Single orange accent; warm cream surface.
class OtpVerifyScreen extends ConsumerStatefulWidget {
  const OtpVerifyScreen({
    super.key,
    required this.mobile,
    required this.requestId,
  });

  final String mobile;
  final String requestId;

  @override
  ConsumerState<OtpVerifyScreen> createState() => _OtpVerifyScreenState();
}

class _OtpVerifyScreenState extends ConsumerState<OtpVerifyScreen> {
  final _pinController = TextEditingController();
  final _pinFocusNode = FocusNode();

  late String _requestId;
  String? _errorText;
  bool _loading = false;
  bool _verified = false;

  // Resend cooldown.
  int _resendSeconds = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _requestId = widget.requestId;
    _startCooldown();
  }

  void _startCooldown() {
    _resendSeconds = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        _resendSeconds--;
        if (_resendSeconds <= 0) t.cancel();
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pinController.dispose();
    _pinFocusNode.dispose();
    super.dispose();
  }

  /// Masks the mobile number: +91 •••••X XXXX (last 4 visible).
  String get _maskedMobile {
    final digits = widget.mobile.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 4) return widget.mobile;
    final last4 = digits.substring(digits.length - 4);
    final secondLast = digits.length >= 5 ? digits[digits.length - 5] : '';
    return '+91 •••••$secondLast $last4';
  }

  Future<void> _verify(String otp) async {
    if (otp.length != 6) return;

    HapticFeedback.lightImpact();
    setState(() {
      _loading = true;
      _errorText = null;
    });

    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations);

    try {
      await ref
          .read(authControllerProvider.notifier)
          .verifyOtp(mobile: widget.mobile, otp: otp, requestId: _requestId);

      if (!mounted) return;
      HapticFeedback.mediumImpact();
      setState(() => _verified = true);

      // Post pending onboarding segment (best-effort).
      await _postPendingSegment();

      // The router's refreshListenable should fire and redirect. Add a
      // fallback navigation after a short delay in case it doesn't.
      await Future<void>.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        context.go(AppRoute.home);
      }
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
      HapticFeedback.heavyImpact();
      _pinController.clear();
      final fallback = e is UnauthorizedException
          ? (l10n?.errorOtpInvalid ?? 'Invalid OTP. Please try again.')
          : e.message;
      setState(() {
        _errorText = userMessageForCode(e.code, l10n: l10n, fallback: fallback);
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

  Future<void> _postPendingSegment() async {
    try {
      final storage = ref.read(sessionStorageProvider);
      final pending = await storage.readPendingOnboardingSegment();
      if (pending == null) return;

      final segment = onboardingSegmentDtoFromWire(pending);
      if (segment == null) return;

      final api = ref.read(apiClientProvider);
      await api.selectOnboardingSegment(
        SelectSegmentRequestDto(segment: segment),
      );
      await storage.setPendingOnboardingSegment(null);
    } catch (_) {
      // Best-effort: swallow errors.
    }
  }

  Future<void> _resend() async {
    HapticFeedback.selectionClick();
    setState(() {
      _errorText = null;
      _loading = true;
    });

    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations);

    try {
      final result = await ref
          .read(authControllerProvider.notifier)
          .requestOtp(widget.mobile);
      if (!mounted) return;
      setState(() {
        _requestId = result.requestId;
      });
      _startCooldown();
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
      setState(
        () => _errorText = userMessageForCode(
          e.code,
          l10n: l10n,
          fallback: e.message,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _errorText = userMessageForCode(null, l10n: l10n));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final defaultPinTheme = PinTheme(
      width: 48,
      height: 56,
      textStyle: theme.textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.w700,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(RadhaRadii.radiusMd),
        border: Border.all(color: theme.colorScheme.outline),
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration?.copyWith(
        border: Border.all(color: RadhaColors.primary, width: 2),
        boxShadow: [
          BoxShadow(
            color: RadhaColors.primaryTint.withValues(alpha: 0.7),
            blurRadius: 0,
            spreadRadius: 3,
          ),
        ],
      ),
    );

    final submittedColor = _verified
        ? RadhaColors.success
        : (_errorText != null ? theme.colorScheme.error : RadhaColors.primary);
    final submittedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration?.copyWith(
        border: Border.all(color: submittedColor, width: 1.5),
      ),
    );

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
                      IconButton(
                        onPressed: _loading ? null : () => context.pop(),
                        icon: const Icon(Icons.arrow_back_rounded),
                        padding: EdgeInsets.zero,
                        alignment: Alignment.centerLeft,
                        color: theme.colorScheme.onSurface,
                      ),
                      const SizedBox(height: RadhaSpacing.space24),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              'Enter the code',
                              style: theme.textTheme.displaySmall?.copyWith(
                                color: theme.colorScheme.onSurface,
                                height: 1.1,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ),
                          const SizedBox(width: RadhaSpacing.space12),
                          // Mor watches you type, then celebrates on success —
                          // a full marigold petal burst on verify (win beat).
                          _verified
                              ? const MorCelebration(size: 76)
                              : const MorCompanion(
                                  mood: MorMood.work,
                                  size: 72,
                                ),
                        ],
                      ),
                      const SizedBox(height: RadhaSpacing.space12),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              'Sent to $_maskedMobile',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: _loading ? null : () => context.pop(),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: RadhaSpacing.space8,
                              ),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text('Edit'),
                          ),
                        ],
                      ),
                      const SizedBox(height: RadhaSpacing.space32),
                      Pinput(
                        controller: _pinController,
                        focusNode: _pinFocusNode,
                        length: 6,
                        enabled: !_loading,
                        autofocus: true,
                        // Keep the cursor static (no blink). The animated
                        // cursor drives a `repeat(reverse: true)` ticker that
                        // never settles, which hangs `pumpAndSettle` in tests
                        // and burns frames in production for no real benefit.
                        isCursorAnimationEnabled: false,
                        defaultPinTheme: defaultPinTheme,
                        focusedPinTheme: focusedPinTheme,
                        submittedPinTheme: submittedPinTheme,
                        onCompleted: _verify,
                        keyboardType: TextInputType.number,
                        separatorBuilder: (_) =>
                            const SizedBox(width: RadhaSpacing.space8),
                        cursor: Container(
                          width: 2,
                          height: 24,
                          decoration: BoxDecoration(
                            color: RadhaColors.primary,
                            borderRadius: BorderRadius.circular(
                              RadhaRadii.radiusFull,
                            ),
                          ),
                        ),
                      ),
                      if (_errorText != null) ...[
                        const SizedBox(height: RadhaSpacing.space16),
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
                      ],
                      const SizedBox(height: RadhaSpacing.space24),
                      _ResendRow(
                        seconds: _resendSeconds,
                        enabled: !_loading && _resendSeconds <= 0,
                        onResend: _resend,
                      ),
                      const Spacer(),
                      const SizedBox(height: RadhaSpacing.space24),
                      PrimaryButton(
                        label: 'Verify OTP',
                        expand: true,
                        loading: _loading,
                        onPressed: _loading
                            ? null
                            : () {
                                final text = _pinController.text;
                                if (text.length == 6) {
                                  _verify(text);
                                } else {
                                  _pinFocusNode.requestFocus();
                                }
                              },
                      ),
                      const SizedBox(height: RadhaSpacing.space12),
                      Center(
                        child: Text(
                          'Your number stays private.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
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

/// Resend row — live countdown in mono until the cooldown expires, then a
/// tappable "Resend code" link.
class _ResendRow extends StatelessWidget {
  const _ResendRow({
    required this.seconds,
    required this.enabled,
    required this.onResend,
  });

  final int seconds;
  final bool enabled;
  final VoidCallback onResend;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (seconds > 0) {
      return Text(
        'Resend OTP (${seconds}s)',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    }
    return TextButton(
      onPressed: enabled ? onResend : null,
      style: TextButton.styleFrom(
        padding: EdgeInsets.zero,
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        alignment: Alignment.centerLeft,
      ),
      child: const Text('Resend OTP'),
    );
  }
}
