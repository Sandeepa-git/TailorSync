import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../routes/app_router.dart';
import '../../../../core/network/providers/user_provider.dart';
import 'package:dio/dio.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/network/providers/api_provider.dart';
import '../../../../core/theme/app_theme.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _businessName = TextEditingController();
  final _businessRegNumber = TextEditingController();
  final _businessContact = TextEditingController();
  final _orgName = TextEditingController(); // For login
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

  void _showForgotPasswordDialog() {
    final resetEmailController = TextEditingController(text: _email.text.trim());
    final otpController = TextEditingController();
    final newPasswordController = TextEditingController();
    bool isResetting = false;
    bool isOtpStep = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isOtpStep ? 'Enter OTP' : 'Reset Password',
                        style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF1A237E)),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isOtpStep
                        ? 'Enter the 6-digit OTP sent to your email and your new password.'
                        : 'Enter your registered email address and we will send you password reset instructions.',
                    style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 20),
                  if (!isOtpStep) ...[
                    TextField(
                      style: const TextStyle(fontSize: 14),
                      controller: resetEmailController,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      decoration: InputDecoration(
                        labelText: 'Email Address',
                        prefixIcon: const Icon(Icons.email_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ] else ...[
                    TextField(
                      style: const TextStyle(fontSize: 14),
                      controller: otpController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'OTP (6 digits)',
                        prefixIcon: const Icon(Icons.security),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      style: const TextStyle(fontSize: 14),
                      controller: newPasswordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'New Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
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
                                        backgroundColor: const Color(0xFF2E7D32),
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
                                        backgroundColor: const Color(0xFF2E7D32),
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
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A237E),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: isResetting
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text(isOtpStep ? 'Verify OTP & Reset Password' : 'Send Reset Instructions', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isSignUp && (!_isPasswordValid || !_passwordsMatch)) return;

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

  Widget _buildChecklistItem(String label, bool isSatisfied) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        children: [
          Icon(
            isSatisfied ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
            size: 16,
            color: isSatisfied ? const Color(0xFF2E7D32) : Colors.grey[400],
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12.5,
                color: isSatisfied ? const Color(0xFF2E7D32) : Colors.grey[600],
                fontWeight: isSatisfied ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool canSubmit = !_loading && (!_isSignUp || (_isPasswordValid && _passwordsMatch));

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          color: AppTheme.scaffoldBg,
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // App Logo & Header
                  Hero(
                    tag: 'app_logo',
                    child: Image.asset('assets/icon.png', height: 80),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'TailorSync',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 28, color: AppTheme.primary, letterSpacing: -0.5),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Elevate Your Craft',
                    style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textCaption, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 48), // 8pt scale

                  // Glassmorphism/Soft Card
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: AppTheme.cardShadow,
                      border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 1.5),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
                      child: Form(
                        key: _formKey,
                        child: AutofillGroup(
                          child: AnimatedSize(
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeOutCubic,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 300),
                                  transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
                                  child: Column(
                                    key: ValueKey<bool>(_isSignUp),
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _isSignUp ? 'Let\'s Get Started' : 'Welcome Back',
                                        style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textPrimary, letterSpacing: -0.5),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        _isSignUp ? 'Join TailorSync and streamline your business.' : 'We\'re excited to see you again. Ready to work?',
                                        style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textBody, height: 1.4),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 32),

                                if (_isSignUp) ...[
                                  TextFormField(
                                    style: GoogleFonts.inter(fontSize: 14),
                                    controller: _name,
                                    autofillHints: const [AutofillHints.name],
                                    decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person_outline)),
                                    validator: (v) => v == null || v.trim().isEmpty ? 'Full name is required' : null,
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    style: GoogleFonts.inter(fontSize: 14),
                                    controller: _phone,
                                    keyboardType: TextInputType.phone,
                                    autofillHints: const [AutofillHints.telephoneNumber],
                                    decoration: const InputDecoration(labelText: 'Mobile Number', prefixIcon: Icon(Icons.phone_outlined)),
                                    validator: (v) => v == null || v.trim().isEmpty ? 'Mobile number is required' : null,
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    style: GoogleFonts.inter(fontSize: 14),
                                    controller: _businessName,
                                    decoration: const InputDecoration(labelText: 'Business Name', prefixIcon: Icon(Icons.business_outlined)),
                                    validator: (v) => v == null || v.trim().isEmpty ? 'Business name is required' : null,
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    style: GoogleFonts.inter(fontSize: 14),
                                    controller: _businessRegNumber,
                                    decoration: const InputDecoration(labelText: 'Registration Number', prefixIcon: Icon(Icons.receipt_long_outlined)),
                                    validator: (v) => v == null || v.trim().isEmpty ? 'Registration number is required' : null,
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    style: GoogleFonts.inter(fontSize: 14),
                                    controller: _businessContact,
                                    keyboardType: TextInputType.phone,
                                    decoration: const InputDecoration(labelText: 'Business Contact', prefixIcon: Icon(Icons.contact_phone_outlined)),
                                    validator: (v) => v == null || v.trim().isEmpty ? 'Business contact is required' : null,
                                  ),
                                  const SizedBox(height: 16),
                                ],

                                TextFormField(
                                  style: GoogleFonts.inter(fontSize: 14),
                                  controller: _email,
                                  keyboardType: TextInputType.emailAddress,
                                  autofillHints: const [AutofillHints.email],
                                  decoration: const InputDecoration(labelText: 'Email Address', prefixIcon: Icon(Icons.email_outlined)),
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) return 'Email address is required';
                                    if (!RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(v.trim())) {
                                      return 'Enter a valid email address';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),

                                TextFormField(
                                  style: GoogleFonts.inter(fontSize: 14),
                                  controller: _password,
                                  obscureText: _obscurePassword,
                                  autofillHints: _isSignUp ? const [AutofillHints.newPassword] : const [AutofillHints.password],
                                  decoration: InputDecoration(
                                    labelText: 'Password',
                                    prefixIcon: const Icon(Icons.lock_outline),
                                    suffixIcon: IconButton(
                                      icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                      splashRadius: 24,
                                    ),
                                  ),
                                  validator: (v) {
                                    if (v == null || v.isEmpty) return 'Password is required';
                                    if (_isSignUp && !_isPasswordValid) return 'Password does not meet requirements';
                                    return null;
                                  },
                                ),

                                // Progressive Disclosure: Only show password requirements when signing up and typing
                                if (_isSignUp) ...[
                                  AnimatedSize(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeOutCubic,
                                    child: _password.text.isEmpty
                                        ? const SizedBox.shrink()
                                        : Container(
                                            margin: const EdgeInsets.only(top: 16),
                                            padding: const EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              color: AppTheme.scaffoldBg,
                                              borderRadius: BorderRadius.circular(16),
                                              border: Border.all(color: AppTheme.divider),
                                            ),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text('Password Security:', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                                                const SizedBox(height: 8),
                                                _buildChecklistItem('Minimum 8 characters', _hasMinLength),
                                                _buildChecklistItem('One uppercase letter', _hasUppercase),
                                                _buildChecklistItem('One lowercase letter', _hasLowercase),
                                                _buildChecklistItem('One number', _hasDigit),
                                                _buildChecklistItem('One special character', _hasSpecialChar),
                                              ],
                                            ),
                                          ),
                                  ),
                                  const SizedBox(height: 16),

                                  TextFormField(
                                    style: GoogleFonts.inter(fontSize: 14),
                                    controller: _confirmPassword,
                                    obscureText: _obscureConfirmPassword,
                                    autofillHints: const [AutofillHints.newPassword],
                                    decoration: InputDecoration(
                                      labelText: 'Confirm Password',
                                      prefixIcon: const Icon(Icons.lock_reset_outlined),
                                      suffixIcon: IconButton(
                                        icon: Icon(_obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                                        onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                                        splashRadius: 24,
                                      ),
                                    ),
                                    validator: (v) {
                                      if (v == null || v.isEmpty) return 'Please confirm your password';
                                      if (v != _password.text) return 'Passwords do not match';
                                      return null;
                                    },
                                  ),

                                  AnimatedSize(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeOutCubic,
                                    child: _confirmPassword.text.isEmpty
                                        ? const SizedBox.shrink()
                                        : Padding(
                                            padding: const EdgeInsets.only(top: 8),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  _passwordsMatch ? Icons.check_circle : Icons.error,
                                                  size: 16,
                                                  color: _passwordsMatch ? Colors.green.shade700 : AppTheme.error,
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  _passwordsMatch ? 'Passwords match' : 'Passwords do not match',
                                                  style: GoogleFonts.inter(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                    color: _passwordsMatch ? Colors.green.shade700 : AppTheme.error,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                  ),
                                ],

                                if (!_isSignUp) ...[
                                  const SizedBox(height: 8),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                      onPressed: _showForgotPasswordDialog,
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        minimumSize: Size.zero,
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      child: Text(
                                        'Forgot Password?',
                                        style: GoogleFonts.inter(fontSize: 13, color: AppTheme.primary, fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                  ),
                                ],

                                const SizedBox(height: 32),

                                // Primary Action Button
                                SizedBox(
                                  width: double.infinity,
                                  height: 56, // 8pt scale tap target
                                  child: ElevatedButton(
                                    onPressed: canSubmit ? _submit : null,
                                    style: ElevatedButton.styleFrom(
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                      elevation: canSubmit ? 4 : 0,
                                      shadowColor: AppTheme.primary.withValues(alpha: 0.4),
                                      disabledBackgroundColor: AppTheme.divider,
                                    ),
                                    child: AnimatedSwitcher(
                                      duration: const Duration(milliseconds: 200),
                                      child: _loading
                                          ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                                          : Text(
                                              _isSignUp ? 'Create Account' : 'Sign In',
                                              key: ValueKey(_isSignUp),
                                              style: GoogleFonts.inter(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                            ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),

                                // Secondary Action
                                Center(
                                  child: TextButton(
                                    onPressed: () => setState(() {
                                      _isSignUp = !_isSignUp;
                                      _name.clear();
                                      _email.clear();
                                      _phone.clear();
                                      _password.clear();
                                      _confirmPassword.clear();
                                    }),
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    child: RichText(
                                      text: TextSpan(
                                        style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textBody),
                                        children: [
                                          TextSpan(text: _isSignUp ? 'Already have an account? ' : 'Need an account? '),
                                          TextSpan(
                                            text: _isSignUp ? 'Sign In' : 'Create Account',
                                            style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppTheme.primary),
                                          ),
                                        ],
                                      ),
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
