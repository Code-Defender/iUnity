import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class ConnectScreen extends StatefulWidget {
  final VoidCallback? onNavigateToDeclare;
  final VoidCallback? onNavigateToDoctrine;

  const ConnectScreen({
    super.key,
    this.onNavigateToDeclare,
    this.onNavigateToDoctrine,
  });

  @override
  State<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends State<ConnectScreen>
    with TickerProviderStateMixin {
  late AnimationController _signalController;
  late AnimationController _fadeController;
  late Animation<double> _fadeIn;
  late AnimationController _gridController;
  late Animation<double> _gridAnimation;

  // ── Mock Movement Insights ──────────────────────────────────────────────
  final List<Map<String, dynamic>> _insights = [
    {
      'tag': 'ANALYSIS',
      'tagColor': 0xFFFFB95F,
      'readTime': '5 min read',
      'title': 'The Future of the I-80 Corridor',
      'summary':
          'A deep dive into how logistics automation is reshaping the backbone of American freight transport.',
    },
    {
      'tag': 'STORY',
      'tagColor': 0xFFBDC7DB,
      'readTime': '8 min read',
      'title': 'Mental Health on the Long Haul',
      'summary':
          'Veteran drivers share their strategies for maintaining mental clarity while on the road for weeks.',
    },
    {
      'tag': 'ADVOCACY',
      'tagColor': 0xFFFFB95F,
      'readTime': '4 min read',
      'title': 'Why Unity Matters in 2020',
      'summary':
          'Understanding the collective power of individual drivers in an increasingly fragmented global economy.',
    },
    {
      'tag': 'REPORT',
      'tagColor': 0xFF8FD5FF,
      'readTime': '6 min read',
      'title': 'TODA Chapter Expansion: West Coast',
      'summary':
          'New regional chapters opening across California, Oregon, and Washington with over 3,000 new members.',
    },
  ];

  // ── Coming Soon Features ────────────────────────────────────────────────
  final List<Map<String, dynamic>> _communityFeatures = [
    {
      'icon': Icons.groups_rounded,
      'label': 'Community Groups',
      'desc': 'Join regional driver collectives',
      'badge': 'V2',
    },
    {
      'icon': Icons.forum_rounded,
      'label': 'Discussion Forums',
      'desc': 'Share insights & experiences',
      'badge': 'V2',
    },
    {
      'icon': Icons.event_rounded,
      'label': 'TODA Events',
      'desc': 'Rallies, meetups & town halls',
      'badge': 'V2',
    },
    {
      'icon': Icons.auto_awesome_rounded,
      'label': 'AI Assistant',
      'desc': 'Organize, Automate, Simplify. Powered by AI.',
      'badge': 'V2',
    },
    {
      'icon': Icons.record_voice_over_rounded,
      'label': 'Driver Stories',
      'desc': 'Cinematic first-person narratives',
      'badge': 'V2',
    },
    {
      'icon': Icons.workspace_premium_rounded,
      'label': 'Member Directory',
      'desc': 'Connect with TODA members',
      'badge': 'V2',
    },
  ];

  // ── Map hotspot positions ───────────────────────────────────────────────
  final List<Map<String, dynamic>> _hotspots = [
    {'x': 0.22, 'y': 0.38, 'size': 8.0, 'delay': 0.0},
    {'x': 0.35, 'y': 0.55, 'size': 5.0, 'delay': 0.4},
    {'x': 0.48, 'y': 0.45, 'size': 10.0, 'delay': 0.8},
    {'x': 0.60, 'y': 0.35, 'size': 6.0, 'delay': 0.2},
    {'x': 0.72, 'y': 0.50, 'size': 7.0, 'delay': 0.6},
    {'x': 0.82, 'y': 0.40, 'size': 5.0, 'delay': 1.0},
    {'x': 0.15, 'y': 0.62, 'size': 4.0, 'delay': 0.3},
    {'x': 0.55, 'y': 0.65, 'size': 6.0, 'delay': 0.7},
  ];

  @override
  void initState() {
    super.initState();

    _signalController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
    _fadeIn = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);

    _gridController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
    _gridAnimation = CurvedAnimation(
      parent: _gridController,
      curve: Curves.linear,
    );
  }

  @override
  void dispose() {
    _signalController.dispose();
    _fadeController.dispose();
    _gridController.dispose();
    super.dispose();
  }

  void _showComingSoon(String feature) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (ctx) => _ComingSoonDialog(feature: feature),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 960;

    return FadeTransition(
      opacity: _fadeIn,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Hero Section ───────────────────────────────────────────────
          _buildHeroSection(isDesktop),
          const SizedBox(height: 64),

          // ── Global Unity Stats ─────────────────────────────────────────
          _buildStatsGrid(isDesktop),
          const SizedBox(height: 64),

          // ── Bento Grid: Map + Insights ─────────────────────────────────
          _buildBentoGrid(isDesktop),
          const SizedBox(height: 64),

          // ── Community Features (Coming Soon) ───────────────────────────
          _buildCommunitySection(isDesktop),
          const SizedBox(height: 80),

          // ── Final CTA ──────────────────────────────────────────────────
          _buildFinalCTA(isDesktop),
          const SizedBox(height: 64),
        ],
      ),
    );
  }

  // ── Hero Section ──────────────────────────────────────────────────────────
  Widget _buildHeroSection(bool isDesktop) {
    return Stack(
      children: [
        // Background grid parallax
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _gridAnimation,
            builder: (context, _) => CustomPaint(
              painter: _GridPainter(progress: _gridAnimation.value),
            ),
          ),
        ),

        // Content
        Container(
          padding: EdgeInsets.symmetric(vertical: isDesktop ? 80 : 48),
          child: Column(
            children: [
              // Global Signal Active Badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(40),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedBuilder(
                      animation: _signalController,
                      builder: (context, _) {
                        final scale =
                            1.0 +
                            0.5 *
                                math.sin(_signalController.value * 2 * math.pi);
                        return Transform.scale(
                          scale: scale.clamp(1.0, 1.5),
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primary,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.6,
                                  ),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'GLOBAL SIGNAL ACTIVE',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.primary,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Headline
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: GoogleFonts.inter(
                    fontSize: isDesktop ? 68 : 38,
                    fontWeight: FontWeight.w800,
                    color: AppColors.onSurface,
                    letterSpacing: -2.0,
                    height: 1.1,
                  ),
                  children: [
                    const TextSpan(text: 'Truckers of the\nWorld, '),
                    TextSpan(
                      text: 'Unite!',
                      style: TextStyle(
                        color: AppColors.primary,
                        shadows: [
                          Shadow(
                            color: AppColors.primary.withValues(alpha: 0.4),
                            blurRadius: 24,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Subtext
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: isDesktop ? 600 : 340),
                child: Text(
                  'We are not marginal. We are foundational. The pulse of the world\'s economy beats through our engines. Together, we are the network that cannot be broken.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: AppColors.onSurfaceMuted,
                    height: 1.7,
                  ),
                ),
              ),
              const SizedBox(height: 36),

              // Hero CTAs
              if (isDesktop)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildHeroCTA(
                      'Declare Unity',
                      Icons.gavel_rounded,
                      isPrimary: true,
                      onTap: () => widget.onNavigateToDeclare?.call(),
                    ),
                    const SizedBox(width: 16),
                    _buildHeroCTA(
                      'Read the Doctrine',
                      Icons.auto_stories_rounded,
                      isPrimary: false,
                      onTap: () => widget.onNavigateToDoctrine?.call(),
                    ),
                  ],
                )
              else
                Column(
                  children: [
                    _buildHeroCTA(
                      'Declare Unity',
                      Icons.gavel_rounded,
                      isPrimary: true,
                      onTap: () => widget.onNavigateToDeclare?.call(),
                      fullWidth: true,
                    ),
                    const SizedBox(height: 12),
                    _buildHeroCTA(
                      'Read the Doctrine',
                      Icons.auto_stories_rounded,
                      isPrimary: false,
                      onTap: () => widget.onNavigateToDoctrine?.call(),
                      fullWidth: true,
                    ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeroCTA(
    String label,
    IconData icon, {
    required bool isPrimary,
    required VoidCallback onTap,
    bool fullWidth = false,
  }) {
    return SizedBox(
      width: fullWidth ? double.infinity : null,
      height: 52,
      child: isPrimary
          ? ElevatedButton.icon(
              onPressed: onTap,
              icon: Icon(icon, size: 20),
              label: Text(label),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: const Color(0xFF1A0F00),
                padding: const EdgeInsets.symmetric(horizontal: 28),
                textStyle: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            )
          : OutlinedButton.icon(
              onPressed: onTap,
              icon: Icon(icon, size: 20),
              label: Text(label),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.onSurface,
                padding: const EdgeInsets.symmetric(horizontal: 28),
                side: BorderSide(
                  color: AppColors.border.withValues(alpha: 0.6),
                  width: 1,
                ),
                textStyle: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
    );
  }

  // ── Stats Grid ────────────────────────────────────────────────────────────
  Widget _buildStatsGrid(bool isDesktop) {
    final stats = [
      {'value': '1.2M+', 'label': 'Associates Declared'},
      {'value': '142', 'label': 'Countries Connected'},
      {'value': '850K', 'label': 'Voices Shared'},
      {'value': '32', 'label': 'Corridors Active'},
    ];

    return GridView.count(
      crossAxisCount: isDesktop ? 4 : 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: isDesktop ? 1.6 : 1.3,
      children: stats
          .map((s) => _buildStatCard(s['value']!, s['label']!))
          .toList(),
    );
  }

  Widget _buildStatCard(String value, String label) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainer.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.border.withValues(alpha: 0.15),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                label.toUpperCase(),
                textAlign: TextAlign.center,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                  color: AppColors.onSurfaceMuted,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Bento Grid ────────────────────────────────────────────────────────────
  Widget _buildBentoGrid(bool isDesktop) {
    if (isDesktop) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 8, child: _buildGlobalSignalMap()),
          const SizedBox(width: 16),
          Expanded(flex: 4, child: _buildInsightsFeed()),
        ],
      );
    } else {
      return Column(
        children: [
          _buildGlobalSignalMap(),
          const SizedBox(height: 16),
          _buildInsightsFeed(),
        ],
      );
    }
  }

  Widget _buildGlobalSignalMap() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          height: 480,
          decoration: BoxDecoration(
            color: AppColors.surfaceContainer.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.border.withValues(alpha: 0.15),
              width: 1,
            ),
          ),
          child: Stack(
            children: [
              // Map Background
              Positioned.fill(child: CustomPaint(painter: _WorldMapPainter())),

              // Animated Hotspots
              ...(_hotspots.map((h) => _buildHotspot(h))),

              // Connection Lines (animated)
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _signalController,
                  builder: (context, _) => CustomPaint(
                    painter: _ConnectionLinePainter(
                      progress: _signalController.value,
                      hotspots: _hotspots,
                    ),
                  ),
                ),
              ),

              // Header Labels
              Positioned(
                top: 24,
                left: 24,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Global Signal Map',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface,
                      ),
                    ),
                    Text(
                      'Live movement density',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 10,
                        color: AppColors.onSurfaceMuted,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),

              // Legend
              Positioned(
                bottom: 20,
                left: 24,
                child: Row(
                  children: [
                    _buildLegendItem(AppColors.primary, 'High Activity'),
                    const SizedBox(width: 20),
                    _buildLegendItem(
                      AppColors.primary.withValues(alpha: 0.35),
                      'Connected',
                    ),
                  ],
                ),
              ),

              // Coming Soon overlay tap
              Positioned(
                top: 20,
                right: 20,
                child: GestureDetector(
                  onTap: () => _showComingSoon('Interactive Global Map'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.border.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.touch_app_rounded,
                          color: AppColors.primary,
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'INTERACTIVE MAP V2',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 9,
                            color: AppColors.primary,
                            letterSpacing: 1,
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
    );
  }

  Widget _buildHotspot(Map<String, dynamic> h) {
    return Positioned.fill(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cx = (h['x'] as double) * constraints.maxWidth;
          final cy = (h['y'] as double) * constraints.maxHeight;
          final r = (h['size'] as double) / 2;
          return Stack(
            children: [
              Positioned(
                left: cx - r,
                top: cy - r,
                child: AnimatedBuilder(
                  animation: _signalController,
                  builder: (context, _) {
                    final phase =
                        (_signalController.value + (h['delay'] as double)) %
                        1.0;
                    final scale =
                        1.0 + 0.6 * math.sin(phase * 2 * math.pi).abs();
                    final opacity = (0.4 + 0.6 * (1 - phase)).clamp(0.2, 1.0);
                    return Transform.scale(
                      scale: scale,
                      child: Opacity(
                        opacity: opacity,
                        child: Container(
                          width: h['size'] as double,
                          height: h['size'] as double,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primary,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.5),
                                blurRadius: (h['size'] as double) * 2,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 8),
        Text(
          label.toUpperCase(),
          style: GoogleFonts.jetBrainsMono(
            fontSize: 9,
            color: AppColors.onSurfaceMuted,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildInsightsFeed() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainer.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.border.withValues(alpha: 0.15),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Movement Insights',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _showComingSoon('All Articles'),
                    child: Text(
                      'VIEW ALL →',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 9,
                        color: AppColors.primary,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Articles
              ..._insights.asMap().entries.map((entry) {
                final i = entry.key;
                final insight = entry.value;
                return Column(
                  children: [
                    _buildInsightArticle(insight),
                    if (i < _insights.length - 1) ...[
                      const SizedBox(height: 16),
                      const RoadLineSeparator(),
                      const SizedBox(height: 16),
                    ],
                  ],
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInsightArticle(Map<String, dynamic> insight) {
    return GestureDetector(
      onTap: () => _showComingSoon(insight['title'] as String),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Color(
                    insight['tagColor'] as int,
                  ).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  insight['tag'] as String,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: Color(insight['tagColor'] as int),
                    letterSpacing: 1,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                insight['readTime'] as String,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 9,
                  color: AppColors.onSurfaceMuted.withValues(alpha: 0.6),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            insight['title'] as String,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurface,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            insight['summary'] as String,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.onSurfaceMuted,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // ── Community Features ────────────────────────────────────────────────────
  Widget _buildCommunitySection(bool isDesktop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          children: [
            AnimatedBuilder(
              animation: _signalController,
              builder: (context, _) => Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(
                        alpha:
                            0.5 *
                            math
                                .sin(_signalController.value * 2 * math.pi)
                                .abs(),
                      ),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'COMMUNITY HUB',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(width: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.border.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Text(
                'COMING IN V2',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 9,
                  color: AppColors.onSurfaceMuted,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Powerful community tools are being built to strengthen the TODA network.',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: AppColors.onSurfaceMuted,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 28),

        // Feature Grid
        GridView.count(
          crossAxisCount: isDesktop ? 3 : 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: isDesktop ? 2.2 : 1.6,
          children: _communityFeatures
              .map((f) => _buildFeatureCard(f))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildFeatureCard(Map<String, dynamic> feature) {
    return GestureDetector(
      onTap: () => _showComingSoon(feature['label'] as String),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainer.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.border.withValues(alpha: 0.12),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(
                      feature['icon'] as IconData,
                      color: AppColors.primary,
                      size: 22,
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        feature['badge'] as String,
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary.withValues(alpha: 0.7),
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      feature['label'] as String,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      feature['desc'] as String,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.onSurfaceMuted.withValues(alpha: 0.7),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Final CTA ─────────────────────────────────────────────────────────────
  Widget _buildFinalCTA(bool isDesktop) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        vertical: isDesktop ? 64 : 48,
        horizontal: isDesktop ? 0 : 8,
      ),
      child: Column(
        children: [
          Text(
            'The Road is Long,\nBut We Never Drive Alone.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: isDesktop ? 36 : 26,
              fontWeight: FontWeight.w800,
              color: AppColors.onSurface,
              letterSpacing: -0.8,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 28),

          const SizedBox(
            width: 120,
            child: RoadLineSeparator(dashWidth: 8, dashSpace: 5),
          ),
          const SizedBox(height: 32),

          SizedBox(
            height: 56,
            child: ElevatedButton.icon(
              onPressed: () => widget.onNavigateToDeclare?.call(),
              icon: const Icon(Icons.add_road_rounded, size: 22),
              label: Text(
                'Begin the Declaration of Unity',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: const Color(0xFF1A0F00),
                padding: const EdgeInsets.symmetric(horizontal: 36),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
                shadowColor: AppColors.primary.withValues(alpha: 0.4),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Coming Soon Dialog ────────────────────────────────────────────────────────
class _ComingSoonDialog extends StatefulWidget {
  final String feature;
  const _ComingSoonDialog({required this.feature});

  @override
  State<_ComingSoonDialog> createState() => _ComingSoonDialogState();
}

class _ComingSoonDialogState extends State<_ComingSoonDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..forward();
    _scale = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: ScaleTransition(
        scale: _scale,
        child: Dialog(
          backgroundColor: Colors.transparent,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 380),
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainer.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icon
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary.withValues(alpha: 0.1),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                      ),
                      child: const Icon(
                        Icons.construction_rounded,
                        color: AppColors.primary,
                        size: 34,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Title
                    Text(
                      'Coming Soon',
                      style: GoogleFonts.inter(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: AppColors.onSurface,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Feature name
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.25),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        widget.feature.toUpperCase(),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Description
                    Text(
                      'This feature is being built for iUnity V2. Stay connected — the road ahead is full of upgrades.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        height: 1.6,
                        color: AppColors.onSurfaceMuted,
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Road line
                    const RoadLineSeparator(dashWidth: 6, dashSpace: 4),
                    const SizedBox(height: 24),

                    // Close button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: const Color(0xFF1A0F00),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Back to Road',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
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
    );
  }
}

// ── Custom Painters ───────────────────────────────────────────────────────────

// Animated background grid
class _GridPainter extends CustomPainter {
  final double progress;
  _GridPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x08F59E0B)
      ..strokeWidth = 1;

    const cols = 12;
    final colW = size.width / cols;
    for (int i = 0; i <= cols; i++) {
      canvas.drawLine(
        Offset(i * colW, 0),
        Offset(i * colW, size.height),
        paint,
      );
    }
    // Radial gradient effect in center
    final gradPaint = Paint()
      ..shader =
          RadialGradient(
            colors: [const Color(0x15F59E0B), Colors.transparent],
          ).createShader(
            Rect.fromCircle(
              center: Offset(size.width / 2, size.height / 2),
              radius: size.width * 0.5,
            ),
          );
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.width * 0.5,
      gradPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

// Simplified world map outlines
class _WorldMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()
      ..color = const Color(0xFF0D1520)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(0),
      ),
      bgPaint,
    );

    final landPaint = Paint()
      ..color = const Color(0xFF1C2A3A)
      ..style = PaintingStyle.fill;

    // Draw simplified continent blobs
    final continents = [
      // North America
      _makeBlob(size, 0.12, 0.25, 0.18, 0.30),
      // South America
      _makeBlob(size, 0.22, 0.55, 0.10, 0.25),
      // Europe
      _makeBlob(size, 0.44, 0.18, 0.08, 0.15),
      // Africa
      _makeBlob(size, 0.46, 0.40, 0.10, 0.30),
      // Asia
      _makeBlob(size, 0.58, 0.15, 0.22, 0.30),
      // Australia
      _makeBlob(size, 0.76, 0.58, 0.10, 0.14),
    ];

    for (final path in continents) {
      canvas.drawPath(path, landPaint);
    }

    // Grid lines (latitude / longitude)
    final gridPaint = Paint()
      ..color = const Color(0x10F59E0B)
      ..strokeWidth = 0.5;
    for (int i = 1; i < 6; i++) {
      canvas.drawLine(
        Offset(0, size.height * i / 6),
        Offset(size.width, size.height * i / 6),
        gridPaint,
      );
    }
    for (int i = 1; i < 10; i++) {
      canvas.drawLine(
        Offset(size.width * i / 10, 0),
        Offset(size.width * i / 10, size.height),
        gridPaint,
      );
    }
  }

  Path _makeBlob(Size size, double cx, double cy, double rw, double rh) {
    final path = Path();
    final x = cx * size.width;
    final y = cy * size.height;
    final hw = rw * size.width * 0.5;
    final hh = rh * size.height * 0.5;
    path.addOval(
      Rect.fromCenter(center: Offset(x, y), width: hw * 2, height: hh * 2),
    );
    return path;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Animated connection lines between hotspots
class _ConnectionLinePainter extends CustomPainter {
  final double progress;
  final List<Map<String, dynamic>> hotspots;

  _ConnectionLinePainter({required this.progress, required this.hotspots});

  @override
  void paint(Canvas canvas, Size size) {
    if (hotspots.length < 2) return;
    final paint = Paint()
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    final positions = hotspots
        .map(
          (h) => Offset(
            (h['x'] as double) * size.width,
            (h['y'] as double) * size.height,
          ),
        )
        .toList();

    // Draw faint connections between nearby nodes
    for (int i = 0; i < positions.length; i++) {
      for (int j = i + 1; j < positions.length; j++) {
        final dist = (positions[i] - positions[j]).distance;
        if (dist < size.width * 0.35) {
          final phase = (progress + i * 0.15 + j * 0.1) % 1.0;
          final opacity = (0.08 + 0.12 * math.sin(phase * math.pi)).clamp(
            0.0,
            0.25,
          );
          paint.color = AppColors.primary.withValues(alpha: opacity);
          canvas.drawLine(positions[i], positions[j], paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ConnectionLinePainter oldDelegate) =>
      oldDelegate.progress != progress;
}
