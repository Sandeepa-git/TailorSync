import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../routes/app_router.dart';
import '../../../../core/network/providers/user_provider.dart';
import 'package:dio/dio.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/network/providers/api_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/tailorsync_text_field.dart';
import '../../../../core/widgets/tailorsync_password_field.dart';
import '../../../../core/widgets/tailorsync_button.dart';
import '../../../../core/widgets/tailorsync_password_requirements.dart';
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
  bool _acceptedTerms = false;

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
    if (_isSignUp && (!_isPasswordValid || !_passwordsMatch || !_acceptedTerms)) return;

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

  @override
  Widget build(BuildContext context) {
    final bool canSubmit = !_loading && (!_isSignUp || (_isPasswordValid && _passwordsMatch && _acceptedTerms));
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallPhone = screenWidth < 360;
    
    // Responsive padding
    final horizontalPadding = isSmallPhone ? 16.0 : (screenWidth < 600 ? 20.0 : 24.0);
    final cardPadding = isSmallPhone ? 20.0 : 24.0;
    
    // Responsive spacing
    final headerSpacing = isSmallPhone ? 24.0 : 32.0;
    final fieldSpacing = isSmallPhone ? 12.0 : 16.0;

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 24.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // App Logo & Header
                  Hero(
                    tag: 'app_logo',
                    child: Image.asset(
                      'assets/icon.png', 
                      height: isSmallPhone ? 64 : 80,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'TailorSync',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w800, 
                      fontSize: isSmallPhone ? 26 : 28, 
                      color: AppTheme.primary, 
                      letterSpacing: -0.5
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Elevate Your Craft',
                    style: GoogleFonts.inter(
                      fontSize: 14, 
                      color: AppTheme.textCaption, 
                      fontWeight: FontWeight.w500
                    ),
                  ),
                  SizedBox(height: headerSpacing),

                  // Registration / Login Card
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primary.withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(color: AppTheme.divider, width: 1.0),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(cardPadding),
                      child: Form(
                        key: _formKey,
                        child: AutofillGroup(
                          child: AnimatedSize(
                            duration: const Duration(milliseconds: 300),
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
                                        _isSignUp ? 'Create Account' : 'Welcome Back',
                                        style: GoogleFonts.inter(
                                          fontSize: isSmallPhone ? 22 : 24, 
                                          fontWeight: FontWeight.bold, 
                                          color: AppTheme.textPrimary, 
                                          letterSpacing: -0.5
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        _isSignUp ? 'Fill in your details to get started.' : 'We\'re excited to see you again. Ready to work?',
                                        style: GoogleFonts.inter(
                                          fontSize: 14, 
                                          color: AppTheme.textBody, 
                                          height: 1.4
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: headerSpacing),

                                if (_isSignUp) ...[
                                  TailorSyncTextField(
                                    label: 'Full Name',
                                    controller: _name,
                                    icon: Icons.person_outline,
                                    validator: (v) => v == null || v.trim().isEmpty ? 'Full name is required' : null,
                                  ),
                                  SizedBox(height: fieldSpacing),
                                  TailorSyncTextField(
                                    label: 'Mobile Number',
                                    controller: _phone,
                                    icon: Icons.phone_outlined,
                                    keyboardType: TextInputType.phone,
                                    validator: (v) => v == null || v.trim().isEmpty ? 'Mobile number is required' : null,
                                  ),
                                  SizedBox(height: fieldSpacing),
                                  TailorSyncTextField(
                                    label: 'Business / Organization',
                                    controller: _businessName,
                                    icon: Icons.business_outlined,
                                    validator: (v) => v == null || v.trim().isEmpty ? 'Business name is required' : null,
                                  ),
                                  SizedBox(height: fieldSpacing),
                                  TailorSyncTextField(
                                    label: 'Business Registration No.',
                                    controller: _businessRegNumber,
                                    icon: Icons.receipt_long_outlined,
                                    validator: (v) => v == null || v.trim().isEmpty ? 'Registration number is required' : null,
                                  ),
                                  SizedBox(height: fieldSpacing),
                                  TailorSyncTextField(
                                    label: 'Business Contact Number',
                                    controller: _businessContact,
                                    icon: Icons.contact_phone_outlined,
                                    keyboardType: TextInputType.phone,
                                    validator: (v) => v == null || v.trim().isEmpty ? 'Business contact is required' : null,
                                  ),
                                  SizedBox(height: fieldSpacing),
                                ],

                                TailorSyncTextField(
                                  label: 'Email Address',
                                  controller: _email,
                                  icon: Icons.email_outlined,
                                  keyboardType: TextInputType.emailAddress,
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) return 'Email address is required';
                                    if (!RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(v.trim())) {
                                      return 'Enter a valid email address';
                                    }
                                    return null;
                                  },
                                ),
                                SizedBox(height: fieldSpacing),

                                TailorSyncPasswordField(
                                  label: 'Password',
                                  controller: _password,
                                  validator: (v) {
                                    if (v == null || v.isEmpty) return 'Password is required';
                                    if (_isSignUp && !_isPasswordValid) return 'Password does not meet requirements';
                                    return null;
                                  },
                                ),

                                if (_isSignUp) ...[
                                  AnimatedSize(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeOutCubic,
                                    child: _password.text.isEmpty
                                        ? const SizedBox.shrink()
                                        : Padding(
                                            padding: const EdgeInsets.only(top: 12, bottom: 16),
                                            child: TailorSyncPasswordRequirements(password: _password.text),
                                          ),
                                  ),
                                  if (_password.text.isEmpty) SizedBox(height: fieldSpacing),

                                  TailorSyncPasswordField(
                                    label: 'Confirm Password',
                                    controller: _confirmPassword,
                                    validator: (v) {
                                      if (v == null || v.isEmpty) return 'Please confirm your password';
                                      if (v != _password.text) return 'Passwords do not match';
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: Checkbox(
                                          value: _acceptedTerms,
                                          onChanged: (val) {
                                            setState(() {
                                              _acceptedTerms = val ?? false;
                                            });
                                          },
                                          activeColor: AppTheme.primary,
                                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => const TermsAndConditionsScreen(),
                                              ),
                                            );
                                          },
                                          child: RichText(
                                            text: TextSpan(
                                              style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textBody),
                                              children: [
                                                const TextSpan(text: 'I agree to the '),
                                                TextSpan(
                                                  text: 'Terms and Conditions',
                                                  style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppTheme.primary, decoration: TextDecoration.underline),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
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
                                        style: GoogleFonts.inter(
                                          fontSize: 13, 
                                          color: AppTheme.primary, 
                                          fontWeight: FontWeight.w600
                                        ),
                                      ),
                                    ),
                                  ),
                                ],

                                SizedBox(height: isSmallPhone ? 24 : 32),

                                // Primary Action Button
                                TailorSyncButton(
                                  text: _isSignUp ? 'Create Account' : 'Sign In',
                                  onPressed: canSubmit ? _submit : null,
                                  isLoading: _loading,
                                ),
                                const SizedBox(height: 20),

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
