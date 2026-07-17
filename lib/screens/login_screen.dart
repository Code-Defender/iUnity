import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    try {
      final userCredential = await _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (mounted && userCredential != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Signal established as ${userCredential.user?.email}"),
            backgroundColor: AppColors.primaryContainer,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      bool isNotRegistered = false;
      String friendlyErrorMessage = e.toString().replaceFirst("Exception: ", "");

      if (e is FirebaseAuthException) {
        if (e.code == 'user-not-found') {
          isNotRegistered = true;
        } else if (e.code == 'invalid-credential') {
          try {
            final tempCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
              email: email,
              password: 'TempPassword123!',
            );
            await tempCredential.user?.delete();
            isNotRegistered = true;
          } on FirebaseAuthException catch (signUpError) {
            if (signUpError.code == 'email-already-in-use') {
              isNotRegistered = false;
            } else {
              print("Sign up check error: ${signUpError.code}");
            }
          } catch (signUpError) {
            print("Sign up check error: $signUpError");
          }
        }
      } else {
        final errString = e.toString();
        if (errString.contains('user-not-found')) {
          isNotRegistered = true;
        } else if (errString.contains('invalid-credential')) {
          try {
            final tempCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
              email: email,
              password: 'TempPassword123!',
            );
            await tempCredential.user?.delete();
            isNotRegistered = true;
          } on FirebaseAuthException catch (signUpError) {
            if (signUpError.code == 'email-already-in-use') {
              isNotRegistered = false;
            }
          } catch (_) {}
        }
      }

      if (isNotRegistered) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Account not created. Directing to registration..."),
              backgroundColor: Colors.redAccent,
            ),
          );
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => RegisterScreen(initialEmail: email),
            ),
          );
        }
      } else {
        setState(() {
          _errorMessage = friendlyErrorMessage;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 16.0,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Headers
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Status Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: AppColors.primary.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            "SYSTEM SCAN // INBOUND FREQUENCY",
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: AppColors.primary,
                              fontSize: 10,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "LOGIN:\nRE-ESTABLISH SIGNAL.",
                          style: theme.textTheme.headlineLarge?.copyWith(
                            fontSize: 42,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1.5,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "Enter your credentials below to authenticate and reconnect to the secure community network.",
                          style: theme.textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 24),
                        const RoadLineSeparator(color: AppColors.border),
                      ],
                    ),

                    // Inputs wrapped in a Glassmorphic Card
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24.0),
                      child: GlassCard(
                        padding: const EdgeInsets.all(28.0),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Email Input Header
                              Text(
                                "DRIVER EMAIL ADDRESS",
                                style: theme.textTheme.labelLarge?.copyWith(fontSize: 10),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                decoration: const InputDecoration(
                                  hintText: "driver@iunity.org",
                                  prefixIcon: Icon(Icons.email_outlined, color: AppColors.onSurfaceMuted, size: 20),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return "Email address is required";
                                  }
                                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.trim())) {
                                    return "Please enter a valid email";
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 20),

                              // Password Input Header
                              Text(
                                "SECRET AUTH KEY",
                                style: theme.textTheme.labelLarge?.copyWith(fontSize: 10),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _passwordController,
                                obscureText: true,
                                decoration: const InputDecoration(
                                  hintText: "••••••••",
                                  prefixIcon: Icon(Icons.lock_outline_rounded, color: AppColors.onSurfaceMuted, size: 20),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return "Password/Key is required";
                                  }
                                  if (value.length < 6) {
                                    return "Key must be at least 6 characters";
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),

                              // Forgot Password Link
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () {
                                    final email = _emailController.text.trim();
                                    if (email.isEmpty) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text("Enter your email above to request a reset link.")),
                                      );
                                      return;
                                    }
                                    _authService.sendPasswordResetEmail(email: email);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text("Reset signal sent to $email")),
                                    );
                                  },
                                  child: const Text("LOST CONNECTION?"),
                                ),
                              ),

                              // Error Message Display
                              if (_errorMessage != null) ...[
                                const SizedBox(height: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.redAccent.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 20),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          _errorMessage!,
                                          style: theme.textTheme.bodyMedium?.copyWith(
                                            color: Colors.redAccent,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Bottom Sign In / Sign Up CTAs
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const RoadLineSeparator(color: AppColors.border),
                        const SizedBox(height: 24),

                        // Login Action Button
                        SizedBox(
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleLogin,
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.onPrimary),
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        "RE-ESTABLISH SIGNAL",
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          color: AppColors.onPrimary,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 1.0,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      const Icon(Icons.radio_button_checked_rounded, size: 18),
                                    ],
                                  ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Create Account Route link
                        Center(
                          child: TextButton(
                            onPressed: () {
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(
                                  builder: (context) => const RegisterScreen(),
                                ),
                              );
                            },
                            child: RichText(
                              text: TextSpan(
                                text: "NEW TO THE NETWORK? ",
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: AppColors.onSurfaceMuted,
                                  fontSize: 12,
                                ),
                                children: [
                                  TextSpan(
                                    text: "BEGIN THE DECLARATION OF UNITY",
                                    style: theme.textTheme.labelLarge?.copyWith(
                                      color: AppColors.primary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
