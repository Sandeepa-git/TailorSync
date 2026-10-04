import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/providers/api_provider.dart';
import '../../../../core/widgets/tailorsync_text_field.dart';
import '../../../../ui/ui.dart';
import '../providers/customers_provider.dart';
import '../../models/customer.dart';

class CustomerFormScreen extends ConsumerStatefulWidget {
  final Customer? customer;
  const CustomerFormScreen({super.key, this.customer});

  @override
  ConsumerState<CustomerFormScreen> createState() => _CustomerFormScreenState();
}

class _CustomerFormScreenState extends ConsumerState<CustomerFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  bool _loading = false;
  @override
  void initState() {
    super.initState();
    if (widget.customer != null) {
      _name.text = widget.customer!.name;
      _email.text = widget.customer!.email ?? '';
      _phone.text = widget.customer!.phone ?? '';
    }
  }
  void _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final api = ref.read(apiClientProvider);
    try {
      if (widget.customer == null) {
        await api.createCustomer({
          'name': _name.text,
          'email': _email.text,
          'phone': _phone.text,
        });
      } else {
        await api.updateCustomer(widget.customer!.id!, {
          'name': _name.text,
          'phone': _phone.text,
        });
      }
      ref.invalidate(customersProvider);
      if (!mounted) return;
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.customer != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Customer' : 'New Customer'),
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: TsFormBody(
        children: [
          EntranceFade(
            child: Center(
              child: Hero(
                tag: 'customer-${widget.customer?.id}',
                child: ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _name,
                  builder: (context, v, _) => v.text.trim().isEmpty
                      ? IconBadge(icon: Icons.person_add_alt_1_rounded, size: 72)
                      : InitialsAvatar(name: v.text, size: 72),
                ),
              ),
            ),
          ),
          const SizedBox(height: Space.sm),
          Text(
            isEdit ? 'Update client details' : 'Add a new client',
            textAlign: TextAlign.center,
            style: context.text.titleMedium,
          ),
          const SizedBox(height: Space.lg),
          TsCard(
            padding: const EdgeInsets.all(Space.lg),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  EntranceFade.indexed(
                    1,
                    child: TailorSyncTextField(
                      label: 'Full Name',
                      controller: _name,
                      icon: Icons.person_outline_rounded,
                      textCapitalization: TextCapitalization.words,
                      autofillHints: const [AutofillHints.name],
                      validator: (v) => v == null || v.isEmpty ? 'Name is required' : null,
                    ),
                  ),
                  const SizedBox(height: Space.md),
                  EntranceFade.indexed(
                    2,
                    child: TextFormField(
                      controller: _email,
                      readOnly: widget.customer != null, // Lock email field when editing
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.email],
                      style: context.text.bodyLarge,
                      decoration: InputDecoration(
                        labelText: 'Email Address',
                        prefixIcon: const Icon(Icons.alternate_email_rounded, size: 20),
                        suffixIcon: isEdit ? const Tooltip(message: 'Email can\'t be changed', child: Icon(Icons.lock_outline_rounded, size: 18)) : null,
                        helperText: isEdit ? 'Email is locked after creation' : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: Space.md),
                  EntranceFade.indexed(
                    3,
                    child: TailorSyncTextField(
                      label: 'Phone Number',
                      controller: _phone,
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      autofillHints: const [AutofillHints.telephoneNumber],
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) {
                        if (!_loading) _save();
                      },
                    ),
                  ),
                  const SizedBox(height: Space.xl),
                  TsButton(
                    label: 'Save Customer',
                    icon: Icons.check_rounded,
                    loading: _loading,
                    onPressed: _loading ? null : _save,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
