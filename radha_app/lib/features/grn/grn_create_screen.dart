import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_client.dart';
import '../../core/network/dto/grn_dto.dart';
import '../../design/tokens.dart';
import '../../design/widgets/primary_button.dart';

/// GRN creation screen — captures the header fields (supplier, invoice number,
/// invoice date, expected delivery) and creates a draft GRN via the API.
class GrnCreateScreen extends ConsumerStatefulWidget {
  const GrnCreateScreen({super.key});

  @override
  ConsumerState<GrnCreateScreen> createState() => _GrnCreateScreenState();
}

class _GrnCreateScreenState extends ConsumerState<GrnCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _supplierController = TextEditingController();
  final _invoiceNumberController = TextEditingController();

  DateTime? _invoiceDate;
  DateTime? _expectedDelivery;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _supplierController.dispose();
    _invoiceNumberController.dispose();
    super.dispose();
  }

  Future<void> _pickInvoiceDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _invoiceDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _invoiceDate = picked);
    }
  }

  Future<void> _pickExpectedDelivery() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expectedDelivery ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _expectedDelivery = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_invoiceDate == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Invoice date is required')));
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Known follow-up: route GRN-item add through
      // `syncServiceProvider.enqueue` so item additions queue when offline.
      // Tracked separately from the task-16 sync work, which currently
      // wires only `expiry_create_screen`.
      final client = ref.read(apiClientProvider);
      final response = await client.createGrn(
        CreateGrnDto(
          supplierId: _supplierController.text.trim(),
          invoiceNumber: _invoiceNumberController.text.trim(),
          invoiceDate: _invoiceDate!.toIso8601String(),
          expectedDeliveryDate: _expectedDelivery?.toIso8601String(),
        ),
      );

      if (!mounted) return;
      // Navigate to items screen with the new GRN ID.
      context.pushReplacement('/grn/${response.id}/items');
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not create the GRN. Please try again.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        title: Text(
          'New GRN',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(RadhaSpacing.space20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Supplier & invoice',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: RadhaSpacing.space20),

              // Supplier picker (text field for now).
              TextFormField(
                controller: _supplierController,
                decoration: const InputDecoration(
                  labelText: 'Supplier name',
                  hintText: 'Enter supplier name',
                  prefixIcon: Icon(Icons.business),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Supplier is required'
                    : null,
              ),
              const SizedBox(height: RadhaSpacing.space24),

              // Invoice number.
              TextFormField(
                controller: _invoiceNumberController,
                decoration: const InputDecoration(
                  labelText: 'Invoice number',
                  hintText: 'Enter invoice number',
                  prefixIcon: Icon(Icons.receipt),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Invoice number is required'
                    : null,
              ),
              const SizedBox(height: RadhaSpacing.space24),

              // Invoice date.
              _DatePickerField(
                label: 'Invoice date *',
                value: _invoiceDate,
                onTap: _pickInvoiceDate,
              ),
              const SizedBox(height: RadhaSpacing.space24),

              // Expected delivery date.
              _DatePickerField(
                label: 'Expected delivery date',
                value: _expectedDelivery,
                onTap: _pickExpectedDelivery,
              ),
              const SizedBox(height: RadhaSpacing.space32),

              // Submit button.
              PrimaryButton(
                label: 'Create Draft GRN',
                expand: true,
                loading: _isSubmitting,
                onPressed: _isSubmitting ? null : _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tappable read-only field that opens a date picker.
class _DatePickerField extends StatelessWidget {
  const _DatePickerField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final DateTime? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(RadhaRadii.radiusSm),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.calendar_today),
          suffixIcon: const Icon(Icons.arrow_drop_down),
        ),
        child: Text(
          value != null
              ? '${value!.day}/${value!.month}/${value!.year}'
              : 'Select date',
          style: TextStyle(
            color: value != null
                ? Theme.of(context).textTheme.bodyLarge?.color
                : Theme.of(context).colorScheme.outline,
          ),
        ),
      ),
    );
  }
}
