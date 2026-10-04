import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/providers/user_provider.dart';
import 'package:dio/dio.dart';
import '../../../../core/network/providers/api_provider.dart';
import '../../../../core/widgets/tailorsync_text_field.dart';
import '../../../../core/widgets/tailorsync_password_field.dart';
import '../../../../core/widgets/tailorsync_button.dart';
import '../../../../core/widgets/tailorsync_password_requirements.dart';
import '../../../../core/widgets/robot_check.dart';
import '../../../../ui/ui.dart';
import 'terms_and_conditions_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _businessName = TextEditingController();
  final _businessRegNumber = TextEditingController();
  final _businessContact = TextEditingController();
  final _orgName = TextEditingController();
 // For login
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  bool _isSignUp = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptedTerms = false;
  bool _captchaPassed = false;
  int _captchaKey = 0; // bump to reset the captcha
  @override
  void initState() {
    super.initState();
    _password.addListener(_updateState);
    _confirmPassword.addListener(_updateState);
  }
  @override
  void dispose() {
    _password.removeListener(_updateState);
    _confirmPassword.removeListener(_updateState);
    _businessName.dispose();
    _businessRegNumber.dispose();
    _businessContact.dispose();
    _orgName.dispose();
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }
  void _updateState() {
    if (mounted && _isSignUp) {
      setState(() {});
    }
  }
  // Real-time Validation Rules
  bool get _hasMinLength => _password.text.length >= 8;
  bool get _hasUppercase => RegExp(r'[A-Z]').hasMatch(_password.text);
  bool get _hasLowercase => RegExp(r'[a-z]').hasMatch(_password.text);
  bool get _hasDigit => RegExp(r'[0-9]').hasMatch(_password.text);
  bool get _hasSpecialChar => RegExp(r'[!@#$%^&*(),.?":{}|<>\_\+\-=\[\]\\/]').hasMatch(_password.text);
  bool get _isPasswordValid => _hasMinLength && _hasUppercase && _hasLowercase && _hasDigit && _hasSpecialChar;
  bool get _passwordsMatch => _password.text.isNotEmpty && _password.text == _confirmPassword.text;
  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isSignUp && (!_isPasswordValid || !_passwordsMatch || !_acceptedTerms)) return;
    if (!_captchaPassed) return;

    setState(() => _loading = true);
    final api = ref.read(apiClientProvider);
    try {
      Response response;
      if (_isSignUp) {
        response = await api.signup(
          businessName: _businessName.text.trim(),
          businessRegistrationNumber: _businessRegNumber.text.trim(),
          businessContactNumber: _businessContact.text.trim(),
          email: _email.text.trim(),
          password: _password.text.trim(),
          fullName: _name.text.trim(),
          phone: _phone.text.trim(),
        );
      } else {
        response = await api.login(_email.text.trim(), _password.text.trim());
      }

      final token = response.data['access_token'];
      if (token == null || token.toString().isEmpty) {
        throw Exception('No access token received from server');
      }

      api.setToken(token);
      await ref.read(secureStorageProvider).write(key: 'auth_token', value: token);

      try {
        final userResp = await api.getMe();
        final role = userResp.data?['role'];
        if (!mounted) return;
        ref.invalidate(userProvider);
        if (role == 'staff' || role == 'STAFF') {
          context.go('/tasks');
        } else {
          context.go('/home');
        }
      } catch (_) {
        if (!mounted) return;
        context.go('/home');
      }
    } on DioException catch (e) {
      if (!mounted) return;
      // Require a fresh captcha after a failed attempt.
      setState(() {
        _captchaPassed = false;
        _captchaKey++;
      });
      String error = _isSignUp ? 'Sign up failed' : 'Login failed';

      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        error = 'Connection timed out. Please check your internet connection.';
      } else if (e.type == DioExceptionType.connectionError) {
        error = 'Cannot connect to server. Please check your internet connection.';
      } else if (e.response != null) {
        final statusCode = e.response?.statusCode;
        final data = e.response?.data;

        if (data is Map && data.containsKey('detail')) {
          error = data['detail'].toString();
        } else if (statusCode == 401) {
          error = 'Incorrect email or password';
        } else if (statusCode == 429) {
          error = 'Too many login attempts. Please wait 15 minutes.';
        } else if (statusCode == 400) {
          error = 'Invalid registration details or email already exists.';
        } else if (statusCode == 500) {
          error = 'Server error. Please try again later.';
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: const Color(0xFFD32F2F),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An unexpected error occurred: ${e.toString()}'),
          backgroundColor: const Color(0xFFD32F2F),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── UI-only state ──────────────────────────────────────────────
  int _shakeCount = 0;

  void _showForgotPasswordDialog() {
    final resetEmailController = TextEditingController(text: _email.text.trim());
    final otpController = TextEditingController();
    final newPasswordController = TextEditingController();
    bool isResetting = false;
    bool isOtpStep = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 0,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: AnimatedSwitcher(
                          duration: Motion.of(context, Motion.short),
                          child: Text(
                            isOtpStep ? 'Enter OTP' : 'Reset Password',
                            key: ValueKey(isOtpStep),
                            style: context.text.titleLarge,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Close',
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isOtpStep
                        ? 'Enter the 6-digit OTP sent to your email and your new password.'
                        : 'Enter your registered email address and we will send you password reset instructions.',
                    style: context.text.bodyMedium,
                  ),
                  const SizedBox(height: 20),
                  if (!isOtpStep) ...[
                    TextField(
                      controller: resetEmailController,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      decoration: InputDecoration(
                        labelText: 'Email Address',
                        prefixIcon: const Icon(Icons.alternate_email_rounded),
                      ),
                    ),
                  ] else ...[
                    TextField(
                      controller: otpController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'OTP (6 digits)',
                        prefixIcon: const Icon(Icons.pin_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: newPasswordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'New Password',
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: isResetting
                          ? null
                          : () async {
                              if (!isOtpStep) {
                                final emailText = resetEmailController.text.trim();
                                if (emailText.isEmpty || !emailText.contains('@')) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Please enter a valid email address.')),
                                  );
                                  return;
                                }
                                setModalState(() => isResetting = true);
                                try {
                                  final api = ref.read(apiClientProvider);
                                  await api.dio.post('/auth/forgot-password', data: {'email': emailText});
                                  setModalState(() {
                                    isOtpStep = true;
                                    isResetting = false;
                                  });
                                  if (ctx.mounted) {
                                    ScaffoldMessenger.of(ctx).showSnackBar(
                                      SnackBar(
                                        content: Text('If an account exists, OTP has been sent to $emailText.'),
                                        backgroundColor: ctx.status.success,
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                    );
                                  }
                                } catch (_) {
                                  setModalState(() => isResetting = false);
                                  if (ctx.mounted) {
                                    ScaffoldMessenger.of(ctx).showSnackBar(
                                      const SnackBar(content: Text('Failed to send OTP. Please try again later.')),
                                    );
                                  }
                                }
                              } else {
                                final emailText = resetEmailController.text.trim();
                                final otpText = otpController.text.trim();
                                final newPasswordText = newPasswordController.text.trim();
                                
                                if (otpText.isEmpty || newPasswordText.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Please fill all fields.')),
                                  );
                                  return;
                                }
                                
                                setModalState(() => isResetting = true);
                                try {
                                  final api = ref.read(apiClientProvider);
                                  await api.dio.post('/auth/reset-password', data: {
                                    'email': emailText,
                                    'otp': otpText,
                                    'new_password': newPasswordText,
                                  });
                                  if (ctx.mounted) {
                                    Navigator.pop(ctx);
                                    ScaffoldMessenger.of(ctx).showSnackBar(
                                      SnackBar(
                                        content: const Text('Password updated successfully. You can now login.'),
                                        backgroundColor: ctx.status.success,
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                    );
                                  }
                                } on DioException catch (e) {
                                  setModalState(() => isResetting = false);
                                  String error = 'Failed to reset password.';
                                  if (e.response != null && e.response?.data is Map && e.response?.data['detail'] != null) {
                                    error = e.response?.data['detail'].toString() ?? error;
                                  }
                                  if (ctx.mounted) {
                                    ScaffoldMessenger.of(ctx).showSnackBar(
                                      SnackBar(content: Text(error)),
                                    );
                                  }
                                } catch (_) {
                                  setModalState(() => isResetting = false);
                                  if (ctx.mounted) {
                                    ScaffoldMessenger.of(ctx).showSnackBar(
                                      const SnackBar(content: Text('Failed to reset password. Please try again.')),
                                    );
                                  }
                                }
                              }
                            },
                      child: isResetting
                          ? SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: context.colors.onPrimary, strokeWidth: 2.5))
                          : Text(isOtpStep ? 'Verify OTP & Reset Password' : 'Send Reset Instructions', maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                  ),
                ],
              ),
              ),
            );
          },
        );
      },
    );
  }

  void _toggleMode() => setState(() {
        _isSignUp = !_isSignUp;
        _captchaPassed = false;
        _captchaKey++;
        _name.clear();
        _email.clear();
        _phone.clear();
        _password.clear();
        _confirmPassword.clear();
      });

  void _attemptSubmit() {
    // Visual feedback only: shake the card when validation fails, then run
    // the original submit logic unchanged.
    if (!(_formKey.currentState?.validate() ?? true)) {
      setState(() => _shakeCount++);
    }
    _submit();
  }

  @override
  Widget build(BuildContext context) {
    final bool canSubmit = !_loading && _captchaPassed && (!_isSignUp || (_isPasswordValid && _passwordsMatch && _acceptedTerms));
    final pad = context.pagePadding;
    final logo = (context.screenWidth * 0.2).clamp(64.0, 92.0);
    final gap = context.isCompact ? Space.sm : Space.md;

    int i = 0; // stagger index
    Widget stagger(Widget child) => EntranceFade(
          key: ValueKey('${_isSignUp}_$i'),
          delay: Motion.stagger(i++),
          child: child,
        );

    return Scaffold(
      body: AmbientBackground(
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => FocusScope.of(context).unfocus(),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.symmetric(horizontal: pad, vertical: Space.lg),
                child: MaxWidthBox(
                  maxWidth: 480,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── Brand header ──
                      Center(
                        child: Container(
                          width: logo,
                          height: logo,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(logo * 0.24),
                            boxShadow: Shadows.raised(context.colors),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Hero(
                            tag: 'app-logo',
                            child: Image.asset('assets/icon.png', fit: BoxFit.cover, semanticLabel: 'TailorSync logo'),
                          ),
                        ),
                      ),
                      const SizedBox(height: Space.md),
                      EntranceFade(
                        child: Text(
                          'TailorSync',
                          textAlign: TextAlign.center,
                          style: context.text.headlineMedium?.copyWith(color: context.colors.primary),
                        ),
                      ),
                      const SizedBox(height: Space.xxs),
                      EntranceFade(
                        delay: Motion.staggerStep,
                        child: Text('Elevate Your Craft', textAlign: TextAlign.center, style: context.text.bodyMedium),
                      ),
                      SizedBox(height: context.isShort ? Space.md : Space.lg),

                      // ── Auth card ──
                      ShakeOnChange(
                        trigger: _shakeCount == 0 ? null : _shakeCount,
                        child: TsCard(
                          padding: EdgeInsets.all(context.isSmallPhone ? Space.md + 4 : Space.lg),
                          child: Form(
                            key: _formKey,
                            child: AutofillGroup(
                              child: AnimatedSize(
                                duration: Motion.of(context, Motion.medium),
                                curve: Motion.emphasized,
                                alignment: Alignment.topCenter,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    _ModeSwitch(
                                      isSignUp: _isSignUp,
                                      onChanged: (signUp) {
                                        if (signUp != _isSignUp && !_loading) _toggleMode();
                                      },
                                    ),
                                    const SizedBox(height: Space.lg),
                                    AnimatedSwitcher(
                                      duration: Motion.of(context, Motion.medium),
                                      transitionBuilder: (child, a) => FadeTransition(
                                        opacity: a,
                                        child: SlideTransition(
                                          position: Tween(begin: const Offset(0, 0.15), end: Offset.zero).animate(a),
                                          child: child,
                                        ),
                                      ),
                                      child: Column(
                                        key: ValueKey<bool>(_isSignUp),
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(_isSignUp ? 'Create Account' : 'Welcome Back', style: context.text.headlineSmall),
                                          const SizedBox(height: Space.xxs),
                                          Text(
                                            _isSignUp
                                                ? 'Fill in your details to get started.'
                                                : 'We\'re excited to see you again. Ready to work?',
                                            style: context.text.bodyMedium,
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(height: context.isShort ? Space.md : Space.lg),

                                    if (_isSignUp) ...[
                                      stagger(TailorSyncTextField(
                                        label: 'Full Name',
                                        controller: _name,
                                        icon: Icons.person_outline_rounded,
                                        autofillHints: const [AutofillHints.name],
                                        textCapitalization: TextCapitalization.words,
                                        validator: (v) => v == null || v.trim().isEmpty ? 'Full name is required' : null,
                                      )),
                                      SizedBox(height: gap),
                                      stagger(TailorSyncTextField(
                                        label: 'Mobile Number',
                                        controller: _phone,
                                        icon: Icons.phone_outlined,
                                        keyboardType: TextInputType.phone,
                                        autofillHints: const [AutofillHints.telephoneNumber],
                                        validator: (v) => v == null || v.trim().isEmpty ? 'Mobile number is required' : null,
                                      )),
                                      SizedBox(height: gap),
                                      stagger(TailorSyncTextField(
                                        label: 'Business / Organization',
                                        controller: _businessName,
                                        icon: Icons.storefront_outlined,
                                        autofillHints: const [AutofillHints.organizationName],
                                        textCapitalization: TextCapitalization.words,
                                        validator: (v) => v == null || v.trim().isEmpty ? 'Business name is required' : null,
                                      )),
                                      SizedBox(height: gap),
                                      stagger(TailorSyncTextField(
                                        label: 'Business Registration No.',
                                        controller: _businessRegNumber,
                                        icon: Icons.receipt_long_outlined,
                                        validator: (v) => v == null || v.trim().isEmpty ? 'Registration number is required' : null,
                                      )),
                                      SizedBox(height: gap),
                                      stagger(TailorSyncTextField(
                                        label: 'Business Contact Number',
                                        controller: _businessContact,
                                        icon: Icons.contact_phone_outlined,
                                        keyboardType: TextInputType.phone,
                                        validator: (v) => v == null || v.trim().isEmpty ? 'Business contact is required' : null,
                                      )),
                                      SizedBox(height: gap),
                                    ],

                                    stagger(TailorSyncTextField(
                                      label: 'Email Address',
                                      controller: _email,
                                      icon: Icons.alternate_email_rounded,
                                      keyboardType: TextInputType.emailAddress,
                                      autofillHints: const [AutofillHints.email],
                                      validator: (v) {
                                        if (v == null || v.trim().isEmpty) return 'Email address is required';
                                        if (!RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(v.trim())) {
                                          return 'Enter a valid email address';
                                        }
                                        return null;
                                      },
                                    )),
                                    SizedBox(height: gap),

                                    stagger(TailorSyncPasswordField(
                                      label: 'Password',
                                      controller: _password,
                                      autofillHints: [_isSignUp ? AutofillHints.newPassword : AutofillHints.password],
                                      textInputAction: _isSignUp ? TextInputAction.next : TextInputAction.done,
                                      onFieldSubmitted: _isSignUp
                                          ? null
                                          : (_) {
                                              if (canSubmit) _attemptSubmit();
                                            },
                                      validator: (v) {
                                        if (v == null || v.isEmpty) return 'Password is required';
                                        if (_isSignUp && !_isPasswordValid) return 'Password does not meet requirements';
                                        return null;
                                      },
                                    )),

                                    if (_isSignUp) ...[
                                      AnimatedSize(
                                        duration: Motion.of(context, Motion.medium),
                                        curve: Motion.emphasized,
                                        child: _password.text.isEmpty
                                            ? const SizedBox(width: double.infinity)
                                            : Padding(
                                                padding: const EdgeInsets.only(top: Space.sm, bottom: Space.md),
                                                child: TailorSyncPasswordRequirements(password: _password.text),
                                              ),
                                      ),
                                      if (_password.text.isEmpty) SizedBox(height: gap),

                                      stagger(TailorSyncPasswordField(
                                        label: 'Confirm Password',
                                        controller: _confirmPassword,
                                        autofillHints: const [AutofillHints.newPassword],
                                        textInputAction: TextInputAction.done,
                                        validator: (v) {
                                          if (v == null || v.isEmpty) return 'Please confirm your password';
                                          if (v != _password.text) return 'Passwords do not match';
                                          return null;
                                        },
                                      )),
                                      const SizedBox(height: Space.sm),
                                      _TermsRow(
                                        accepted: _acceptedTerms,
                                        onChanged: (val) {
                                          setState(() {
                                            _acceptedTerms = val ?? false;
                                          });
                                        },
                                        onOpenTerms: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => const TermsAndConditionsScreen(),
                                            ),
                                          );
                                        },
                                      ),
                                    ],

                                    const SizedBox(height: Space.sm),
                                    RobotCheck(
                                      key: ValueKey('captcha_$_captchaKey'),
                                      enabled: !_loading,
                                      onChanged: (ok) => setState(() => _captchaPassed = ok),
                                    ),

                                    if (!_isSignUp)
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: TextButton(
                                          onPressed: _showForgotPasswordDialog,
                                          child: const Text('Forgot Password?'),
                                        ),
                                      ),

                                    SizedBox(height: _isSignUp ? Space.lg : Space.sm),

                                    TailorSyncButton(
                                      text: _isSignUp ? 'Create Account' : 'Sign In',
                                      icon: _isSignUp ? Icons.person_add_alt_1_rounded : Icons.login_rounded,
                                      onPressed: canSubmit ? _attemptSubmit : null,
                                      isLoading: _loading,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: Space.md),

                      // ── Secondary action ──
                      Center(
                        child: TextButton(
                          onPressed: _loading ? null : _toggleMode,
                          child: Text.rich(
                            TextSpan(
                              style: context.text.bodyMedium,
                              children: [
                                TextSpan(text: _isSignUp ? 'Already have an account? ' : 'Need an account? '),
                                TextSpan(
                                  text: _isSignUp ? 'Sign In' : 'Create Account',
                                  style: TextStyle(fontWeight: FontWeight.w800, color: context.colors.primary),
                                ),
                              ],
                            ),
                            textAlign: TextAlign.center,
                          ),
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

/// Animated segmented switch between Sign in / Create account.
class _ModeSwitch extends StatelessWidget {
  final bool isSignUp;
  final ValueChanged<bool> onChanged;
  const _ModeSwitch({required this.isSignUp, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: cs.surfaceContainerHigh, borderRadius: Radii.brPill),
      child: Stack(
        children: [
          AnimatedAlign(
            alignment: isSignUp ? Alignment.centerRight : Alignment.centerLeft,
            duration: Motion.of(context, Motion.medium),
            curve: Motion.emphasized,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              heightFactor: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: cs.surfaceContainerLowest,
                  borderRadius: Radii.brPill,
                  boxShadow: Shadows.soft(cs),
                ),
              ),
            ),
          ),
          Row(
            children: [
              for (final signUp in [false, true])
                Expanded(
                  child: Semantics(
                    button: true,
                    selected: isSignUp == signUp,
                    child: InkWell(
                      borderRadius: Radii.brPill,
                      onTap: () => onChanged(signUp),
                      child: Center(
                        child: AnimatedDefaultTextStyle(
                          duration: Motion.of(context, Motion.short),
                          style: (context.text.labelLarge ?? const TextStyle()).copyWith(
                            color: isSignUp == signUp ? cs.primary : cs.onSurfaceVariant,
                          ),
                          child: Text(signUp ? 'Create account' : 'Sign in', maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                      ),
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

class _TermsRow extends StatelessWidget {
  final bool accepted;
  final ValueChanged<bool?> onChanged;
  final VoidCallback onOpenTerms;
  const _TermsRow({required this.accepted, required this.onChanged, required this.onOpenTerms});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Checkbox(
          value: accepted,
          onChanged: onChanged,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        Expanded(
          child: InkWell(
            borderRadius: Radii.brSm,
            onTap: onOpenTerms,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: Space.sm),
              child: Text.rich(
                TextSpan(
                  style: context.text.bodyMedium,
                  children: [
                    const TextSpan(text: 'I agree to the '),
                    TextSpan(
                      text: 'Terms and Conditions',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: context.colors.primary,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
