import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  final String? initialEmail;
  const RegisterScreen({super.key, this.initialEmail});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  final AuthService _authService = AuthService();
  final DatabaseService _databaseService = DatabaseService();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  String _selectedRole = "DRIVER"; // "DRIVER", "OWNER", or "BOTH"
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.initialEmail != null) {
      _emailController.text = widget.initialEmail!;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userCredential = await _authService.signUpWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      
      if (userCredential != null && userCredential.user != null) {
        // Save user profile details to database
        await _databaseService.saveUserProfile(
          uid: userCredential.user!.uid,
          email: _emailController.text.trim(),
          displayName: _nameController.text.trim(),
          role: _selectedRole,
        );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text("Account registered. Welcome to the Unity!"),
              backgroundColor: AppColors.primaryContainer,
            ),
          );
          // Dismiss registration screen overlay so user lands on HomeScreen
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst("Exception: ", "");
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _navigateToLogin() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const LoginScreen(),
      ),
    );
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
                            "SYSTEM DISCOVERY // BEGIN THE DECLARATION",
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: AppColors.primary,
                              fontSize: 10,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "BEGIN THE DECLARATION\nOF UNITY.",
                          style: theme.textTheme.headlineLarge?.copyWith(
                            fontSize: 42,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1.5,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "You are not marginal. You are foundational. Start your declaration.",
                          style: theme.textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 24),
                        const RoadLineSeparator(color: AppColors.border),
                      ],
                    ),

                    // Inputs wrapped in Glassmorphic Card
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24.0),
                      child: GlassCard(
                        padding: const EdgeInsets.all(28.0),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Full Name
                              Text(
                                "FULL NAME",
                                style: theme.textTheme.labelLarge?.copyWith(fontSize: 10),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _nameController,
                                keyboardType: TextInputType.name,
                                decoration: const InputDecoration(
                                  hintText: "John Doe",
                                  prefixIcon: Icon(Icons.person_outline_rounded, color: AppColors.onSurfaceMuted, size: 20),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return "Full name is required";
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 20),

                              // Email Input
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

                              // Password Input
                              Text(
                                "SECRET AUTH KEY",
                                style: theme.textTheme.labelLarge?.copyWith(fontSize: 10),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                decoration: InputDecoration(
                                  hintText: "••••••••",
                                  prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.onSurfaceMuted, size: 20),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                      color: AppColors.onSurfaceMuted,
                                      size: 20,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                                  ),
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
                              const SizedBox(height: 24),

                              // Identity Declaration Title
                              Text(
                                "IDENTITY DECLARATION",
                                style: theme.textTheme.labelLarge?.copyWith(fontSize: 10),
                              ),
                              const SizedBox(height: 12),

                              // Identity cards selection
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildRoleCard("DRIVER", Icons.person_outline_rounded),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _buildRoleCard("OWNER", Icons.local_shipping_outlined),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _buildRoleCard("BOTH", Icons.handshake_outlined),
                                  ),
                                ],
                              ),

                              // Error Message Display
                              if (_errorMessage != null) ...[
                                const SizedBox(height: 20),
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

                    // Bottom CTA Panel
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const RoadLineSeparator(color: AppColors.border),
                        const SizedBox(height: 24),

                        // Register Action Button
                        SizedBox(
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleRegister,
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
                                        "BEGIN THE DECLARATION",
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          color: AppColors.onPrimary,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 1.0,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      const Icon(Icons.arrow_forward_rounded, size: 18),
                                    ],
                                  ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Login Route Link
                        Center(
                          child: TextButton(
                            onPressed: _navigateToLogin,
                            child: RichText(
                              text: TextSpan(
                                text: "ALREADY AN ASSOCIATE? ",
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: AppColors.onSurfaceMuted,
                                  fontSize: 12,
                                ),
                                children: [
                                  TextSpan(
                                    text: "LOG IN",
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

  Widget _buildRoleCard(String role, IconData icon) {
    final isSelected = _selectedRole == role;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedRole = role;
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.08) : AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primary : AppColors.onSurfaceMuted.withOpacity(0.6),
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              role,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppColors.primary : AppColors.onSurfaceMuted,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
