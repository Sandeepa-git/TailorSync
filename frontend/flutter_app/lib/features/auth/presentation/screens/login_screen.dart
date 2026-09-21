import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../routes/app_router.dart';
import '../../../../core/network/providers/user_provider.dart';
import 'package:dio/dio.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/network/providers/api_provider.dart';

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
    bool isResetting = false;

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
                        'Reset Password',
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
                    'Enter your registered email address and we will send you password reset instructions.',
                    style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: resetEmailController,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    decoration: InputDecoration(
                      labelText: 'Email Address',
                      prefixIcon: const Icon(Icons.email_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: isResetting
                          ? null
                          : () async {
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
                                if (ctx.mounted) {
                                  Navigator.pop(ctx);
                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                    SnackBar(
                                      content: Text('If an account exists for $emailText, reset instructions have been sent.'),
                                      backgroundColor: const Color(0xFF2E7D32),
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                  );
                                }
                              } catch (_) {
                                if (ctx.mounted) {
                                  Navigator.pop(ctx);
                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                    const SnackBar(content: Text('Failed to process request. Please try again later.')),
                                  );
                                }
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A237E),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: isResetting
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text('Send Reset Instructions', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
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
          gradient: LinearGradient(
            colors: [Color(0xFFF8F9FA), Color(0xFFE8EAF6)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/icon.png',
                    height: 90,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'TailorSync',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 24, color: const Color(0xFF1A237E)),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Elevate Your Craft',
                    style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF5C6BC0), fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 28),
                  Card(
                    elevation: 6,
                    shadowColor: const Color(0xFF1A237E).withOpacity(0.12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                      child: Form(
                        key: _formKey,
                        child: AutofillGroup(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _isSignUp ? 'Create Account' : 'Welcome Back',
                                style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF1A237E)),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _isSignUp ? 'Fill in your details to get started' : 'Sign in to access your dashboard',
                                style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600]),
                              ),
                              const SizedBox(height: 20),

                              if (_isSignUp) ...[
                                TextFormField(
                                  controller: _name,
                                  autofillHints: const [AutofillHints.name],
                                  decoration: const InputDecoration(
                                    labelText: 'Full Name', 
                                    prefixIcon: Icon(Icons.person_outline),
                                    contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                                  ),
                                  validator: (v) => v == null || v.trim().isEmpty ? 'Full name is required' : null,
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _phone,
                                  keyboardType: TextInputType.phone,
                                  autofillHints: const [AutofillHints.telephoneNumber],
                                  decoration: const InputDecoration(
                                    labelText: 'Mobile Number', 
                                    prefixIcon: Icon(Icons.phone_outlined),
                                    contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                                  ),
                                  validator: (v) => v == null || v.trim().isEmpty ? 'Mobile number is required' : null,
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _businessName,
                                  decoration: const InputDecoration(
                                    labelText: 'Business / Organization Name',
                                    prefixIcon: Icon(Icons.business),
                                    contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                                  ),
                                  validator: (v) => v == null || v.trim().isEmpty ? 'Business name is required' : null,
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _businessRegNumber,
                                  decoration: const InputDecoration(
                                    labelText: 'Business Registered Number',
                                    prefixIcon: Icon(Icons.receipt_long),
                                    contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                                  ),
                                  validator: (v) => v == null || v.trim().isEmpty ? 'Registration number is required' : null,
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _businessContact,
                                  keyboardType: TextInputType.phone,
                                  decoration: const InputDecoration(
                                    labelText: 'Business Contact Number',
                                    prefixIcon: Icon(Icons.phone),
                                    contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                                  ),
                                  validator: (v) => v == null || v.trim().isEmpty ? 'Business contact is required' : null,
                                ),
                                const SizedBox(height: 16),
                              ],

                              TextFormField(
                                controller: _email,
                                keyboardType: TextInputType.emailAddress,
                                autofillHints: const [AutofillHints.email],
                                decoration: const InputDecoration(
                                  labelText: 'Email Address', 
                                  prefixIcon: Icon(Icons.email_outlined),
                                  contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                                ),
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
                                controller: _password,
                                obscureText: _obscurePassword,
                                autofillHints: _isSignUp ? const [AutofillHints.newPassword] : const [AutofillHints.password],
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  prefixIcon: const Icon(Icons.lock_outline),
                                  contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                                  suffixIcon: IconButton(
                                    icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                  ),
                                ),
                                validator: (v) {
                                  if (v == null || v.isEmpty) return 'Password is required';
                                  if (_isSignUp && !_isPasswordValid) return 'Password does not meet requirements';
                                  return null;
                                },
                              ),

                              if (_isSignUp) ...[
                                const SizedBox(height: 12),
                                // Real-time Password Checklist Container
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF4F6FB),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: const Color(0xFFE2E6F0)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Password Requirements:', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF1A237E))),
                                      const SizedBox(height: 6),
                                      _buildChecklistItem('Minimum 8 characters', _hasMinLength),
                                      _buildChecklistItem('At least one uppercase letter (A-Z)', _hasUppercase),
                                      _buildChecklistItem('At least one lowercase letter (a-z)', _hasLowercase),
                                      _buildChecklistItem('At least one number (0-9)', _hasDigit),
                                      _buildChecklistItem('At least one special character (!@#\$%...)', _hasSpecialChar),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),

                                TextFormField(
                                  controller: _confirmPassword,
                                  obscureText: _obscureConfirmPassword,
                                  autofillHints: const [AutofillHints.newPassword],
                                  decoration: InputDecoration(
                                    labelText: 'Confirm Password',
                                    prefixIcon: const Icon(Icons.lock_reset_outlined),
                                    contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                                    suffixIcon: IconButton(
                                      icon: Icon(_obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                                      onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                                    ),
                                  ),
                                  validator: (v) {
                                    if (v == null || v.isEmpty) return 'Please confirm your password';
                                    if (v != _password.text) return 'Passwords do not match';
                                    return null;
                                  },
                                ),

                                if (_confirmPassword.text.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(
                                        _passwordsMatch ? Icons.check_circle : Icons.error,
                                        size: 16,
                                        color: _passwordsMatch ? const Color(0xFF2E7D32) : const Color(0xFFD32F2F),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        _passwordsMatch ? 'Passwords match' : 'Passwords do not match',
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: _passwordsMatch ? const Color(0xFF2E7D32) : const Color(0xFFD32F2F),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],

                              if (!_isSignUp) ...[
                                const SizedBox(height: 4),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: _showForgotPasswordDialog,
                                    style: TextButton.styleFrom(padding: EdgeInsets.zero),
                                    child: Text(
                                      'Forgot Password?',
                                      style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF1A237E), fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ),
                              ],

                              const SizedBox(height: 24),

                              SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: ElevatedButton(
                                  onPressed: canSubmit ? _submit : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF1A237E),
                                    disabledBackgroundColor: Colors.grey[300],
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    elevation: canSubmit ? 2 : 0,
                                  ),
                                  child: _loading
                                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                      : Text(
                                          _isSignUp ? 'Create Account' : 'Sign In',
                                          style: GoogleFonts.inter(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                        ),
                                ),
                              ),
                              const SizedBox(height: 16),

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
                                  child: Text(
                                    _isSignUp ? 'Already have an account? Sign In' : 'Need an account? Create Account',
                                    style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF1A237E), fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ),
                            ],
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
