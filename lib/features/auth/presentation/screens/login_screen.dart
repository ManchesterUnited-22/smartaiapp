// lib/features/auth/presentation/screens/login_screen.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../../core/services/auth_services.dart';
import '../../../../../core/widgets/aura_orb.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isRegisterMode = false;
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _submit() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final authService = context.read<AuthService>();
    try {
      if (_isRegisterMode) {
        await authService.signUpWithEmail(
          email: _emailController.text.trim(),
          username: _usernameController.text.trim(),
          password: _passwordController.text.trim(),
        );

        setState(() {
          _isRegisterMode = false;
          _emailController.clear();
          _passwordController.clear();
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đăng ký thành công! Vui lòng đăng nhập.')),
          );
        }
      } else {
        await authService.signInWithUsername(
          username: _usernameController.text.trim(),
          password: _passwordController.text.trim(),
        );
      }
    } catch (e) {
      setState(() => _errorMessage = _friendlyError(e.toString()));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _submitGoogleAuth() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await context.read<AuthService>().signInWithGoogle();
    } catch (e) {
      setState(() => _errorMessage = 'Đăng nhập Google thất bại: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _friendlyError(String raw) {
    if (raw.contains('username-already-taken')) return 'Tên đăng nhập đã tồn tại.';
    if (raw.contains('username-not-found')) return 'Tên đăng nhập không tồn tại.';
    if (raw.contains('email-already-in-use')) return 'Email này đã được đăng ký.';
    if (raw.contains('weak-password')) return 'Mật khẩu quá yếu (tối thiểu 6 ký tự).';
    if (raw.contains('wrong-password')) return 'Sai mật khẩu.';
    if (raw.contains('invalid-email')) return 'Email không hợp lệ.';
    return 'Có lỗi xảy ra, vui lòng thử lại.';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          // Nền gradient mesh mềm mại
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [const Color(0xFF0F1117), const Color(0xFF171A2B)]
                      : [const Color(0xFFF5F6FA), const Color(0xFFEDEFFB)],
                ),
              ),
            ),
          ),
          Positioned(
            top: -80, left: -60,
            child: _blob(scheme.primary.withValues(alpha: isDark ? 0.25 : 0.18), 220),
          ),
          Positioned(
            bottom: -100, right: -80,
            child: _blob(scheme.secondary.withValues(alpha: isDark ? 0.22 : 0.16), 260),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const AuraOrb(size: 64, animate: true),
                    const SizedBox(height: 20),
                    Text(
                      'AI Life Companion',
                      style: GoogleFonts.fraunces(
                        fontSize: 28, fontWeight: FontWeight.w600,
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Người bạn đồng hành quản lý công việc',
                      style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 32),

                    ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: scheme.surface.withValues(alpha: isDark ? 0.55 : 0.75),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: scheme.outline.withValues(alpha: 0.4)),
                          ),
                          child: Column(
                            children: [
                              if (_isRegisterMode) ...[
                                TextField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  decoration: const InputDecoration(
                                    labelText: 'Email',
                                    prefixIcon: Icon(Icons.mail_outline),
                                  ),
                                ),
                                const SizedBox(height: 14),
                              ],
                              TextField(
                                controller: _usernameController,
                                decoration: const InputDecoration(
                                  labelText: 'Tên đăng nhập',
                                  prefixIcon: Icon(Icons.person_outline),
                                ),
                              ),
                              const SizedBox(height: 14),
                              TextField(
                                controller: _passwordController,
                                obscureText: true,
                                decoration: const InputDecoration(
                                  labelText: 'Mật khẩu',
                                  prefixIcon: Icon(Icons.lock_outline),
                                ),
                              ),

                              if (_errorMessage != null) ...[
                                const SizedBox(height: 12),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    _errorMessage!,
                                    style: TextStyle(color: scheme.error, fontSize: 13),
                                  ),
                                ),
                              ],

                              const SizedBox(height: 20),
                              SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    gradient: LinearGradient(
                                      colors: [scheme.primary, scheme.secondary],
                                    ),
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(16),
                                      onTap: _isLoading ? null : _submit,
                                      child: Center(
                                        child: _isLoading
                                            ? const SizedBox(
                                                height: 20, width: 20,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2, color: Colors.white,
                                                ),
                                              )
                                            : Text(
                                                _isRegisterMode ? 'Đăng ký' : 'Đăng nhập',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 15,
                                                ),
                                              ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              TextButton(
                                onPressed: () => setState(() => _isRegisterMode = !_isRegisterMode),
                                child: Text(
                                  _isRegisterMode ? 'Đã có tài khoản? Đăng nhập' : 'Chưa có tài khoản? Đăng ký',
                                  style: TextStyle(color: scheme.primary, fontSize: 13),
                                ),
                              ),

                              Row(
                                children: [
                                  Expanded(child: Divider(color: scheme.outline)),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    child: Text('hoặc', style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
                                  ),
                                  Expanded(child: Divider(color: scheme.outline)),
                                ],
                              ),
                              const SizedBox(height: 16),

                              SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    side: BorderSide(color: scheme.outline),
                                  ),
                                  onPressed: _isLoading ? null : _submitGoogleAuth,
                                  icon: const Icon(Icons.g_mobiledata, size: 26),
                                  label: const Text('Đăng nhập với Google'),
                                ),
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
        ],
      ),
    );
  }

  Widget _blob(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}