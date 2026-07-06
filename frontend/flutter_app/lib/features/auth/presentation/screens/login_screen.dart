import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../../../../core/network/providers/api_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _loading = false;
  bool _isSignUp = false;
  bool _obscurePassword = true;

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final api = ref.read(apiClientProvider);
    try {
      Response response;
      if (_isSignUp) {
        response = await api.signup(_email.text.trim(), _password.text.trim(), _name.text.trim(), _phone.text.trim());
      } else {
        response = await api.login(_email.text.trim(), _password.text.trim());
      }
      
      final token = response.data['access_token'];
      api.setToken(token);
      await ref.read(secureStorageProvider).write(key: 'auth_token', value: token);

      if (!mounted) return;
      context.go('/home');
    } catch (e) {
      if (!mounted) return;
      String error = 'Authentication failed';
      try {
          if (e is DioException && e.response != null) {
            error = e.response?.data['detail'] ?? error;
          }
      } catch (_) {}
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
            padding: const EdgeInsets.all(24.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.cut, size: 48, color: Color(0xFF1A237E)),
                  const SizedBox(height: 12),
                  Text('TailorSync', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: const Color(0xFF1A237E))),
                  const SizedBox(height: 8),
                  Text('Elevate Your Craft', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: const Color(0xFF5C6BC0))),
                  const SizedBox(height: 32),
                  Card(
                    elevation: 4,
                    shadowColor: const Color(0xFF1A237E).withOpacity(0.1),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            if (_isSignUp) ...[
                              TextFormField(
                                controller: _name,
                                decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person)),
                                validator: (v) => v == null || v.isEmpty ? 'Name is required' : null,
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _phone,
                                decoration: const InputDecoration(labelText: 'Mobile Number', prefixIcon: Icon(Icons.phone)),
                                keyboardType: TextInputType.phone,
                                validator: (v) => v == null || v.isEmpty ? 'Phone is required' : null,
                              ),
                              const SizedBox(height: 16),
                            ],
                            TextFormField(
                              controller: _email,
                              decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email)),
                              keyboardType: TextInputType.emailAddress,
                              validator: (v) {
                                if (v == null || v.isEmpty) return 'Email is required';
                                if (!RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(v)) {
                                  return 'Enter a valid email';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _password,
                              decoration: InputDecoration(
                                labelText: 'Password', 
                                prefixIcon: const Icon(Icons.lock),
                                suffixIcon: IconButton(
                                  icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                ),
                              ),
                              obscureText: _obscurePassword,
                              validator: (v) {
                                if (v == null || v.isEmpty) return 'Password is required';
                                if (_isSignUp) {
                                  if (v.length < 8) return 'Must be at least 8 characters';
                                  if (!RegExp(r'[A-Z]').hasMatch(v)) return 'Must contain at least one capital letter';
                                  if (!RegExp(r'[!@#\$&*~`%\^\(\)_\+\-=\[\]\{\};:"\\|,.<>/?]').hasMatch(v)) return 'Must contain at least one special character';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: _loading ? null : _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1A237E),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: _loading 
                                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                                : Text(_isSignUp ? 'Sign Up' : 'Sign In', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                            ),
                          ),
                          const SizedBox(height: 20),
                          TextButton(
                            onPressed: () => setState(() {
                              _isSignUp = !_isSignUp;
                              _name.clear();
                              _email.clear();
                              _phone.clear();
                              _password.clear();
                            }),
                            child: Text(_isSignUp ? 'Already have an account? Sign In' : 'Need an account? Sign Up'),
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
    );
  }
}
