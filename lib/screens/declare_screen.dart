import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';

class DeclareScreen extends StatefulWidget {
  final VoidCallback onReturnToDashboard;

  const DeclareScreen({super.key, required this.onReturnToDashboard});

  @override
  State<DeclareScreen> createState() => _DeclareScreenState();
}

class _DeclareScreenState extends State<DeclareScreen> {
  final AuthService _authService = AuthService();
  final DatabaseService _databaseService = DatabaseService();

  bool _isLoading = false;
  bool _isSubmitting = false;
  bool _showSuccess = false;

  String _selectedRole = "DRIVER"; // "DRIVER", "OWNER", or "BOTH"
  String _selectedCountry = "United States";
  String _selectedLanguage = "English";

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _corridorController = TextEditingController();
  final TextEditingController _chapterController = TextEditingController();

  final List<String> _countries = [
    "United States",
    "Canada",
    "Mexico",
    "European Union",
    "Global Corridor",
  ];

  final List<String> _languages = ["English", "Spanish", "French", "Punjabi"];

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _corridorController.dispose();
    _chapterController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    final user = _authService.currentUser;
    if (user == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final doc = await _databaseService
          .getUserProfile(user.uid)
          .timeout(const Duration(seconds: 3));
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        if (mounted) {
          setState(() {
            if (data['displayName'] != null) {
              _nameController.text = data['displayName'].toString();
            } else if (user.displayName != null) {
              _nameController.text = user.displayName!;
            }
            if (data['phone'] != null) {
              _phoneController.text = data['phone'].toString();
            }
            if (data['role'] != null) {
              final roleStr = data['role'].toString().toUpperCase();
              if (roleStr == "DRIVER" ||
                  roleStr == "OWNER" ||
                  roleStr == "BOTH") {
                _selectedRole = roleStr;
              }
            }
            if (data['country'] != null &&
                _countries.contains(data['country'])) {
              _selectedCountry = data['country'].toString();
            }
            if (data['preferredCorridor'] != null) {
              _corridorController.text = data['preferredCorridor'].toString();
            }
            if (data['preferredCorridor'] != null) {
              _corridorController.text = data['preferredCorridor'].toString();
            }
            if (data['primaryLanguage'] != null &&
                _languages.contains(data['primaryLanguage'])) {
              _selectedLanguage = data['primaryLanguage'].toString();
            }
            if (data['localChapter'] != null) {
              _chapterController.text = data['localChapter'].toString();
            }
          });
        }
      }
    } catch (e) {
      debugPrint("Error loading profile: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Unable to reach database: loaded default profile options. ($e)",
            ),
            duration: const Duration(seconds: 4),
            backgroundColor: AppColors.surfaceContainerHigh,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _submitDeclaration() async {
    final user = _authService.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Error: User session not found. Please log in again."),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Update profile with role and mission details using set(merge: true) to make it robust
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({
            'displayName': _nameController.text.trim(),
            'phone': _phoneController.text.trim(),
            'role': _selectedRole,
            'country': _selectedCountry,
            'preferredCorridor': _corridorController.text.trim(),
            'primaryLanguage': _selectedLanguage,
            'localChapter': _chapterController.text.trim(),
            'declaredAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true))
          .timeout(const Duration(seconds: 5));

      if (mounted) {
        setState(() {
          _showSuccess = true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error affirming identity: $e"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 960;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Hero Header Section
        Center(
          child: Column(
            children: [
              const SizedBox(height: 16),
              // Glowing central emblem
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      blurRadius: 16,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.language_rounded,
                  color: AppColors.primary,
                  size: 40,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                "Declaration of Unity",
                style: theme.textTheme.headlineLarge?.copyWith(
                  fontSize: isDesktop ? 56 : 36,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1.5,
                  height: 1.1,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                "\"We declare that truckers are not marginal. They are foundational.\"",
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: AppColors.onSurfaceMuted.withValues(alpha: 0.9),
                  fontSize: isDesktop ? 18 : 15,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              const SizedBox(width: 280, child: RoadLineSeparator()),
              const SizedBox(height: 48),
            ],
          ),
        ),

        // Main content (Success state or Form)
        _showSuccess
            ? _buildSuccessState(theme)
            : _isLoading
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 64.0),
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.primary,
                    ),
                  ),
                ),
              )
            : _buildFormLayout(theme, isDesktop),
      ],
    );
  }

  Widget _buildFormLayout(ThemeData theme, bool isDesktop) {
    if (isDesktop) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 5, child: _buildLeftContextColumn(theme)),
          const SizedBox(width: 48),
          Expanded(flex: 7, child: _buildRightFormColumn(theme)),
        ],
      );
    } else {
      return Column(
        children: [
          _buildLeftContextColumn(theme),
          const SizedBox(height: 32),
          _buildRightFormColumn(theme),
        ],
      );
    }
  }

  Widget _buildLeftContextColumn(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Live Community Signal Card
        GlassCard(
          padding: const EdgeInsets.all(28.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const UnitySignal(size: 10),
                  const SizedBox(width: 12),
                  Text(
                    "LIVE COMMUNITY SIGNAL",
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: AppColors.primary,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2.0,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                "The Transcontinental Owners and Drivers Association (TODA) represents the backbone of global commerce. By declaring your identity, you join a network of over 140,000 professionals standing for dignity and collective strength.",
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
              ),
              const SizedBox(height: 24),
              // Advantages Checklist
              _buildChecklistItem(theme, "Collective Bargaining Identity"),
              const SizedBox(height: 12),
              _buildChecklistItem(theme, "Infrastructure Sovereignty"),
              const SizedBox(height: 12),
              _buildChecklistItem(theme, "Cinematic Driver Visibility"),
            ],
          ),
        ),
        const SizedBox(height: 24),
        // Cinematic Truck Image
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              Image.network(
                "https://lh3.googleusercontent.com/aida-public/AB6AXuCWxcv9sLesYUaQRbileLn7DmyZjvMD6n8mHho9LemuArmYUDUFFX_fnVMVCsK8PRhcn8Bqt1YbXTAW-UGw_qX3hs71Uds9HyIiAS0ImqJIghdpnASHCfdsnLridHymR2_fs6cE0bg0XM5_M-iM4fT3rHSmvs96OEPyfTAlSYYTmKpq4S3nm67toJrygSGBB_WnIrF5WrNQrU-ptDiY05k8gbnEe5i1D-LnhMGscpR1vZf-jUsf9Zi-v6jlDSRxN0Uz9wACxBaoeao",
                fit: BoxFit.cover,
                height: 250,
                width: double.infinity,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 250,
                    width: double.infinity,
                    color: AppColors.surfaceContainerLow,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.local_shipping_rounded,
                          size: 48,
                          color: AppColors.onSurfaceMuted.withValues(
                            alpha: 0.3,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "Cinematic Transit Signal",
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: AppColors.onSurfaceMuted.withValues(
                              alpha: 0.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        AppColors.background.withValues(alpha: 0.7),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChecklistItem(ThemeData theme, String text) {
    return Row(
      children: [
        const Icon(
          Icons.check_circle_rounded,
          color: AppColors.primary,
          size: 18,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text.toUpperCase(),
            style: theme.textTheme.labelLarge?.copyWith(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurface,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRightFormColumn(ThemeData theme) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Step 1: Role Selector
          Text(
            "STEP 1: SELECT YOUR ROLE",
            style: theme.textTheme.labelLarge?.copyWith(
              color: AppColors.primary,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 2.0,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildRoleSelectorButton(
                  role: "OWNER",
                  label: "Owner",
                  icon: Icons.business_center_outlined,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildRoleSelectorButton(
                  role: "DRIVER",
                  label: "Driver",
                  icon: Icons.local_shipping_outlined,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildRoleSelectorButton(
                  role: "BOTH",
                  label: "Both",
                  icon: Icons.handshake_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 36),

          // Step 2: Mission Details
          Text(
            "STEP 2: MISSION DETAILS (OPTIONAL)",
            style: theme.textTheme.labelLarge?.copyWith(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 2.0,
            ),
          ),
          const SizedBox(height: 20),

          // Responsive grid layout for Name, Phone, Country, Corridor, Language, Chapter
          LayoutBuilder(
            builder: (context, constraints) {
              final useSingleColumn = constraints.maxWidth < 450;
              if (useSingleColumn) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildNameInput(theme),
                    const SizedBox(height: 16),
                    _buildPhoneInput(theme),
                    const SizedBox(height: 16),
                    _buildCountryDropdown(theme),
                    const SizedBox(height: 16),
                    _buildLanguageDropdown(theme),
                    const SizedBox(height: 16),
                    _buildChapterInput(theme),
                  ],
                );
              } else {
                return Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildNameInput(theme)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildPhoneInput(theme)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildCountryDropdown(theme)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildLanguageDropdown(theme)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [Expanded(child: _buildChapterInput(theme))],
                    ),
                  ],
                );
              }
            },
          ),
          const SizedBox(height: 40),

          const SizedBox(height: 16),
          Center(
            child: Column(
              children: [
                Text(
                  "The Declaration of Unity",
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.onSurface,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                const SizedBox(width: 80, child: RoadLineSeparator(height: 1)),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Submission Action
          ElevatedButton(
            onPressed: _isSubmitting ? null : _submitDeclaration,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 18),
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
              elevation: 8,
              shadowColor: AppColors.primary.withValues(alpha: 0.25),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: _isSubmitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.onPrimary,
                      ),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "I AM UNITED",
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.onPrimary,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Icon(Icons.gavel_rounded, size: 18),
                    ],
                  ),
          ),
          const SizedBox(height: 16),
          Text(
            "BY PRESSING DECLARE, YOU AFFIRM YOUR PLACE IN THE UNITY",
            style: theme.textTheme.labelLarge?.copyWith(
              fontSize: 9,
              color: AppColors.onSurfaceMuted.withValues(alpha: 0.5),
              letterSpacing: 1.0,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRoleSelectorButton({
    required String role,
    required String label,
    required IconData icon,
  }) {
    final isSelected = _selectedRole == role;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedRole = role;
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
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
              size: 28,
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 11,
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

  Widget _buildNameInput(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "ASSOCIATE NAME",
          style: theme.textTheme.labelLarge?.copyWith(
            fontSize: 9,
            color: AppColors.onSurfaceMuted.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: _nameController,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.onSurface,
            fontSize: 14,
          ),
          decoration: const InputDecoration(
            hintText: "e.g. John Doe",
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildPhoneInput(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "PHONE NUMBER",
          style: theme.textTheme.labelLarge?.copyWith(
            fontSize: 9,
            color: AppColors.onSurfaceMuted.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.onSurface,
            fontSize: 14,
          ),
          decoration: const InputDecoration(
            hintText: "e.g. +1 (555) 019-2834",
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildCountryDropdown(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "COUNTRY",
          style: theme.textTheme.labelLarge?.copyWith(
            fontSize: 9,
            color: AppColors.onSurfaceMuted.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          initialValue: _selectedCountry,
          dropdownColor: AppColors.surfaceContainer,
          iconEnabledColor: AppColors.primary,
          decoration: const InputDecoration(
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          items: _countries.map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.onSurface,
                  fontSize: 14,
                ),
              ),
            );
          }).toList(),
          onChanged: (newValue) {
            if (newValue != null) {
              setState(() {
                _selectedCountry = newValue;
              });
            }
          },
        ),
      ],
    );
  }

  Widget _buildLanguageDropdown(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "PRIMARY LANGUAGE",
          style: theme.textTheme.labelLarge?.copyWith(
            fontSize: 9,
            color: AppColors.onSurfaceMuted.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          initialValue: _selectedLanguage,
          dropdownColor: AppColors.surfaceContainer,
          iconEnabledColor: AppColors.primary,
          decoration: const InputDecoration(
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          items: _languages.map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.onSurface,
                  fontSize: 14,
                ),
              ),
            );
          }).toList(),
          onChanged: (newValue) {
            if (newValue != null) {
              setState(() {
                _selectedLanguage = newValue;
              });
            }
          },
        ),
      ],
    );
  }

  Widget _buildChapterInput(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "LOCAL CHAPTER",
          style: theme.textTheme.labelLarge?.copyWith(
            fontSize: 9,
            color: AppColors.onSurfaceMuted.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: _chapterController,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.onSurface,
            fontSize: 14,
          ),
          decoration: const InputDecoration(
            hintText: "e.g. California, Texas",
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessState(ThemeData theme) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 550),
        child: GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Glowing emblem
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      blurRadius: 24,
                      spreadRadius: 6,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.verified_user_rounded,
                  color: AppColors.primary,
                  size: 48,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                "Identity Affirmed",
                style: theme.textTheme.headlineLarge?.copyWith(
                  color: AppColors.primary,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                "You are now part of a global unity. Your beacon is active in the TODA corridor.",
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: AppColors.onSurfaceMuted,
                  fontSize: 15,
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              const SizedBox(width: 200, child: RoadLineSeparator()),
              const SizedBox(height: 36),
              TextButton(
                onPressed: widget.onReturnToDashboard,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                child: Text(
                  "RETURN TO DASHBOARD",
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                    letterSpacing: 2.0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
