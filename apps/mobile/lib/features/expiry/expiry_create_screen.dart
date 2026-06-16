import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/network/api_exception.dart';
import '../../core/network/dto/expiry_dto.dart';
import '../../core/offline/sync_service.dart';
import '../../core/router/app_router.dart';
import '../../design/app_assets.dart';
import '../../design/tokens.dart';
import '../../design/widgets/empty_state.dart';
import '../../design/widgets/mor_companion.dart';
import '../../design/widgets/primary_button.dart';
import 'ocr_date_helper.dart';

/// Screen for creating a new expiry record. Supports manual date entry
/// and an OCR-assisted camera path on mobile platforms.
class ExpiryCreateScreen extends ConsumerStatefulWidget {
  const ExpiryCreateScreen({super.key});

  @override
  ConsumerState<ExpiryCreateScreen> createState() => _ExpiryCreateScreenState();
}

class _ExpiryCreateScreenState extends ConsumerState<ExpiryCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _productIdController = TextEditingController();
  final _batchController = TextEditingController();
  final _quantityController = TextEditingController();
  final _locationController = TextEditingController();

  DateTime? _mfgDate;
  DateTime? _expiryDate;
  String? _dateError;
  bool _loading = false;

  /// Whether the device supports on-device camera OCR.
  bool get _canUseCamera {
    if (kIsWeb) return false;
    return Platform.isAndroid || Platform.isIOS;
  }

  @override
  void dispose() {
    _productIdController.dispose();
    _batchController.dispose();
    _quantityController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _validateDates() {
    if (_mfgDate != null &&
        _expiryDate != null &&
        _mfgDate!.isAfter(_expiryDate!)) {
      setState(
        () => _dateError = 'Manufacturing date cannot be after expiry date',
      );
    } else {
      setState(() => _dateError = null);
    }
  }

  Future<void> _pickDate({required bool isMfg}) async {
    final now = DateTime.now();
    final initial = isMfg ? (_mfgDate ?? now) : (_expiryDate ?? now);
    final first = DateTime(2000);
    final last = DateTime(2100);

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: last,
      helpText: isMfg ? 'Select manufacturing date' : 'Select expiry date',
    );
    if (picked == null) return;

    setState(() {
      if (isMfg) {
        _mfgDate = picked;
      } else {
        _expiryDate = picked;
      }
    });
    _validateDates();
  }

  Future<void> _useCamera() async {
    final result = await OcrDateHelper.extractDates(context, ref);
    if (result == null || !mounted) return;

    setState(() {
      if (result.mfgDate != null) _mfgDate = result.mfgDate;
      if (result.expiryDate != null) _expiryDate = result.expiryDate;
    });
    _validateDates();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final storeId = ref.read(currentUserProvider)?.selectedStoreId;
    if (storeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a store before saving expiry.')),
      );
      return;
    }
    if (_expiryDate == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Expiry date is required')));
      return;
    }
    if (_dateError != null) return;

    setState(() => _loading = true);

    try {
      final dto = CreateExpiryDto(
        productId: _productIdController.text.trim(),
        storeId: storeId,
        expiryDate: _expiryDate!.toIso8601String().split('T').first,
        manufactureDate: _mfgDate?.toIso8601String().split('T').first,
        batchNumber: _batchController.text.trim().isEmpty
            ? null
            : _batchController.text.trim(),
        quantity: int.tryParse(_quantityController.text.trim()),
        shelfLocation: _locationController.text.trim().isEmpty
            ? null
            : _locationController.text.trim(),
      );

      // Route through the offline-first queue (Task 16). Successful 2xx
      // responses go straight through; offline / 5xx responses are
      // persisted in `pending_writes` and surfaced via the
      // [SyncStatusBanner].
      final result = await ref
          .read(syncServiceProvider)
          .enqueue<void>(
            endpoint: '/api/v1/expiry-records',
            method: 'POST',
            body: dto.toJson(),
          );
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.synced
                ? 'Expiry record created'
                : 'You\'re offline — record will sync when you\'re back online',
          ),
        ),
      );
      Navigator.of(context).pop();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Something went wrong. Please try again.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Not set';
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = ref.watch(authControllerProvider);
    final selectedStoreId = auth.valueOrNull?.selectedStoreId;
    final canSelectStore = auth.valueOrNull?.stores.isNotEmpty ?? false;

    if (!auth.isLoading && selectedStoreId == null) {
      return _ExpiryCreateNeedsStore(canSelectStore: canSelectStore);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('New Expiry Record')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: RadhaSpacing.space24,
            vertical: RadhaSpacing.space24,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Prominent OCR helper card (mobile only) — the fast path.
                if (_canUseCamera) ...[
                  _OcrHelperCard(onTap: _loading ? null : _useCamera),
                  const SizedBox(height: RadhaSpacing.space24),
                ],

                // Product ID
                Text('Product ID', style: theme.textTheme.labelLarge),
                const SizedBox(height: RadhaSpacing.space8),
                TextFormField(
                  controller: _productIdController,
                  enabled: !_loading,
                  decoration: const InputDecoration(
                    hintText: 'Enter product ID or scan barcode',
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: RadhaSpacing.space24),

                // MFG Date
                Text('Manufacturing Date', style: theme.textTheme.labelLarge),
                const SizedBox(height: RadhaSpacing.space8),
                _DatePickerTile(
                  label: _formatDate(_mfgDate),
                  onTap: _loading ? null : () => _pickDate(isMfg: true),
                ),
                const SizedBox(height: RadhaSpacing.space24),

                // Expiry Date
                Text('Expiry Date *', style: theme.textTheme.labelLarge),
                const SizedBox(height: RadhaSpacing.space8),
                _DatePickerTile(
                  label: _formatDate(_expiryDate),
                  onTap: _loading ? null : () => _pickDate(isMfg: false),
                ),

                // Date validation error
                if (_dateError != null) ...[
                  const SizedBox(height: RadhaSpacing.space8),
                  Text(
                    _dateError!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: RadhaColors.danger,
                    ),
                  ),
                ],
                const SizedBox(height: RadhaSpacing.space24),

                // Batch number
                Text('Batch Number', style: theme.textTheme.labelLarge),
                const SizedBox(height: RadhaSpacing.space8),
                TextFormField(
                  controller: _batchController,
                  enabled: !_loading,
                  decoration: const InputDecoration(hintText: 'Optional'),
                ),
                const SizedBox(height: RadhaSpacing.space24),

                // Quantity
                Text('Quantity', style: theme.textTheme.labelLarge),
                const SizedBox(height: RadhaSpacing.space8),
                TextFormField(
                  controller: _quantityController,
                  enabled: !_loading,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(hintText: 'Optional'),
                ),
                const SizedBox(height: RadhaSpacing.space24),

                // Location
                Text('Location', style: theme.textTheme.labelLarge),
                const SizedBox(height: RadhaSpacing.space8),
                TextFormField(
                  controller: _locationController,
                  enabled: !_loading,
                  decoration: const InputDecoration(
                    hintText: 'Shelf / aisle / zone',
                  ),
                ),
                const SizedBox(height: RadhaSpacing.space32),

                // Submit
                PrimaryButton(
                  label: 'Save Record',
                  expand: true,
                  loading: _loading,
                  onPressed: _loading || _dateError != null ? null : _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Shown when a user reaches expiry creation without a selected store.
class _ExpiryCreateNeedsStore extends StatelessWidget {
  const _ExpiryCreateNeedsStore({required this.canSelectStore});

  final bool canSelectStore;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Expiry Record')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(RadhaSpacing.space16),
            child: EmptyState(
              illustration: const MorCompanion(
                mood: MorMood.concern,
                size: 104,
              ),
              title: 'No store selected',
              body:
                  'Expiry records are store-scoped. Select a store before adding expiry dates.',
              actionLabel: canSelectStore ? 'Select store' : 'Contact manager',
              actionIcon: canSelectStore
                  ? Icons.storefront_outlined
                  : Icons.support_agent_outlined,
              onAction: () {
                if (canSelectStore) {
                  context.push(AppRoute.selectStore);
                  return;
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Ask your manager to add you to a store.'),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// Prominent OCR helper card — the recommended fast path for entering dates.
class _OcrHelperCard extends StatelessWidget {
  const _OcrHelperCard({required this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(RadhaRadii.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(RadhaRadii.radiusMd),
        child: Container(
          padding: const EdgeInsets.all(RadhaSpacing.space16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(RadhaRadii.radiusMd),
            border: Border.all(color: theme.colorScheme.outline),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 44,
                height: 44,
                child: MorCompanion(
                  mood: MorMood.think,
                  size: 44,
                  semanticLabel: 'RADHA reads the date for you',
                ),
              ),
              const SizedBox(width: RadhaSpacing.space12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Scan the date off the pack',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: RadhaSpacing.space2),
                    Text(
                      "We'll read MFG / EXP for you",
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tappable row that displays a date value and opens the date picker on tap.
class _DatePickerTile extends StatelessWidget {
  const _DatePickerTile({required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      borderRadius: BorderRadius.circular(RadhaRadii.radiusSm),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: RadhaSpacing.space16,
          vertical: RadhaSpacing.space12,
        ),
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.outline),
          borderRadius: BorderRadius.circular(RadhaRadii.radiusSm),
        ),
        child: Row(
          children: [
            Expanded(child: Text(label, style: theme.textTheme.bodyLarge)),
            Icon(
              Icons.calendar_today_outlined,
              size: 20,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
