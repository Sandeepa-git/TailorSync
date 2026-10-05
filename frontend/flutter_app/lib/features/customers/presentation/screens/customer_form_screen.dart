import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/providers/api_provider.dart';
import '../../../../ui/ui.dart';
import '../../models/customer.dart';
import '../providers/customers_provider.dart';

/// Add / edit customer.
/// Friendly form: clear sections, required markers, helper text, live
/// validation, a live preview card, and a Save bar that stays above the
/// keyboard. Asks before discarding unsaved changes.
class CustomerFormScreen extends ConsumerStatefulWidget {
  final Customer? customer;
  const CustomerFormScreen({super.key, this.customer});

  @override
  ConsumerState<CustomerFormScreen> createState() => _CustomerFormScreenState();
}

class _CustomerFormScreenState extends ConsumerState<CustomerFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _address = TextEditingController();
  final _phoneFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _addressFocus = FocusNode();
  bool _loading = false;
  bool _submitted = false;
  bool _leaving = false;
  late final String _initial;

  bool get _isEdit => widget.customer != null;

  @override
  void initState() {
    super.initState();
    final c = widget.customer;
    if (c != null) {
      _name.text = c.name;
      _phone.text = c.phone ?? '';
      _email.text = c.email ?? '';
      _address.text = c.address ?? '';
    }
    _initial = _snapshot();
    for (final ctrl in [_name, _phone, _email, _address]) {
      ctrl.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    for (final c in [_name, _phone, _email, _address]) {
      c.dispose();
    }
    _phoneFocus.dispose();
    _emailFocus.dispose();
    _addressFocus.dispose();
    super.dispose();
  }

  String _snapshot() => [_name.text, _phone.text, _email.text, _address.text].join('|');
  bool get _dirty => _snapshot() != _initial;

  // ---------- validation ----------
  String? _validateName(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return 'Please enter the customer\'s name';
    if (s.length < 2) return 'Name looks too short';
    return null;
  }

  String? _validatePhone(String? v) {
    final s = (v ?? '').replaceAll(RegExp(r'[\s-]'), '');
    if (s.isEmpty) return 'Please enter a phone number so you can contact the customer';
    final local = RegExp(r'^0\d{9}$');
    final intl = RegExp(r'^\+94\d{9}$');
    if (!local.hasMatch(s) && !intl.hasMatch(s)) return 'Use 10 digits, e.g. 0771234567 or +94771234567';
    return null;
  }

  String? _validateEmail(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return null; // optional
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(s)) return 'Enter a valid email, e.g. name@gmail.com';
    return null;
  }

  // ---------- actions ----------
  String _friendlyError(Object e) {
    if (e is DioException) {
      final d = e.response?.data;
      if (d is Map && d['detail'] != null) {
        final detail = d['detail'];
        if (detail is String) return detail;
        return 'Some details are not valid. Please check the form.';
      }
      if (e.type == DioExceptionType.connectionError || e.type == DioExceptionType.connectionTimeout) {
        return 'No connection. Check your internet and try again.';
      }
      return 'Could not save (error ${e.response?.statusCode ?? ''}). Please try again.';
    }
    return 'Something went wrong. Please try again.';
  }

  Future<void> _save() async {
    setState(() => _submitted = true);
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) {
      HapticFeedback.mediumImpact();
      return;
    }
    setState(() => _loading = true);
    final api = ref.read(apiClientProvider);
    String? orNull(String s) => s.trim().isEmpty ? null : s.trim();
    final payload = {
      'name': _name.text.trim(),
      'phone': _phone.text.replaceAll(RegExp(r'[\s-]'), ''),
      'email': orNull(_email.text),
      'address': orNull(_address.text),
    };
    try {
      if (_isEdit) {
        payload.remove('email'); // email is locked after creation
        await api.updateCustomer(widget.customer!.id!, payload);
      } else {
        await api.createCustomer(payload);
      }
      ref.invalidate(customersProvider);
      if (!mounted) return;
      showToast(context, _isEdit ? 'Customer updated' : '${_name.text.trim()} added to your customers',
          type: ToastType.success);
      _leave();
    } catch (e) {
      if (mounted) showToast(context, _friendlyError(e), type: ToastType.error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _leave() {
    setState(() => _leaving = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.pop();
    });
  }

  Future<void> _close() async {
    if (_dirty && !_loading) {
      final discard = await confirmDialog(
        context,
        title: 'Discard changes?',
        message: 'The details you entered will not be saved.',
        confirmLabel: 'Discard',
        cancelLabel: 'Keep editing',
        destructive: true,
      );
      if (!discard || !mounted) return;
    }
    if (mounted) _leave();
  }

  // ---------- UI ----------
  Widget _field({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    String? hint,
    String? helper,
    bool required = false,
    bool readOnly = false,
    TextInputType? keyboard,
    TextInputAction action = TextInputAction.next,
    FocusNode? focus,
    FocusNode? next,
    String? Function(String?)? validator,
    Iterable<String>? autofill,
    TextCapitalization caps = TextCapitalization.none,
    List<TextInputFormatter>? formatters,
    int maxLines = 1,
    Widget? suffix,
  }) {
    final cs = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 6),
            child: Text.rich(TextSpan(children: [
              TextSpan(text: label, style: context.text.labelLarge?.copyWith(color: cs.onSurface)),
              if (required) TextSpan(text: ' *', style: context.text.labelLarge?.copyWith(color: cs.error)),
              if (!required && !readOnly)
                TextSpan(text: '  (optional)', style: context.text.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
            ])),
          ),
          TextFormField(
            controller: controller,
            focusNode: focus,
            readOnly: readOnly,
            keyboardType: keyboard,
            textInputAction: action,
            textCapitalization: caps,
            inputFormatters: formatters,
            autofillHints: autofill,
            maxLines: maxLines,
            minLines: 1,
            validator: validator,
            autovalidateMode: _submitted ? AutovalidateMode.always : AutovalidateMode.onUserInteraction,
            scrollPadding: const EdgeInsets.only(bottom: 160),
            style: context.text.bodyLarge,
            onFieldSubmitted: (_) {
              if (next != null) {
                next.requestFocus();
              } else if (action == TextInputAction.done && !_loading) {
                _save();
              }
            },
            decoration: InputDecoration(
              hintText: hint,
              helperText: helper,
              helperMaxLines: 2,
              errorMaxLines: 2,
              prefixIcon: Icon(icon, size: 20),
              suffixIcon: suffix ??
                  (readOnly || controller.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Clear',
                          icon: const Icon(Icons.close_rounded, size: 18),
                          onPressed: () => controller.clear(),
                        )),
              fillColor: readOnly ? cs.surfaceContainerHigh : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _previewCard() {
    final name = _name.text.trim();
    final phone = _phone.text.trim();
    final email = _email.text.trim();
    return Container(
      padding: const EdgeInsets.all(Space.md),
      decoration: BoxDecoration(gradient: Gradients.hero(context.colors), borderRadius: Radii.brXl, boxShadow: Shadows.raised(context.colors)),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 2)),
            child: name.isEmpty
                ? const Icon(Icons.person_add_alt_1_rounded, color: Colors.white)
                : Text(
                    name.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).take(2).map((p) => p[0].toUpperCase()).join(),
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
                  ),
          ),
          const SizedBox(width: Space.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name.isEmpty ? (_isEdit ? 'Customer name' : 'New customer') : name,
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: context.text.titleLarge?.copyWith(color: Colors.white)),
                const SizedBox(height: 2),
                Text(
                  [if (phone.isNotEmpty) phone, if (email.isNotEmpty) email].join('  •  ').isEmpty
                      ? 'Fill in the details below'
                      : [if (phone.isNotEmpty) phone, if (email.isNotEmpty) email].join('  •  '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.bodySmall?.copyWith(color: Colors.white.withValues(alpha: 0.85)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(String title, IconData icon, List<Widget> fields) {
    final cs = context.colors;
    return TsCard(
      padding: const EdgeInsets.fromLTRB(Space.md, Space.md, Space.md, Space.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            Icon(icon, size: 18, color: cs.primary),
            const SizedBox(width: Space.xs),
            Text(title, style: context.text.titleSmall?.copyWith(color: cs.primary)),
          ]),
          const SizedBox(height: Space.md),
          ...fields,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return PopScope(
      canPop: !_dirty || _leaving,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _close();
      },
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          leading: IconButton(tooltip: 'Close', icon: const Icon(Icons.close_rounded), onPressed: _close),
          title: Text(_isEdit ? 'Edit Customer' : 'New Customer',
              style: context.text.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
        ),
        body: Stack(
          fit: StackFit.expand,
          children: [
            const PageBackdrop(),
            GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () => FocusScope.of(context).unfocus(),
              child: SingleChildScrollView(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.fromLTRB(context.pagePadding, Space.sm, context.pagePadding, Space.xl),
                child: MaxWidthBox(
                  maxWidth: MaxWidth.form,
                  child: AutofillGroup(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          EntranceFade(child: _previewCard()),
                          const SizedBox(height: Space.md),
                          EntranceFade.indexed(
                            1,
                            child: _section('Basic details', Icons.badge_outlined, [
                              _field(
                                label: 'Full name',
                                controller: _name,
                                icon: Icons.person_outline_rounded,
                                hint: 'e.g. Kasun Perera',
                                required: true,
                                caps: TextCapitalization.words,
                                autofill: const [AutofillHints.name],
                                next: _phoneFocus,
                                validator: _validateName,
                              ),
                              _field(
                                label: 'Phone number',
                                controller: _phone,
                                focus: _phoneFocus,
                                next: _emailFocus,
                                icon: Icons.phone_outlined,
                                hint: '07X XXX XXXX',
                                helper: 'Used to contact the customer about their order',
                                required: true,
                                keyboard: TextInputType.phone,
                                autofill: const [AutofillHints.telephoneNumber],
                                formatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+\s-]')), LengthLimitingTextInputFormatter(15)],
                                validator: _validatePhone,
                              ),
                            ]),
                          ),
                          const SizedBox(height: Space.md),
                          EntranceFade.indexed(
                            2,
                            child: _section('More details', Icons.contact_mail_outlined, [
                              _field(
                                label: 'Email address',
                                controller: _email,
                                focus: _emailFocus,
                                next: _addressFocus,
                                icon: Icons.alternate_email_rounded,
                                hint: 'name@gmail.com',
                                helper: _isEdit ? 'Email can\'t be changed after the customer is created' : 'Order updates can be emailed to the customer',
                                readOnly: _isEdit,
                                keyboard: TextInputType.emailAddress,
                                autofill: const [AutofillHints.email],
                                validator: _validateEmail,
                                suffix: _isEdit ? const Icon(Icons.lock_outline_rounded, size: 18) : null,
                              ),
                              _field(
                                label: 'Address',
                                controller: _address,
                                focus: _addressFocus,
                                icon: Icons.location_on_outlined,
                                hint: 'House no, street, city',
                                keyboard: TextInputType.streetAddress,
                                autofill: const [AutofillHints.fullStreetAddress],
                                caps: TextCapitalization.words,
                                action: TextInputAction.done,
                                maxLines: 3,
                              ),
                            ]),
                          ),
                          const SizedBox(height: Space.sm),
                          Row(children: [
                            Icon(Icons.lock_outline_rounded, size: 14, color: cs.onSurfaceVariant),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text('Customer details are private to your business. Ask the customer\'s permission before saving them.',
                                  style: context.text.bodySmall),
                            ),
                          ]),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        // Save bar always visible, sits above the keyboard.
        bottomNavigationBar: AnimatedPadding(
          duration: const Duration(milliseconds: 120),
          padding: EdgeInsets.only(bottom: bottomInset),
          child: Container(
            decoration: BoxDecoration(
              color: cs.surface,
              border: Border(top: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5))),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(context.pagePadding, Space.sm, context.pagePadding, Space.sm),
                child: MaxWidthBox(
                  maxWidth: MaxWidth.form,
                  heightFactor: 1,
                  alignment: Alignment.bottomCenter,
                  child: Row(
                    children: [
                      Expanded(
                        child: TsButton.secondary(label: 'Cancel', onPressed: _loading ? null : _close),
                      ),
                      const SizedBox(width: Space.sm),
                      Expanded(
                        flex: 2,
                        child: TsButton(
                          label: _isEdit ? 'Save Changes' : 'Save Customer',
                          icon: Icons.check_rounded,
                          loading: _loading,
                          onPressed: _loading ? null : _save,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
