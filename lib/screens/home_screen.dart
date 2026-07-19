import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import 'declare_screen.dart';
import 'voice_screen.dart';
import 'connect_screen.dart';
import 'doctrine_screen.dart';
import 'login_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  int _currentNavIndex = 0;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _pulseAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _handleLogout() async {
    try {
      await _authService.signOut();
      if (mounted) {
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

  void _onNavItemTapped(int index, String title, bool isLoggedIn) {
    if (!isLoggedIn && index != 0) {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (context) => const LoginScreen()));
      return;
    }

    if (index == 0 || index == 1 || index == 2 || index == 3 || index == 4) {
      setState(() {
        _currentNavIndex = index;
      });
      return;
    }

    // Placeholder navigation indicator for other tabs
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Routing to $title Screen (Under Construction)..."),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _authService.userStream,
      builder: (context, snapshot) {
        final isLoggedIn = snapshot.hasData && snapshot.data != null;
        final theme = Theme.of(context);
        final size = MediaQuery.of(context).size;
        final isDesktop = size.width > 960;

        return Scaffold(
          appBar: isDesktop
              ? null // Use custom header for desktop
              : AppBar(
                  backgroundColor: AppColors.background.withValues(alpha: 0.8),
                  elevation: 0,
                  titleSpacing: 20,
                  title: Row(
                    children: [
                      Flexible(
                        child: Text(
                          "iUnity",
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1.2,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const UnitySignal(size: 6),
                    ],
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(
                        Icons.person_outline_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      onPressed: () {
                        if (isLoggedIn) {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const ProfileScreen(),
                            ),
                          );
                        } else {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const LoginScreen(),
                            ),
                          );
                        }
                      },
                      tooltip: isLoggedIn ? "Driver Profile" : "Connect Signal",
                    ),
                    const SizedBox(width: 16),
                    if (isLoggedIn)
                      IconButton(
                        icon: const Icon(
                          Icons.logout_rounded,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        onPressed: _handleLogout,
                        tooltip: "Disconnect Signal",
                      )
                    else
                      IconButton(
                        icon: const Icon(
                          Icons.login_rounded,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const LoginScreen(),
                            ),
                          );
                        },
                        tooltip: "Connect Signal",
                      ),
                    const SizedBox(width: 12),
                  ],
                ),
          bottomNavigationBar: isDesktop
              ? null
              : _buildMobileBottomNavBar(isLoggedIn),
          body: SafeArea(
            child: SingleChildScrollView(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1280),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20.0,
                      vertical: 16.0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Desktop Header
                        if (isDesktop) ...[
                          _buildDesktopHeader(theme, isLoggedIn),
                          const SizedBox(height: 40),
                        ],

                        if (_currentNavIndex == 0) ...[
                          // Hero Banner Section
                          _buildHeroSection(theme, isDesktop, isLoggedIn),
                          const SizedBox(height: 48),

                          // Stats Dashboard Grid
                          _buildStatsGrid(theme, isDesktop),
                          const SizedBox(height: 64),

                          // Bento Grid: Map & Insights
                          _buildBentoGrid(theme, isDesktop, isLoggedIn),
                          const SizedBox(height: 64),

                          // Final Call to Action
                          _buildFinalCTA(theme, isLoggedIn),
                          const SizedBox(height: 40),

                          // Footer
                          _buildFooter(),
                          const SizedBox(height: 24),
                        ] else if (_currentNavIndex == 1) ...[
                          DeclareScreen(
                            onReturnToDashboard: () {
                              setState(() {
                                _currentNavIndex = 0;
                              });
                            },
                          ),
                          const SizedBox(height: 40),
                          _buildFooter(),
                          const SizedBox(height: 24),
                        ] else if (_currentNavIndex == 2) ...[
                          const VoiceScreen(),
                          const SizedBox(height: 40),
                          _buildFooter(),
                          const SizedBox(height: 24),
                        ] else if (_currentNavIndex == 3) ...[
                          ConnectScreen(
                            onNavigateToDeclare: () {
                              setState(() {
                                _currentNavIndex = 1;
                              });
                            },
                            onNavigateToDoctrine: () {
                              setState(() {
                                _currentNavIndex = 4;
                              });
                            },
                          ),
                          const SizedBox(height: 40),
                          _buildFooter(),
                          const SizedBox(height: 24),
                        ] else if (_currentNavIndex == 4) ...[
                          DoctrineScreen(
                            isNested: true,
                            onAffirmDoctrine: () {
                              if (isLoggedIn) {
                                setState(() {
                                  _currentNavIndex = 1;
                                });
                              } else {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => const LoginScreen(),
                                  ),
                                );
                              }
                            },
                          ),
                          const SizedBox(height: 40),
                          _buildFooter(),
                          const SizedBox(height: 24),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          floatingActionButton: _currentNavIndex == 0
              ? FloatingActionButton(
                  onPressed: () {
                    if (isLoggedIn) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Creating a new corridor signal..."),
                        ),
                      );
                    } else {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const LoginScreen(),
                        ),
                      );
                    }
                  },
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                  shape: const CircleBorder(),
                  child: const Icon(Icons.add_road_rounded, size: 24),
                )
              : null,
        );
      },
    );
  }

  Widget _buildDesktopHeader(ThemeData theme, bool isLoggedIn) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "iUnity",
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1.2,
                  ),
                ),
                const SizedBox(width: 8),
                const UnitySignal(size: 6),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildDesktopNavItem("Home", 0, isLoggedIn),
                    _buildDesktopNavItem("Declare", 1, isLoggedIn),
                    _buildDesktopNavItem("Voice", 2, isLoggedIn),
                    _buildDesktopNavItem("Connect", 3, isLoggedIn),
                    _buildDesktopNavItem("Doctrine", 4, isLoggedIn),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Icon(Icons.language, color: AppColors.primary, size: 20),
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(
                    Icons.person_outline_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  onPressed: () {
                    if (isLoggedIn) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const ProfileScreen(),
                        ),
                      );
                    } else {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const LoginScreen(),
                        ),
                      );
                    }
                  },
                  tooltip: isLoggedIn ? "Driver Profile" : "Connect Signal",
                ),
                const SizedBox(width: 16),
                if (isLoggedIn)
                  IconButton(
                    icon: const Icon(
                      Icons.logout_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    onPressed: _handleLogout,
                    tooltip: "Disconnect Signal",
                    // Use a unique ID key if needed but this is standard
                  )
                else
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const LoginScreen(),
                        ),
                      );
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    child: Text(
                      'LOG IN',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopNavItem(String label, int index, bool isLoggedIn) {
    final isActive = _currentNavIndex == index;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: TextButton(
        onPressed: () => _onNavItemTapped(index, label, isLoggedIn),
        style: TextButton.styleFrom(
          foregroundColor: isActive
              ? AppColors.primary
              : AppColors.onSurfaceMuted,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        child: Text(
          label.toUpperCase(),
          style: GoogleFonts.jetBrainsMono(
            fontSize: 12,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildMobileBottomNavBar(bool isLoggedIn) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow.withValues(alpha: 0.9),
        border: const Border(
          top: BorderSide(color: AppColors.border, width: 0.5),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Expanded(
                child: _buildMobileNavItem(
                  Icons.home_rounded,
                  "Home",
                  0,
                  isLoggedIn,
                ),
              ),
              Expanded(
                child: _buildMobileNavItem(
                  Icons.verified_user_rounded,
                  "Declare",
                  1,
                  isLoggedIn,
                ),
              ),
              Expanded(
                child: _buildMobileNavItem(
                  Icons.campaign_rounded,
                  "Voice",
                  2,
                  isLoggedIn,
                ),
              ),
              Expanded(
                child: _buildMobileNavItem(
                  Icons.groups_rounded,
                  "Connect",
                  3,
                  isLoggedIn,
                ),
              ),
              Expanded(
                child: _buildMobileNavItem(
                  Icons.auto_stories_rounded,
                  "Doctrine",
                  4,
                  isLoggedIn,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileNavItem(
    IconData icon,
    String label,
    int index,
    bool isLoggedIn,
  ) {
    final isActive = _currentNavIndex == index;
    return InkWell(
      onTap: () => _onNavItemTapped(index, label, isLoggedIn),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: isActive
                ? BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  )
                : null,
            child: Icon(
              icon,
              color: isActive
                  ? AppColors.primary
                  : AppColors.onSurfaceMuted.withValues(alpha: 0.6),
              size: 24,
            ),
          ),
          const SizedBox(height: 4),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 9,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive
                    ? AppColors.primary
                    : AppColors.onSurfaceMuted.withValues(alpha: 0.6),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection(ThemeData theme, bool isDesktop, bool isLoggedIn) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: isDesktop ? 60 : 30),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Active Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const UnitySignal(size: 8),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    "GLOBAL SIGNAL ACTIVE",
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: AppColors.primary,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2.0,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Headline
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: theme.textTheme.displayLarge?.copyWith(
                fontSize: isDesktop ? 64 : 36,
                letterSpacing: -1.5,
              ),
              children: [
                TextSpan(
                  text: isDesktop
                      ? "Truckers of the World,\n"
                      : "Truckers of the\nWorld, ",
                ),
                TextSpan(
                  text: "Unite!",
                  style: const TextStyle(color: AppColors.primary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Core Slogans
          Column(
            children: [
              Text(
                "We are not Marginal.",
                style: GoogleFonts.inter(
                  fontSize: isDesktop ? 22 : 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "We are Foundational.",
                style: GoogleFonts.inter(
                  fontSize: isDesktop ? 22 : 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Subtitle
          Container(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Text(
              "The pulse of the world's economy beats through our engines. Together, we are the network that cannot be broken.",
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: AppColors.onSurfaceMuted,
                fontSize: isDesktop ? 18 : 15,
                height: 1.6,
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Action Buttons
          isDesktop
              ? Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 16,
                  runSpacing: 12,
                  children: [
                    ElevatedButton(
                      onPressed: () =>
                          _onNavItemTapped(4, "Doctrine", isLoggedIn),
                      child: const Text("THE TRUCKERS MANIFESTO"),
                    ),
                    OutlinedButton(
                      onPressed: () =>
                          _onNavItemTapped(4, "Doctrine", isLoggedIn),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.onSurface,
                        side: const BorderSide(
                          color: AppColors.border,
                          width: 1.5,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        "UNITATIS DOCTRINE",
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                )
              : Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () =>
                              _onNavItemTapped(4, "Doctrine", isLoggedIn),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text("THE TRUCKERS MANIFESTO"),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () =>
                              _onNavItemTapped(4, "Doctrine", isLoggedIn),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.onSurface,
                            side: const BorderSide(
                              color: AppColors.border,
                              width: 1.5,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            "UNITATIS DOCTRINE",
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppColors.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(ThemeData theme, bool isDesktop) {
    final List<Map<String, String>> stats = [
      {"value": "1.2M+", "label": "ASSOCIATES DECLARED"},
      {"value": "142", "label": "COUNTRIES CONNECTED"},
      {"value": "850K", "label": "VOICES SHARED"},
      {"value": "32", "label": "CORRIDORS ACTIVE"},
    ];

    final width = MediaQuery.of(context).size.width;
    final textScale = MediaQuery.textScalerOf(context).scale(1.0);
    double childAspectRatio = 1.3;
    if (!isDesktop) {
      if (width < 360) {
        childAspectRatio = 1.0;
      } else if (width < 400) {
        childAspectRatio = 1.15;
      }
      childAspectRatio = (childAspectRatio / textScale).clamp(0.7, 1.5);
    } else {
      childAspectRatio = (1.6 / textScale).clamp(1.0, 2.0);
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isDesktop ? 4 : 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: childAspectRatio,
      ),
      itemCount: stats.length,
      itemBuilder: (context, index) {
        return GlassCard(
          padding: const EdgeInsets.all(16),
          borderRadius: 16,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  stats[index]["value"]!,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.headlineLarge?.copyWith(
                    fontSize: isDesktop ? 36 : 28,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Flexible(
                child: Text(
                  stats[index]["label"]!,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontSize: 10,
                    color: AppColors.onSurfaceMuted.withValues(alpha: 0.8),
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBentoGrid(ThemeData theme, bool isDesktop, bool isLoggedIn) {
    if (isDesktop) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 2, child: _buildMapCard(theme, true)),
          const SizedBox(width: 20),
          Expanded(flex: 1, child: _buildInsightsCard(theme, isLoggedIn)),
        ],
      );
    } else {
      return Column(
        children: [
          _buildMapCard(theme, false),
          const SizedBox(height: 20),
          _buildInsightsCard(theme, isLoggedIn),
        ],
      );
    }
  }

  Widget _buildMapCard(ThemeData theme, bool isDesktop) {
    return GlassCard(
      padding: const EdgeInsets.all(24),
      borderRadius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Global Signal Map",
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "LIVE MOVEMENT DENSITY",
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelLarge?.copyWith(fontSize: 10),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Signal Status Indicator
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(
                                alpha: 0.5 * _pulseAnimation.value,
                              ),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "LIVE",
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: AppColors.primary,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Stylized Map Canvas Container
          Container(
            height: isDesktop ? 380 : 260,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.border.withValues(alpha: 0.3),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return CustomPaint(
                    painter: MapPainter(pulseValue: _pulseAnimation.value),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 20,
            runSpacing: 8,
            children: [
              _buildMapLegendItem(AppColors.primary, "HIGH ACTIVITY"),
              _buildMapLegendItem(
                AppColors.primary.withValues(alpha: 0.4),
                "CONNECTED CORRIDORS",
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMapLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 9,
              color: AppColors.onSurfaceMuted,
              letterSpacing: 1.0,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInsightsCard(ThemeData theme, bool isLoggedIn) {
    final List<Map<String, String>> articles = [
      {
        "category": "ANALYSIS",
        "readTime": "5 min read",
        "title": "The Future of the I-80 Corridor",
        "desc":
            "A deep dive into how logistics automation is reshaping the backbone of American freight transport.",
      },
      {
        "category": "STORY",
        "readTime": "8 min read",
        "title": "Mental Health on the Long Haul",
        "desc":
            "Veteran drivers share their strategies for maintaining mental clarity and connection while on the road.",
      },
      {
        "category": "ADVOCACY",
        "readTime": "4 min read",
        "title": "Why Unity Matters in 2020",
        "desc":
            "Understanding the collective power of individual drivers in an increasingly fragmented global economy.",
      },
    ];

    return GlassCard(
      padding: const EdgeInsets.all(24),
      borderRadius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  "Movement Insights",
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              InkWell(
                onTap: () {
                  if (isLoggedIn) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Loading insight archive..."),
                      ),
                    );
                  } else {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const LoginScreen(),
                      ),
                    );
                  }
                },
                child: Text(
                  "VIEW ALL",
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: AppColors.primary,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: articles.length,
            separatorBuilder: (context, index) => const Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: RoadLineSeparator(),
            ),
            itemBuilder: (context, index) {
              final item = articles[index];
              return InkWell(
                onTap: () {
                  if (isLoggedIn) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Opening '${item["title"]}'")),
                    );
                  } else {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const LoginScreen(),
                      ),
                    );
                  }
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              item["category"]!,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: AppColors.primary,
                                fontSize: 8,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            item["readTime"]!,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontSize: 8,
                              color: AppColors.onSurfaceMuted.withValues(
                                alpha: 0.6,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item["title"]!,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item["desc"]!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFinalCTA(ThemeData theme, bool isLoggedIn) {
    final isDesktop = MediaQuery.of(context).size.width > 960;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40.0),
      child: Column(
        children: [
          Text(
            "The Road is Long, But We Never Drive Alone.",
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
              fontSize: 22,
            ),
          ),
          const SizedBox(height: 24),
          const SizedBox(width: 120, child: RoadLineSeparator()),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => _onNavItemTapped(4, "Doctrine", isLoggedIn),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 40 : 20,
                vertical: 20,
              ),
            ),
            child: const Text(
              "READ THE DECLARATION OF UNITY",
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        Center(
          child: Container(
            width: 1,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.primary.withValues(alpha: 0.4),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: Text(
            "ESTABLISHED IN SOLIDARITY • 2020",
            style: GoogleFonts.jetBrainsMono(
              fontSize: 9,
              color: AppColors.onSurfaceMuted.withValues(alpha: 0.4),
              letterSpacing: 3.0,
            ),
          ),
        ),
      ],
    );
  }
}

// Custom World Constellation Map Painter
class MapPainter extends CustomPainter {
  final double pulseValue;

  MapPainter({required this.pulseValue});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.border.withValues(alpha: 0.15)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Draw background grid pattern
    const int gridSpacing = 20;
    for (double x = 0; x < size.width; x += gridSpacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += gridSpacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Stylized constellation coordinate nodes (continent approximations)
    final nodes = [
      Offset(size.width * 0.18, size.height * 0.35), // NW (Seattle/LA)
      Offset(size.width * 0.35, size.height * 0.30), // NE (New York/Chicago)
      Offset(
        size.width * 0.42,
        size.height * 0.70,
      ), // South America (Sao Paulo)
      Offset(
        size.width * 0.54,
        size.height * 0.28,
      ), // West Europe (London/Paris)
      Offset(size.width * 0.62, size.height * 0.75), // South Africa (Cape Town)
      Offset(size.width * 0.75, size.height * 0.48), // India (Mumbai/Delhi)
      Offset(size.width * 0.85, size.height * 0.36), // East Asia (Tokyo)
      Offset(size.width * 0.88, size.height * 0.76), // Oceania (Sydney)
    ];

    // Node connections list
    final connections = [
      [0, 1], // NW - NE
      [1, 2], // NE - SA
      [1, 3], // NE - WE
      [3, 4], // WE - SAfrica
      [3, 5], // WE - India
      [5, 6], // India - East Asia
      [6, 7], // East Asia - Oceania
      [5, 7], // India - Oceania
      [2, 4], // SA - SAfrica
    ];

    // Paint active connection lines
    final linePaint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.15)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    for (final conn in connections) {
      canvas.drawLine(nodes[conn[0]], nodes[conn[1]], linePaint);
    }

    // Paint glowing nodes
    final nodeFillPaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.fill;

    for (int i = 0; i < nodes.length; i++) {
      final node = nodes[i];
      // Larger pulsing active hubs, smaller solid connections
      final isMajorHub = i == 1 || i == 3 || i == 6;

      if (isMajorHub) {
        // Pulse ring paint
        final pulsePaint = Paint()
          ..color = AppColors.primary.withValues(
            alpha: 0.3 * (1.0 - pulseValue),
          )
          ..style = PaintingStyle.fill;

        canvas.drawCircle(node, 16.0 * pulseValue, pulsePaint);
        canvas.drawCircle(node, 6.0, nodeFillPaint);
      } else {
        canvas.drawCircle(node, 4.0, nodeFillPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant MapPainter oldDelegate) {
    return oldDelegate.pulseValue != pulseValue;
  }
}
