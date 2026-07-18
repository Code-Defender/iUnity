import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  final DatabaseService _databaseService = DatabaseService();

  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;

  bool _isEditing = false;
  bool _isSaving = false;
  bool _initialized = false;
  String _selectedRole = "DRIVER";
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile(String uid, String email) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      await _databaseService.saveUserProfile(
        uid: uid,
        email: email,
        displayName: _nameController.text.trim(),
        role: _selectedRole,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Profile frequency updated and secured."),
            backgroundColor: AppColors.primaryContainer,
          ),
        );
        setState(() {
          _isEditing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "Failed to update profile: $e";
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _handleLogout() async {
    try {
      await _authService.signOut();
      if (mounted) {
        Navigator.of(context).pop(); // Go back to home
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Signal terminated. Disconnected secure session."),
            backgroundColor: AppColors.primaryContainer,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error disconnecting: $e"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  String _getInitials(String displayName, String email) {
    String name = displayName.trim().isEmpty ? email : displayName.trim();
    List<String> parts = name.split(RegExp(r'\s+'));
    if (parts.isEmpty) return "U";
    if (parts.length == 1) {
      return parts[0].substring(0, parts[0].length > 1 ? 2 : 1).toUpperCase();
    }
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = _authService.currentUser;

    if (user == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: AppColors.primary,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                "NO SIGNAL DETECTED",
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 8),
              const Text("Please log in to view profile details."),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text("RETURN TO HOME"),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: AppColors.onSurface,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: _databaseService.getUserProfileStream(user.uid),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Text("Error fetching user data: ${snapshot.error}"),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting &&
                !_initialized) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            }

            final data = snapshot.data?.data() ?? {};

            // Initialize controllers once data is available
            if (!_initialized) {
              _nameController.text = data['displayName'] ?? '';
              _selectedRole = data['role'] ?? 'DRIVER';
              _initialized = true;
            }

            final displayName = data['displayName'] ?? '';
            final role = data['role'] ?? 'DRIVER';
            final email = data['email'] ?? user.email ?? '';

            // Formatting creation date if available
            String createdStr = "SECURE MEMBER";
            if (data['createdAt'] != null && data['createdAt'] is Timestamp) {
              final date = (data['createdAt'] as Timestamp).toDate();
              createdStr =
                  "COMMISSIONED // ${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}";
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 8.0,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Title
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        "CONNECTION ESTABLISHED // DRIVER PROFILE",
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: AppColors.primary,
                          fontSize: 10,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "MEMBER\nPORTAL STATUS.",
                      style: theme.textTheme.headlineLarge?.copyWith(
                        fontSize: 42,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1.5,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Review your active network signature, role specifications, and credentials below.",
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 24),
                    const RoadLineSeparator(color: AppColors.border),
                    const SizedBox(height: 32),

                    // Avatar & Stats Summary Card
                    Center(
                      child: Column(
                        children: [
                          Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              Container(
                                width: 110,
                                height: 110,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.primary,
                                    width: 2.0,
                                  ),
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      AppColors.primaryContainer.withValues(
                                        alpha: 0.4,
                                      ),
                                      AppColors.background,
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primary.withValues(
                                        alpha: 0.1,
                                      ),
                                      blurRadius: 16,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    _getInitials(displayName, email),
                                    style: GoogleFonts.inter(
                                      fontSize: 36,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.primary,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                ),
                              ),
                              // Live signal indicator overlapping avatar
                              const Padding(
                                padding: EdgeInsets.all(4.0),
                                child: UnitySignal(size: 14),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            displayName.isEmpty ? "IDENT_NOT_SET" : displayName,
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.onSurface,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            createdStr.toUpperCase(),
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 11,
                              color: AppColors.onSurfaceMuted.withValues(
                                alpha: 0.7,
                              ),
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Main Info Card
                    GlassCard(
                      padding: const EdgeInsets.all(28.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Display Name field
                          Text(
                            "DRIVER IDENTIFICATION (DISPLAY NAME)",
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontSize: 10,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (_isEditing)
                            TextFormField(
                              controller: _nameController,
                              style: const TextStyle(
                                color: AppColors.onSurface,
                              ),
                              decoration: const InputDecoration(
                                hintText: "Enter full name",
                                prefixIcon: Icon(
                                  Icons.badge_outlined,
                                  color: AppColors.onSurfaceMuted,
                                  size: 20,
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return "Display name is required";
                                }
                                return null;
                              },
                            )
                          else
                            _buildInfoFieldContainer(
                              context: context,
                              icon: Icons.badge_outlined,
                              text: displayName.isEmpty
                                  ? "Not declared"
                                  : displayName,
                              isPlaceholder: displayName.isEmpty,
                            ),
                          const SizedBox(height: 24),

                          // Email field (Always read-only)
                          Text(
                            "NETWORK FREQUENCY (EMAIL ADDRESS)",
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontSize: 10,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildInfoFieldContainer(
                            context: context,
                            icon: Icons.email_outlined,
                            text: email,
                            isReadOnly: true,
                          ),
                          const SizedBox(height: 24),

                          // Identity Role selection
                          Text(
                            "UNITY SPECIFICATION (ROLE)",
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontSize: 10,
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (_isEditing)
                            Row(
                              children: [
                                Expanded(
                                  child: _buildRoleSelectButton(
                                    "DRIVER",
                                    Icons.person_outline_rounded,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _buildRoleSelectButton(
                                    "OWNER",
                                    Icons.local_shipping_outlined,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _buildRoleSelectButton(
                                    "BOTH",
                                    Icons.handshake_outlined,
                                  ),
                                ),
                              ],
                            )
                          else
                            _buildInfoFieldContainer(
                              context: context,
                              icon: _getRoleIcon(role),
                              text: role,
                            ),

                          // Error Display
                          if (_errorMessage != null) ...[
                            const SizedBox(height: 20),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.redAccent.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.redAccent.withValues(
                                    alpha: 0.3,
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.error_outline_rounded,
                                    color: Colors.redAccent,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      _errorMessage!,
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
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
                    const SizedBox(height: 32),

                    // Actions Panel
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const RoadLineSeparator(color: AppColors.border),
                        const SizedBox(height: 24),

                        if (_isEditing)
                          Row(
                            children: [
                              Expanded(
                                child: SizedBox(
                                  height: 52,
                                  child: OutlinedButton(
                                    onPressed: _isSaving
                                        ? null
                                        : () {
                                            setState(() {
                                              _nameController.text =
                                                  displayName;
                                              _selectedRole = role;
                                              _isEditing = false;
                                              _errorMessage = null;
                                            });
                                          },
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.onSurface,
                                      side: const BorderSide(
                                        color: AppColors.border,
                                        width: 1.5,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: Text(
                                      "CANCEL",
                                      style: GoogleFonts.inter(
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.0,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: SizedBox(
                                  height: 52,
                                  child: ElevatedButton(
                                    onPressed: _isSaving
                                        ? null
                                        : () => _saveProfile(user.uid, email),
                                    child: _isSaving
                                        ? const SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                    AppColors.onPrimary,
                                                  ),
                                            ),
                                          )
                                        : Text(
                                            "SAVE CHANGES",
                                            style: GoogleFonts.inter(
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 1.0,
                                            ),
                                          ),
                                  ),
                                ),
                              ),
                            ],
                          )
                        else ...[
                          SizedBox(
                            height: 52,
                            child: ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _isEditing = true;
                                });
                              },
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "EDIT PROFILE FREQUENCY",
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: AppColors.onPrimary,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.edit_note_rounded, size: 20),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            height: 52,
                            child: OutlinedButton(
                              onPressed: _handleLogout,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.redAccent,
                                side: const BorderSide(
                                  color: Colors.redAccent,
                                  width: 1.5,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "DISCONNECT SIGNAL (LOGOUT)",
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.logout_rounded, size: 18),
                                ],
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 32),
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

  Widget _buildInfoFieldContainer({
    required BuildContext context,
    required IconData icon,
    required String text,
    bool isPlaceholder = false,
    bool isReadOnly = false,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: isReadOnly
            ? AppColors.surfaceContainerLowest
            : AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.border.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: isReadOnly
                ? AppColors.onSurfaceMuted.withValues(alpha: 0.4)
                : AppColors.onSurfaceMuted.withValues(alpha: 0.8),
            size: 20,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isReadOnly
                    ? AppColors.onSurfaceMuted.withValues(alpha: 0.5)
                    : isPlaceholder
                    ? AppColors.onSurfaceMuted.withValues(alpha: 0.4)
                    : AppColors.onSurface,
                fontWeight: isReadOnly ? FontWeight.normal : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getRoleIcon(String role) {
    switch (role.toUpperCase()) {
      case 'OWNER':
        return Icons.local_shipping_outlined;
      case 'BOTH':
        return Icons.handshake_outlined;
      case 'DRIVER':
      default:
        return Icons.person_outline_rounded;
    }
  }

  Widget _buildRoleSelectButton(String role, IconData icon) {
    final isSelected = _selectedRole == role;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedRole = role;
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.08)
              : AppColors.surfaceContainerLow,
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
              color: isSelected
                  ? AppColors.primary
                  : AppColors.onSurfaceMuted.withValues(alpha: 0.6),
              size: 22,
            ),
            const SizedBox(height: 8),
            Text(
              role,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? AppColors.primary
                    : AppColors.onSurfaceMuted,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
