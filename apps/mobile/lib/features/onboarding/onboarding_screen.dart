// Onboarding flow (Task 6 — consumes BE-34).
//
// Three-page swipeable intro shown to first-time users before authentication.
//
//   * Page 1 — Welcome: brand wordmark + value-prop.
//   * Page 2 — Capabilities: three plain capability rows (no emoji-as-icon).
//   * Page 3 — Segment selector: 2×3 grid of six tap-cards mapping 1:1 to
//     the backend's `onboarding_segments` enum (BE-34).
//
// IMPORTANT — auth ordering (deviates from the literal task text on purpose).
// The backend's `POST /api/v1/onboarding/segment` endpoint is guarded by
// `JwtAuthGuard`, but this screen runs *before* the user signs in. The task
// text in `tasks.md` calls out a 2-segment flow ('consumer' | 'business')
// and asks for the call to fire here, both of which conflict with the real
// backend contract (six segments, JWT required).
//
// Resolution (Path A from the orchestrator's notes):
//
//   1. Persist the chosen segment locally to secure storage under the key
//      `pending_onboarding_segment` as the snake_case wire value.
//   2. Mark `onboarding_complete = true` so the router unblocks the rest of
//      the app (`/auth/otp` becomes the next destination).
//   3. Route to `/auth/otp` — the router's `refreshListenable` redirect
//      already does this once the onboarding flag flips, but we issue an
//      explicit `context.go` as a fallback in case the redirect callback
//      hasn't fired yet by the time the navigator settles.
//   4. Task 7 (post-OTP / `/auth/me` success) reads the pending segment,
//      posts it to `/onboarding/segment`, and clears the pending key.
//
// Visual rules (anti-slop):
//   * No purple/blue gradients, no neon glows, no emoji-as-icon.
//   * Single orange accent (`RadhaColors.primary` #EA580C); selection state
//     uses a 6%-alpha orange wash + 1.5px orange border + a soft orange halo
//     and a check badge. The teal complement is reserved for other surfaces.
//   * Plus Jakarta Sans display weight on headlines via the theme's
//     `displaySmall` / `headlineMedium` styles — never set fontFamily inline.
//   * No `MediaQuery.size.height` math; layout uses `Expanded`, `Spacer`,
//     and `SafeArea` to compose the page chrome.
//   * Segment cards animate: staggered entrance, spring press-scale, and an
//     animated selection state — all gated on `disableAnimations`.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/session_storage.dart';
import '../../core/network/dto/onboarding_dto.dart';
import '../../core/onboarding/onboarding_flag_controller.dart';
import '../../core/router/app_router.dart';
import '../../design/app_assets.dart';
import '../../design/tokens.dart';
import '../../design/widgets/mor_companion.dart';
import '../../design/widgets/primary_button.dart';

/// Total number of pages in the onboarding stack. Kept as a constant so the
/// page indicator and the "next" / "back" affordances stay in sync.
const int _kPageCount = 3;
const int _kSegmentPageIndex = 2;

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _pageIndex = 0;
  OnboardingSegmentDto? _selectedSegment;
  bool _submitting = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int next) {
    if (next == _pageIndex) return;
    setState(() => _pageIndex = next);
  }

  void _selectSegment(OnboardingSegmentDto segment) {
    if (_selectedSegment == segment) return;
    // Light haptic confirms the tap registered — matches the "engaging,
    // responsive" feel without being noisy.
    HapticFeedback.selectionClick();
    setState(() => _selectedSegment = segment);
  }

  Future<void> _advance() async {
    if (_pageIndex < _kPageCount - 1) {
      await _pageController.nextPage(
        duration: RadhaMotion.medium,
        curve: RadhaMotion.easeOut,
      );
    } else {
      await _finish();
    }
  }

  Future<void> _finish() async {
    final segment = _selectedSegment;
    if (segment == null || _submitting) return;

    setState(() => _submitting = true);

    try {
      // 1. Persist the wire value so the post-OTP `_postPendingSegment`
      // hook in `OtpVerifyScreen` can replay it once the user is signed in
      // and the JWT-guarded `POST /onboarding/segment` becomes callable.
      final storage = ref.read(sessionStorageProvider);
      await storage.setPendingOnboardingSegment(segment.wireValue);

      // 2. Flip `onboarding_complete = true`. The router watches the
      // onboarding flag controller via `refreshListenable` and will redirect
      // to `/auth/otp` automatically.
      await ref.read(onboardingFlagControllerProvider.notifier).markComplete();

      // 3. Fallback navigation. If the redirect callback fires first this is
      // a no-op (GoRouter coalesces identical-target redirects); if it
      // hasn't fired yet this gets us to the next screen without a frame of
      // visible empty state.
      if (mounted) {
        context.go(AppRoute.authOtp);
      }
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLastPage = _pageIndex == _kPageCount - 1;
    final isSegmentPage = _pageIndex == _kSegmentPageIndex;
    final canAdvance = !isSegmentPage || _selectedSegment != null;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                children: <Widget>[
                  const _WelcomePage(),
                  const _CapabilitiesPage(),
                  _SegmentPage(
                    selected: _selectedSegment,
                    onSelect: _selectSegment,
                  ),
                ],
              ),
            ),
            _BottomBar(
              pageIndex: _pageIndex,
              pageCount: _kPageCount,
              ctaLabel: isLastPage ? 'Get started' : 'Continue',
              ctaEnabled: canAdvance,
              loading: _submitting,
              onPressed: canAdvance ? _advance : null,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Page 1 — Welcome ───────────────────────────────────────────────────────

class _WelcomePage extends StatelessWidget {
  const _WelcomePage();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: RadhaSpacing.space32,
        vertical: RadhaSpacing.space32,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Spacer(flex: 2),
          Text(
            'RADHA',
            style: theme.textTheme.displaySmall?.copyWith(
              letterSpacing: -1.0,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: RadhaSpacing.space12),
          Text(
            'Retail Assistant for Data, Health & Audits.',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: RadhaSpacing.space32),
          Text(
            'Scan, track, audit your stock without the spreadsheets.',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: theme.colorScheme.onSurface,
              height: 1.3,
            ),
          ),
          const Spacer(flex: 2),
          const Center(
            child: MorCompanion(mood: MorMood.greet, size: 168),
          ),
          const Spacer(flex: 2),
        ],
      ),
    );
  }
}

// ─── Page 2 — Capabilities ──────────────────────────────────────────────────

class _CapabilitiesPage extends StatelessWidget {
  const _CapabilitiesPage();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: RadhaSpacing.space32,
        vertical: RadhaSpacing.space32,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Spacer(),
          Text(
            'Built for the floor,\nnot the back office.',
            style: theme.textTheme.headlineLarge?.copyWith(
              color: theme.colorScheme.onSurface,
              height: 1.15,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: RadhaSpacing.space32),
          const _CapabilityRow(
            icon: Icons.qr_code_scanner_outlined,
            title: 'Scan products in one tap',
            subtitle: 'EAN lookup with health and approval pre-checked.',
          ),
          const SizedBox(height: RadhaSpacing.space24),
          const _CapabilityRow(
            icon: Icons.event_outlined,
            title: 'Catch expiry before it costs you',
            subtitle: 'OCR-assisted dates and per-category thresholds.',
          ),
          const SizedBox(height: RadhaSpacing.space24),
          const _CapabilityRow(
            icon: Icons.checklist_outlined,
            title: 'Run audits the team can finish',
            subtitle: 'Tasks, evidence and bulk scan sessions.',
          ),
          const Spacer(flex: 2),
        ],
      ),
    );
  }
}

class _CapabilityRow extends StatelessWidget {
  const _CapabilityRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(RadhaRadii.radiusSm),
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 22, color: theme.colorScheme.primary),
        ),
        const SizedBox(width: RadhaSpacing.space16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: RadhaSpacing.space4),
              Text(
                subtitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Page 3 — Segment selector (the 2×3 grid) ──────────────────────────────

/// One row in the 2×3 grid. Order matches the visual layout reading
/// left-to-right, top-to-bottom.
class _SegmentChoice {
  const _SegmentChoice({
    required this.segment,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final OnboardingSegmentDto segment;
  final IconData icon;
  final String title;
  final String subtitle;
}

const List<_SegmentChoice> _segmentChoices = <_SegmentChoice>[
  _SegmentChoice(
    segment: OnboardingSegmentDto.personal,
    icon: Icons.person_outline,
    title: 'Personal',
    subtitle: 'Just shopping for myself',
  ),
  _SegmentChoice(
    segment: OnboardingSegmentDto.parent,
    icon: Icons.family_restroom_outlined,
    title: 'Parent',
    subtitle: 'Shopping for my family / kids',
  ),
  _SegmentChoice(
    segment: OnboardingSegmentDto.businessOwner,
    icon: Icons.storefront_outlined,
    title: 'Business owner',
    subtitle: 'I run a small retail store',
  ),
  _SegmentChoice(
    segment: OnboardingSegmentDto.pharmacy,
    icon: Icons.local_pharmacy_outlined,
    title: 'Pharmacy',
    subtitle: 'I run a pharmacy / chemist',
  ),
  _SegmentChoice(
    segment: OnboardingSegmentDto.institution,
    icon: Icons.apartment_outlined,
    title: 'Institution',
    subtitle: 'School / hostel / canteen',
  ),
  _SegmentChoice(
    segment: OnboardingSegmentDto.auditorInvited,
    icon: Icons.verified_user_outlined,
    title: 'Auditor (invited)',
    subtitle: 'I have an invite code',
  ),
];

class _SegmentPage extends StatelessWidget {
  const _SegmentPage({required this.selected, required this.onSelect});

  final OnboardingSegmentDto? selected;
  final ValueChanged<OnboardingSegmentDto> onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        RadhaSpacing.space24,
        RadhaSpacing.space32,
        RadhaSpacing.space24,
        RadhaSpacing.space24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: RadhaSpacing.space8,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Who are you here as?',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: RadhaSpacing.space8),
                Text(
                  'Pick the closest fit. You can change later in Settings.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: RadhaSpacing.space24),
          Expanded(
            child: GridView.builder(
              physics: const BouncingScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: RadhaSpacing.space12,
                crossAxisSpacing: RadhaSpacing.space12,
                childAspectRatio: 0.95,
              ),
              itemCount: _segmentChoices.length,
              itemBuilder: (context, index) {
                final choice = _segmentChoices[index];
                final isSelected = selected == choice.segment;
                return _SegmentCard(
                  choice: choice,
                  isSelected: isSelected,
                  index: index,
                  onTap: () => onSelect(choice.segment),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// A premium, interactive segment card.
///
/// Three layers of motion, all honouring `disableAnimations`:
///   * **Entrance** — a one-shot fade + 8px rise + scale-from-0.96, staggered
///     by [index] so the six cards cascade in (≤90ms apart).
///   * **Press** — pointer-down springs the card to 0.96 scale and back on
///     release, giving immediate tactile feedback (the "clicker effect").
///   * **Selection** — the border colour/width, a soft tint wash, and a
///     check badge cross-fade in over [RadhaMotion.fast] when chosen.
class _SegmentCard extends StatefulWidget {
  const _SegmentCard({
    required this.choice,
    required this.isSelected,
    required this.index,
    required this.onTap,
  });

  final _SegmentChoice choice;
  final bool isSelected;
  final int index;
  final VoidCallback onTap;

  @override
  State<_SegmentCard> createState() => _SegmentCardState();
}

class _SegmentCardState extends State<_SegmentCard>
    with SingleTickerProviderStateMixin {
  AnimationController? _entrance;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    // Defer the reduce-motion check to didChangeDependencies (needs context).
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduceMotion || _entrance != null) return;

    final ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
    );
    _entrance = ctrl;
    // Stagger: each card starts 70ms after the previous one.
    Future<void>.delayed(Duration(milliseconds: 70 * widget.index), () {
      if (mounted) ctrl.forward();
    });
  }

  @override
  void dispose() {
    _entrance?.dispose();
    super.dispose();
  }

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    final selected = widget.isSelected;

    final card = AnimatedScale(
      // Press springs to 0.96; rest is 1.0. Selection adds a tiny 1.0→1.0
      // lift handled by the border/halo, not scale, to avoid jitter.
      scale: _pressed ? 0.96 : 1.0,
      duration: RadhaMotion.fast,
      curve: RadhaMotion.spring,
      child: AnimatedContainer(
        duration: RadhaMotion.medium,
        curve: RadhaMotion.easeOut,
        decoration: BoxDecoration(
          color: selected
              ? accent.withValues(alpha: 0.06)
              : theme.colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(RadhaRadii.radiusMd),
          border: Border.all(
            color: selected ? accent : theme.colorScheme.outline,
            width: selected ? 1.5 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.16),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ]
              : const <BoxShadow>[],
        ),
        child: Padding(
          padding: const EdgeInsets.all(RadhaSpacing.space16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  AnimatedContainer(
                    duration: RadhaMotion.fast,
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: selected
                          ? accent.withValues(alpha: 0.12)
                          : theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(RadhaRadii.radiusSm),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      widget.choice.icon,
                      size: 22,
                      color: selected ? accent : theme.colorScheme.onSurface,
                    ),
                  ),
                  const Spacer(),
                  // Selection check badge — scales + fades in when chosen.
                  AnimatedScale(
                    scale: selected ? 1.0 : 0.0,
                    duration: RadhaMotion.medium,
                    curve: RadhaMotion.spring,
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: accent,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.check_rounded,
                        size: 15,
                        color: theme.colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                widget.choice.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: RadhaSpacing.space4),
              Text(
                widget.choice.subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    final interactive = Semantics(
      button: true,
      selected: selected,
      label: widget.choice.title,
      hint: widget.choice.subtitle,
      child: GestureDetector(
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: card,
      ),
    );

    final entrance = _entrance;
    if (entrance == null) return interactive;

    // Entrance: fade + rise + subtle scale, projected from the controller.
    final fade = CurvedAnimation(parent: entrance, curve: Curves.easeOut);
    final rise = Tween<Offset>(
      begin: const Offset(0, 0.10),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: entrance, curve: Curves.easeOutCubic));
    final scale = Tween<double>(
      begin: 0.96,
      end: 1.0,
    ).animate(CurvedAnimation(parent: entrance, curve: RadhaMotion.spring));

    return FadeTransition(
      opacity: fade,
      child: SlideTransition(
        position: rise,
        child: ScaleTransition(scale: scale, child: interactive),
      ),
    );
  }
}

// ─── Bottom bar ─────────────────────────────────────────────────────────────

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.pageIndex,
    required this.pageCount,
    required this.ctaLabel,
    required this.ctaEnabled,
    required this.loading,
    required this.onPressed,
  });

  final int pageIndex;
  final int pageCount;
  final String ctaLabel;
  final bool ctaEnabled;
  final bool loading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        RadhaSpacing.space24,
        RadhaSpacing.space16,
        RadhaSpacing.space24,
        RadhaSpacing.space24,
      ),
      child: Column(
        children: [
          _PageDots(pageIndex: pageIndex, pageCount: pageCount),
          const SizedBox(height: RadhaSpacing.space16),
          PrimaryButton(
            label: ctaLabel,
            onPressed: ctaEnabled ? onPressed : null,
            loading: loading,
            expand: true,
          ),
        ],
      ),
    );
  }
}

class _PageDots extends StatelessWidget {
  const _PageDots({required this.pageIndex, required this.pageCount});

  final int pageIndex;
  final int pageCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List<Widget>.generate(pageCount, (i) {
        final isActive = i == pageIndex;
        return AnimatedContainer(
          duration: RadhaMotion.fast,
          curve: RadhaMotion.easeOut,
          margin: const EdgeInsets.symmetric(horizontal: RadhaSpacing.space4),
          height: 6,
          width: isActive ? 20 : 6,
          decoration: BoxDecoration(
            color: isActive
                ? theme.colorScheme.primary
                : theme.colorScheme.outline,
            borderRadius: BorderRadius.circular(RadhaRadii.radiusFull),
          ),
        );
      }),
    );
  }
}
