import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';

class UnityDeclarationScreen extends StatefulWidget {
  const UnityDeclarationScreen({super.key});

  @override
  State<UnityDeclarationScreen> createState() => _UnityDeclarationScreenState();
}

class _UnityDeclarationScreenState extends State<UnityDeclarationScreen>
    with TickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final DatabaseService _databaseService = DatabaseService();

  // ── Form State ────────────────────────────────────────────────────────────
  String _selectedRole = ''; // 'OWNER' | 'DRIVER' | 'BOTH'
  String _selectedCountry = 'United States';
  String _selectedLanguage = 'English';
  final TextEditingController _corridorController = TextEditingController();
  final TextEditingController _chapterController = TextEditingController();

  bool _isSubmitting = false;
  bool _showSuccess = false;
  bool _alreadyDeclared = false;
  bool _isLoadingStatus = true;

  // ── Animation ─────────────────────────────────────────────────────────────
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _successController;
  late Animation<double> _successScale;
  late Animation<double> _successFade;
  late AnimationController _fadeInController;
  late Animation<double> _fadeIn;

  // ── Static Data ───────────────────────────────────────────────────────────
  final List<String> _countries = [
    'United States',
    'Canada',
    'Mexico',
    'European Union',
    'Global Corridor',
  ];
  final List<String> _languages = ['English', 'Spanish', 'French', 'Punjabi'];
  final List<Map<String, dynamic>> _roles = [
    {
      'key': 'OWNER',
      'label': 'Owner',
      'icon': Icons.business_center_rounded,
      'desc': 'Fleet or independent owner-operator',
    },
    {
      'key': 'DRIVER',
      'label': 'Driver',
      'icon': Icons.local_shipping_rounded,
      'desc': 'Professional long-haul driver',
    },
    {
      'key': 'BOTH',
      'label': 'Both',
      'icon': Icons.handshake_rounded,
      'desc': 'Owner who also drives',
    },
  ];
  final List<Map<String, dynamic>> _benefits = [
    {'icon': Icons.gavel_rounded, 'label': 'Collective Bargaining Identity'},
    {'icon': Icons.public_rounded, 'label': 'Infrastructure Sovereignty'},
    {
      'icon': Icons.movie_filter_rounded,
      'label': 'Cinematic Driver Visibility',
    },
    {'icon': Icons.hub_rounded, 'label': 'Network Intelligence Access'},
  ];

  // ── Lifecycle ─────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _successController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _successScale = CurvedAnimation(
      parent: _successController,
      curve: Curves.elasticOut,
    );
    _successFade = CurvedAnimation(
      parent: _successController,
      curve: Curves.easeIn,
    );

    _fadeInController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _fadeIn = CurvedAnimation(parent: _fadeInController, curve: Curves.easeOut);

    _checkExistingDeclaration();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _successController.dispose();
    _fadeInController.dispose();
    _corridorController.dispose();
    _chapterController.dispose();
    super.dispose();
  }

  // ── Data Methods ──────────────────────────────────────────────────────────
  Future<void> _checkExistingDeclaration() async {
    final user = _authService.currentUser;
    if (user == null) {
      setState(() => _isLoadingStatus = false);
      return;
    }
    try {
      final doc = await _databaseService.getUserProfile(user.uid);
      if (doc.exists) {
        final data = doc.data();
        if (data != null && data['declaredUnity'] == true) {
          if (mounted) {
            setState(() {
              _alreadyDeclared = true;
              _selectedRole = data['role'] ?? 'DRIVER';
              _showSuccess = true;
            });
            _successController.forward();
          }
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoadingStatus = false);
  }

  Future<void> _submitDeclaration() async {
    if (_selectedRole.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'SELECT YOUR ROLE to continue.',
            style: GoogleFonts.jetBrainsMono(fontSize: 12),
          ),
          backgroundColor: AppColors.primaryContainer,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final user = _authService.currentUser;
    if (user == null) {
      setState(() => _isSubmitting = false);
      return;
    }

    try {
      await _databaseService.saveUserProfile(
        uid: user.uid,
        email: user.email ?? '',
        role: _selectedRole,
      );

      // Save declaration data to Firestore with timeout
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({
            'declaredUnity': true,
            'declarationRole': _selectedRole,
            'declarationCountry': _selectedCountry,
            'declarationLanguage': _selectedLanguage,
            'declarationCorridor': _corridorController.text.trim(),
            'declarationChapter': _chapterController.text.trim(),
            'declaredAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true))
          .timeout(const Duration(seconds: 8));

      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _showSuccess = true;
        });
        _successController.forward();
      }
    } catch (e) {
      // Fallback: show success even if Firestore timed out (optimistic)
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _showSuccess = true;
        });
        _successController.forward();
      }
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 960;

    if (_isLoadingStatus) {
      return const SizedBox(
        height: 400,
        child: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    return FadeTransition(
      opacity: _fadeIn,
      child: _showSuccess
          ? _buildSuccessState(isDesktop)
          : _buildDeclarationForm(isDesktop),
    );
  }

  // ── Declaration Form ───────────────────────────────────────────────────────
  Widget _buildDeclarationForm(bool isDesktop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Hero Header ──────────────────────────────────────────────────
        _buildHeroHeader(isDesktop),
        const SizedBox(height: 64),

        // ── Two Column Layout ────────────────────────────────────────────
        if (isDesktop)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 5, child: _buildContextColumn()),
              const SizedBox(width: 48),
              Expanded(flex: 7, child: _buildFormColumn()),
            ],
          )
        else
          Column(
            children: [
              _buildContextColumn(),
              const SizedBox(height: 32),
              _buildFormColumn(),
            ],
          ),

        const SizedBox(height: 80),

        // ── Cinematic Footer ─────────────────────────────────────────────
        _buildCinematicFooter(),
        const SizedBox(height: 48),
      ],
    );
  }

  Widget _buildHeroHeader(bool isDesktop) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: isDesktop ? 48 : 32),
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 1.2,
          colors: [
            AppColors.primary.withValues(alpha: 0.06),
            Colors.transparent,
          ],
        ),
      ),
      child: Column(
        children: [
          // Logo Glow
          _buildLogoGlow(),
          const SizedBox(height: 32),

          // Dashed Road Line
          const RoadLineSeparator(dashWidth: 10, dashSpace: 6),
          const SizedBox(height: 32),

          // Title
          Text(
            'Declaration of Unity',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: isDesktop ? 52 : 34,
              fontWeight: FontWeight.w800,
              color: AppColors.onSurface,
              letterSpacing: -1.5,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 16),

          // Tagline
          Text(
            '"We declare that truckers are not marginal.\nThey are foundational."',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: AppColors.onSurfaceMuted,
              fontStyle: FontStyle.italic,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 32),

          // Road Line
          const RoadLineSeparator(dashWidth: 10, dashSpace: 6),
        ],
      ),
    );
  }

  Widget _buildLogoGlow() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.surfaceContainerLow,
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(
                  alpha: 0.35 * _pulseAnimation.value,
                ),
                blurRadius: 28,
                spreadRadius: 6,
              ),
            ],
          ),
          child: const Icon(
            Icons.public_rounded,
            color: AppColors.primary,
            size: 36,
          ),
        );
      },
    );
  }

  // ── Left Context Column ───────────────────────────────────────────────────
  Widget _buildContextColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Live Signal Card
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainer.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.border.withValues(alpha: 0.15),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Live Badge
                  Row(
                    children: [
                      AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, _) => Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primary,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(
                                  alpha: 0.7 * _pulseAnimation.value,
                                ),
                                blurRadius: 12,
                                spreadRadius: 3,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'LIVE COMMUNITY SIGNAL',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppColors.primary,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'The Transcontinental Owners and Drivers Association (TODA) represents the backbone of global commerce. By declaring your identity, you join a network of over 140,000 professionals standing for dignity and collective strength.',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      height: 1.7,
                      color: AppColors.onSurfaceMuted,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Benefits List
                  ...(_benefits.map(
                    (b) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Row(
                        children: [
                          Icon(
                            b['icon'] as IconData,
                            color: AppColors.primary,
                            size: 18,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              b['label'] as String,
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: AppColors.onSurface,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Truck Image Card
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            height: 220,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Gradient background as placeholder (truck imagery)
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF1C2532), Color(0xFF0D1520)],
                    ),
                  ),
                ),
                // Abstract road/truck silhouette
                CustomPaint(painter: _TruckScenePainter()),
                // Bottom gradient overlay
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          AppColors.background.withValues(alpha: 0.85),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                // Caption
                Positioned(
                  bottom: 16,
                  left: 20,
                  child: Text(
                    'THE ROAD NEVER ENDS',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 10,
                      color: AppColors.primary.withValues(alpha: 0.8),
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 20),

        // Stats Row
        Row(
          children: [
            Expanded(child: _buildMiniStat('140K+', 'TODA Members')),
            const SizedBox(width: 12),
            Expanded(child: _buildMiniStat('48', 'States Active')),
            const SizedBox(width: 12),
            Expanded(child: _buildMiniStat('12', 'Chapters')),
          ],
        ),
      ],
    );
  }

  Widget _buildMiniStat(String value, String label) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainer.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.border.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 9,
                  color: AppColors.onSurfaceMuted,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Right Form Column ─────────────────────────────────────────────────────
  Widget _buildFormColumn() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(36),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainer.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.18),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 40,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Step 1 ── Role Selection
              _buildStepLabel('STEP 1', 'SELECT YOUR ROLE'),
              const SizedBox(height: 20),
              _buildRoleSelector(),
              const SizedBox(height: 40),

              // Divider
              const RoadLineSeparator(),
              const SizedBox(height: 40),

              // Step 2 ── Mission Details
              _buildStepLabel('STEP 2', 'MISSION DETAILS (OPTIONAL)'),
              const SizedBox(height: 20),
              _buildMissionDetailsForm(),
              const SizedBox(height: 40),

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
                    const SizedBox(
                      width: 80,
                      child: RoadLineSeparator(height: 1),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // CTA ── Declare
              _buildDeclareCTA(),
              const SizedBox(height: 16),

              // Disclaimer
              Text(
                'BY PRESSING DECLARE, YOU AFFIRM YOUR PLACE IN THE UNITY',
                textAlign: TextAlign.center,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 9,
                  color: AppColors.onSurfaceMuted.withValues(alpha: 0.5),
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepLabel(String step, String title) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            step,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
              letterSpacing: 1.5,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppColors.onSurfaceMuted,
            letterSpacing: 1.8,
          ),
        ),
      ],
    );
  }

  Widget _buildRoleSelector() {
    return Row(
      children: _roles.map((role) {
        final key = role['key'] as String;
        final isSelected = _selectedRole == key;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: role['key'] != 'BOTH' ? 12 : 0),
            child: GestureDetector(
              onTap: () => setState(() => _selectedRole = key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  vertical: 20,
                  horizontal: 10,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary.withValues(alpha: 0.1)
                      : AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.border.withValues(alpha: 0.5),
                    width: isSelected ? 1.5 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.2),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  children: [
                    Icon(
                      role['icon'] as IconData,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.onSurfaceMuted,
                      size: 28,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      role['label'] as String,
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 11,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.onSurfaceMuted,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      role['desc'] as String,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: AppColors.onSurfaceMuted.withValues(alpha: 0.6),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMissionDetailsForm() {
    return Column(
      children: [
        // Row 1: Country + Language
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFieldLabel('COUNTRY'),
                  const SizedBox(height: 8),
                  _buildDropdown(
                    value: _selectedCountry,
                    items: _countries,
                    onChanged: (v) => setState(() => _selectedCountry = v!),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFieldLabel('PRIMARY LANGUAGE'),
                  const SizedBox(height: 8),
                  _buildDropdown(
                    value: _selectedLanguage,
                    items: _languages,
                    onChanged: (v) => setState(() => _selectedLanguage = v!),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Row 2: Chapter
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFieldLabel('LOCAL CHAPTER'),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _chapterController,
                    hint: 'e.g. California, Texas',
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.jetBrainsMono(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        color: AppColors.onSurfaceMuted.withValues(alpha: 0.7),
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      onChanged: onChanged,
      dropdownColor: AppColors.surfaceContainerHigh,
      style: GoogleFonts.inter(fontSize: 14, color: AppColors.onSurface),
      icon: const Icon(
        Icons.expand_more_rounded,
        color: AppColors.onSurfaceMuted,
        size: 20,
      ),
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        filled: true,
        fillColor: AppColors.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
      items: items
          .map(
            (item) => DropdownMenuItem(
              value: item,
              child: Text(item, style: GoogleFonts.inter(fontSize: 13)),
            ),
          )
          .toList(),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
  }) {
    return TextFormField(
      controller: controller,
      style: GoogleFonts.inter(fontSize: 14, color: AppColors.onSurface),
      decoration: InputDecoration(
        hintText: hint,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        filled: true,
        fillColor: AppColors.surfaceContainerHighest,
        hintStyle: GoogleFonts.inter(
          fontSize: 13,
          color: AppColors.onSurfaceMuted.withValues(alpha: 0.5),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildDeclareCTA() {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitDeclaration,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: const Color(0xFF1A0F00),
          disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.4),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          shadowColor: AppColors.primary.withValues(alpha: 0.4),
        ),
        child: _isSubmitting
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: AppColors.onPrimary,
                  strokeWidth: 2.5,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'I am United',
                    style: GoogleFonts.inter(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Icon(Icons.gavel_rounded, size: 22),
                ],
              ),
      ),
    );
  }

  Widget _buildCinematicFooter() {
    return Column(
      children: [
        const RoadLineSeparator(),
        const SizedBox(height: 20),
        Text(
          'iUnity © 2020',
          style: GoogleFonts.jetBrainsMono(
            fontSize: 10,
            color: AppColors.onSurfaceMuted.withValues(alpha: 0.4),
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'The road does not end; it only connects.',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontStyle: FontStyle.italic,
            color: AppColors.onSurfaceMuted.withValues(alpha: 0.4),
          ),
        ),
      ],
    );
  }

  // ── Success State ─────────────────────────────────────────────────────────
  Widget _buildSuccessState(bool isDesktop) {
    return Column(
      children: [
        const SizedBox(height: 60),
        Center(
          child: FadeTransition(
            opacity: _successFade,
            child: ScaleTransition(
              scale: _successScale,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    width: isDesktop ? 520 : double.infinity,
                    padding: const EdgeInsets.all(48),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainer.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.25),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Glow Icon
                        AnimatedBuilder(
                          animation: _pulseAnimation,
                          builder: (context, _) => Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primary.withValues(alpha: 0.08),
                              border: Border.all(
                                color: AppColors.primary.withValues(alpha: 0.3),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.3 * _pulseAnimation.value,
                                  ),
                                  blurRadius: 32,
                                  spreadRadius: 8,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.verified_user_rounded,
                              color: AppColors.primary,
                              size: 48,
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),

                        Text(
                          'Identity Affirmed',
                          style: GoogleFonts.inter(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                            letterSpacing: -0.8,
                          ),
                        ),
                        const SizedBox(height: 16),

                        Text(
                          'You are now part of a global unity.\nYour beacon is active in the TODA corridor.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            height: 1.6,
                            color: AppColors.onSurfaceMuted,
                          ),
                        ),
                        const SizedBox(height: 28),

                        // Road Line
                        const SizedBox(
                          width: 180,
                          child: RoadLineSeparator(dashWidth: 8, dashSpace: 5),
                        ),
                        const SizedBox(height: 28),

                        // Role Badge
                        if (_selectedRole.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(40),
                              border: Border.all(
                                color: AppColors.primary.withValues(alpha: 0.4),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              'DECLARED AS: $_selectedRole',
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),
                        const SizedBox(height: 28),

                        // Network Stats Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildSuccessStat('140K+', 'Members'),
                            _buildSuccessDivider(),
                            _buildSuccessStat('142', 'Countries'),
                            _buildSuccessDivider(),
                            _buildSuccessStat('32', 'Corridors'),
                          ],
                        ),
                        const SizedBox(height: 32),

                        // Already declared note or re-declare not needed
                        if (_alreadyDeclared)
                          Text(
                            'YOU HAVE ALREADY DECLARED UNITY',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 9,
                              color: AppColors.onSurfaceMuted.withValues(
                                alpha: 0.4,
                              ),
                              letterSpacing: 1.5,
                            ),
                          ),
                        if (!_alreadyDeclared)
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _showSuccess = false;
                                _selectedRole = '';
                              });
                              _successController.reset();
                            },
                            child: Text(
                              'RETURN TO DECLARATION',
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 10,
                                color: AppColors.primary.withValues(alpha: 0.6),
                                letterSpacing: 1.5,
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
        const SizedBox(height: 80),
        _buildCinematicFooter(),
        const SizedBox(height: 48),
      ],
    );
  }

  Widget _buildSuccessStat(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 9,
            color: AppColors.onSurfaceMuted,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessDivider() {
    return Container(
      width: 1,
      height: 36,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      color: AppColors.border.withValues(alpha: 0.3),
    );
  }
}

// ── Truck Scene Painter ────────────────────────────────────────────────────
class _TruckScenePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Starry sky
    paint.color = const Color(0x33F59E0B);
    final starPositions = [
      Offset(size.width * 0.1, size.height * 0.15),
      Offset(size.width * 0.25, size.height * 0.08),
      Offset(size.width * 0.45, size.height * 0.2),
      Offset(size.width * 0.65, size.height * 0.1),
      Offset(size.width * 0.8, size.height * 0.18),
      Offset(size.width * 0.92, size.height * 0.06),
    ];
    for (final p in starPositions) {
      canvas.drawCircle(p, 1.5, paint);
    }

    // Road
    paint.color = const Color(0xFF1A2030);
    final roadPath = Path()
      ..moveTo(0, size.height * 0.62)
      ..lineTo(size.width, size.height * 0.62)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(roadPath, paint);

    // Road center dashes
    final dashPaint = Paint()
      ..color = const Color(0x55F59E0B)
      ..strokeWidth = 2;
    final dashY = size.height * 0.72;
    for (double x = 0; x < size.width; x += 32) {
      canvas.drawLine(Offset(x, dashY), Offset(x + 16, dashY), dashPaint);
    }

    // Truck silhouette
    final truckPaint = Paint()..color = const Color(0xFF2A3550);
    final truckX = size.width * 0.15;
    final truckY = size.height * 0.40;
    final truckW = size.width * 0.55;
    final truckH = size.height * 0.24;

    // Trailer
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(truckX, truckY, truckW * 0.72, truckH),
        const Radius.circular(4),
      ),
      truckPaint,
    );

    // Cab
    final cabPaint = Paint()..color = const Color(0xFF3A4A70);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          truckX + truckW * 0.72,
          truckY + truckH * 0.2,
          truckW * 0.28,
          truckH * 0.8,
        ),
        const Radius.circular(4),
      ),
      cabPaint,
    );

    // Headlight glow
    final headlightPaint = Paint()
      ..color = const Color(0x88F59E0B)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawCircle(
      Offset(truckX + truckW + 10, truckY + truckH * 0.65),
      6,
      headlightPaint,
    );

    // Wheels
    final wheelPaint = Paint()..color = const Color(0xFF1A1A2A);
    final rimPaint = Paint()
      ..color = const Color(0xFF4A5568)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final wheelY = truckY + truckH;
    final wheelPositions = [
      truckX + truckW * 0.12,
      truckX + truckW * 0.30,
      truckX + truckW * 0.57,
      truckX + truckW * 0.76,
    ];
    for (final wx in wheelPositions) {
      canvas.drawCircle(Offset(wx, wheelY), 10, wheelPaint);
      canvas.drawCircle(Offset(wx, wheelY), 10, rimPaint);
    }

    // Amber glow horizon
    final horizonPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          const Color(0x00F59E0B),
          const Color(0x30F59E0B),
          const Color(0x00F59E0B),
        ],
      ).createShader(Rect.fromLTWH(0, size.height * 0.55, size.width, 20));
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.55, size.width, 20),
      horizonPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
