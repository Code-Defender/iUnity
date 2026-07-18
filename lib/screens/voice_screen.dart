import 'package/material.dart';import 'package/google_fonts.dart';import 'package/cloud_firestore.dart';import '../theme/app_theme.dart';import '../services/auth_service.dart';import '../services/database_service.dart';

class VoiceScreen extends StatefulWidget {const VoiceScreen({super.key});

@overrideState<VoiceScreen> createState() => _VoiceScreenState();}

class _VoiceScreenState extends State<VoiceScreen> {final AuthService _authService = AuthService();final DatabaseService _databaseService = DatabaseService();

String _selectedRegionFilter = "ALL REGIONS";

// Local state to track "joined" voids for trending cardsfinal Set<String> _joinedVoids = {};

// Local state to track locally verified report IDs (to prevent double voting/immediate update feedback)final Set<String> _locallyVerifiedReports = {};final Map<String, int> _localVerificationIncrements = {};

final List<String> _regions = ["ALL REGIONS","NORTHEAST","MIDWEST","WEST COAST","SOUTHWEST","PACIFIC","NATIONAL",];

// Mock trending concerns datafinal List<Map<String, dynamic>> _trendingConcerns = [{"id": "trend_1","tag": "Critical","change": "24h Change: +14%","title": "Fuel Surge: I-80","description": "Localized price fixing identified at Wyoming corridor hubs.","initialNodes": 128,},{"id": "trend_2","tag": "Observation","change": "Active Pattern","title": "Dispatch Ghosting","description": "Tier 2 brokers failing to respond after detention claims.","initialNodes": 84,},{"id": "trend_3","tag": "Rising","change": "Developing","title": "Wait Times: NJ","description": "Port Elizabeth terminal 4 reporting 6hr average turn times.","initialNodes": 42,}];

// Predefined mockup reports to merge with live Firestore database reportsfinal List<Map<String, dynamic>> _mockReports = [{"id": "mock_report_1","region": "SOUTHWEST","severity": "HIGH","reportsCount": 214,"title": "Fuel Pricing Anomaly","description": "Identified 45% markup above market average at three independent stops within 50 miles. Coordinated pattern suspected.",},{"id": "mock_report_2","region": "NATIONAL","severity": "MID","reportsCount": 56,"title": "Dispatch Abuse","description": "Load board ghosting during ETA verification. Brokers canceling without penalty after arrival confirmed by ELD.",},{"id": "mock_report_3","region": "PACIFIC","severity": "LOW","reportsCount": 312,"title": "Terminal Access Delay","description": "Persistent gate failure at LA Basin port terminals causing unpaid detention exceeding safety thresholds.",}];

void _toggleJoinVoid(String id, String title) {setState(() {if (_joinedVoids.contains(id)) {_joinedVoids.remove(id);ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Disconnected from $title Void."),backgroundColor: AppColors.surfaceContainerHigh,duration: const Duration(seconds: 2),),);} else {_joinedVoids.add(id);ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Signal aligned. Joined $title Void."),backgroundColor: AppColors.primaryContainer,duration: const Duration(seconds: 2),),);}});}

void _verifySignal(String reportId, bool isMock, {DocumentReference? docRef}) async {final user = _authService.currentUser;if (user == null) {ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Authentication required to verify signals."),backgroundColor: Colors.redAccent,),);return;}

if (_locallyVerifiedReports.contains(reportId)) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text("You have already backed this signal."),
      backgroundColor: AppColors.surfaceContainerHigh,
    ),
  );
  return;
}

setState(() {
  _locallyVerifiedReports.add(reportId);
  _localVerificationIncrements[reportId] = (_localVerificationIncrements[reportId] ?? 0) + 1;
});

ScaffoldMessenger.of(context).showSnackBar(
  const SnackBar(
    content: Text("Signal backed. Strengthening pattern visibility..."),
    backgroundColor: AppColors.primaryContainer,
    duration: Duration(seconds: 2),
  ),
);

if (!isMock && docRef != null) {
  try {
    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) return;
      
      final data = snapshot.data() as Map<String, dynamic>?;
      List<dynamic> verifiedBy = data?['verifiedBy'] ?? [];
      int currentCount = data?['reportsCount'] ?? 1;

      if (!verifiedBy.contains(user.uid)) {
        verifiedBy.add(user.uid);
        transaction.update(docRef, {
          'verifiedBy': verifiedBy,
          'reportsCount': currentCount + 1,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    }).timeout(const Duration(seconds: 4));
  } catch (e) {
    debugPrint("Error updating verification in Firestore: $e");
    // Revert local state if database fails
    setState(() {
      _locallyVerifiedReports.remove(reportId);
      _localVerificationIncrements[reportId] = (_localVerificationIncrements[reportId] ?? 1) - 1;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Sync failed, verification kept locally. ($e)"),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }
}

}

void _showReportDialog() {showGeneralDialog(context: context,barrierDismissible: true,barrierLabel: "Dismiss",barrierColor: Colors.black.withOpacity(0.7),transitionDuration: const Duration(milliseconds: 300),pageBuilder: (context, anim1, anim2) {return _ReportPatternDialog(onReportSubmitted: () {ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Report broadcasted successfully to the iUnity network!"),backgroundColor: AppColors.primaryContainer,),);},);},transitionBuilder: (context, anim1, anim2, child) {return Transform.scale(scale: anim1.value,child: FadeTransition(opacity: anim1,child: child,),);},);}

Color _getTagBgColor(String tag, ThemeData theme) {switch (tag.toUpperCase()) {case "CRITICAL":case "HIGH":return theme.colorScheme.error.withOpacity(0.15);case "OBSERVATION":case "MID":return AppColors.secondary.withOpacity(0.15);case "RISING":case "DEVELOPING":case "LOW":return AppColors.primary.withOpacity(0.15);default:return AppColors.border.withOpacity(0.15);}}

Color _getTagTextColor(String tag, ThemeData theme) {switch (tag.toUpperCase()) {case "CRITICAL":case "HIGH":return theme.colorScheme.error;case "OBSERVATION":case "MID":return AppColors.secondary;case "RISING":case "DEVELOPING":case "LOW":return AppColors.primary;default:return AppColors.onSurfaceMuted;}}

@overrideWidget build(BuildContext context) {final theme = Theme.of(context);final size = MediaQuery.of(context).size;final isDesktop = size.width > 768;

return Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    // Hero / Mission Section
    _buildHeroSection(theme, isDesktop),
    const SizedBox(height: 60),

    // Trending Concerns (Horizontal Scroll)
    _buildTrendingSection(theme, isDesktop),
    const SizedBox(height: 60),

    // Live Intelligence Stream Header & Grid
    _buildLiveStreamSection(theme, isDesktop),
    const SizedBox(height: 40),
  ],
);

}

Widget _buildHeroSection(ThemeData theme, bool isDesktop) {return Container(width: double.infinity,padding: EdgeInsets.symmetric(vertical: isDesktop ? 20 : 10),child: isDesktop? Row(crossAxisAlignment: CrossAxisAlignment.end,mainAxisAlignment: MainAxisAlignment.spaceBetween,children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,children: [Text("Voice of the Road",style: theme.textTheme.headlineLarge?.copyWith(fontSize: 40,fontWeight: FontWeight.w700,letterSpacing: -1.0,),),const SizedBox(height: 16),Text("Collective intelligence monitoring patterns of injustice. Every report strengthens the network and exposes systemic friction.",style: theme.textTheme.bodyMedium?.copyWith(fontSize: 18,height: 1.6,color: AppColors.onSurfaceMuted,),),],),),const SizedBox(width: 40),Row(children: [ElevatedButton(onPressed: _showReportDialog,child: Text("REPORT PATTERN",style: GoogleFonts.jetBrainsMono(fontSize: 12,fontWeight: FontWeight.w700,letterSpacing: 1.0,),),),const SizedBox(width: 16),OutlinedButton(onPressed: () {ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Every shared voice adds nodes to our real-time truth map."),backgroundColor: AppColors.surfaceContainerHigh,),);},style: OutlinedButton.styleFrom(foregroundColor: AppColors.onSurface,side: const BorderSide(color: AppColors.border, width: 1.5),padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8),),),child: Text("SHARE ISSUE",style: GoogleFonts.jetBrainsMono(fontSize: 12,fontWeight: FontWeight.w700,letterSpacing: 1.0,),),),],),],): Column(crossAxisAlignment: CrossAxisAlignment.start,children: [Text("Voice of the Road",style: theme.textTheme.headlineLarge?.copyWith(fontSize: 32,fontWeight: FontWeight.w700,letterSpacing: -0.8,),),const SizedBox(height: 12),Text("Collective intelligence monitoring patterns of injustice. Every report strengthens the network and exposes systemic friction.",style: theme.textTheme.bodyMedium?.copyWith(fontSize: 15,height: 1.5,color: AppColors.onSurfaceMuted,),),const SizedBox(height: 24),Row(children: [Expanded(child: ElevatedButton(onPressed: _showReportDialog,child: Text("REPORT PATTERN",style: GoogleFonts.jetBrainsMono(fontSize: 11,fontWeight: FontWeight.w700,letterSpacing: 1.0,),),),),const SizedBox(width: 12),Expanded(child: OutlinedButton(onPressed: () {ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Every shared voice adds nodes to our real-time truth map."),backgroundColor: AppColors.surfaceContainerHigh,),);},style: OutlinedButton.styleFrom(foregroundColor: AppColors.onSurface,side: const BorderSide(color: AppColors.border, width: 1.5),padding: const EdgeInsets.symmetric(vertical: 16),shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8),),),child: Text("SHARE ISSUE",style: GoogleFonts.jetBrainsMono(fontSize: 11,fontWeight: FontWeight.w700,letterSpacing: 1.0,),),),),],),],),);}

Widget _buildTrendingSection(ThemeData theme, bool isDesktop) {return Column(crossAxisAlignment: CrossAxisAlignment.start,children: [Row(children: [const UnitySignal(size: 8),const SizedBox(width: 8),Text("TRENDING CONCERNS",style: theme.textTheme.labelLarge?.copyWith(color: AppColors.primary,fontWeight: FontWeight.w700,letterSpacing: 2.0,),),],),const SizedBox(height: 16),SizedBox(height: 190,child: ListView.builder(scrollDirection: Axis.horizontal,physics: const BouncingScrollPhysics(),itemCount: _trendingConcerns.length,itemBuilder: (context, index) {final item = _trendingConcerns[index];final id = item["id"] as String;final isJoined = _joinedVoids.contains(id);final activeNodesCount = item["initialNodes"] + (isJoined ? 1 : 0);

          return Padding(
            padding: const EdgeInsets.only(right: 20.0),
            child: Container(
              width: 320,
              child: GlassCard(
                padding: const EdgeInsets.all(20),
                borderRadius: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getTagBgColor(item["tag"], theme),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            (item["tag"] as String).toUpperCase(),
                            style: GoogleFonts.jetBrainsMono(
                              color: _getTagTextColor(item["tag"], theme),
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Text(
                          item["change"] as String,
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontSize: 10,
                            color: AppColors.onSurfaceMuted.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item["title"] as String,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item["description"] as String,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 13,
                        color: AppColors.onSurfaceMuted.withOpacity(0.8),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.hub_rounded, size: 14, color: AppColors.primary),
                            const SizedBox(width: 6),
                            Text(
                              "$activeNodesCount+ Nodes",
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 10,
                                color: AppColors.onSurfaceMuted,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        TextButton(
                          onPressed: () => _toggleJoinVoid(id, item["title"]),
                          style: TextButton.styleFrom(
                            foregroundColor: isJoined ? AppColors.primary : AppColors.onSurface,
                            padding: EdgeInsets.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                isJoined ? "SIGNAL ALIGNED" : "JOIN VOID",
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.0,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                isJoined ? Icons.check : Icons.arrow_forward_rounded,
                                size: 12,
                              ),
                            ],
                          ),
                        ),
                      ],
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

}

Widget _buildLiveStreamSection(ThemeData theme, bool isDesktop) {final controls = Row(mainAxisSize: MainAxisSize.min,children: [DropdownButtonHideUnderline(child: Container(height: 36,padding: const EdgeInsets.symmetric(horizontal: 12),decoration: BoxDecoration(color: AppColors.surfaceContainerLow,borderRadius: BorderRadius.circular(8),border: Border.all(color: AppColors.border, width: 0.5),),child: DropdownButton<String>(dropdownColor: AppColors.surfaceContainer,value: _selectedRegionFilter,icon: const Icon(Icons.arrow_drop_down, color: AppColors.primary, size: 18),onChanged: (String? newValue) {if (newValue != null) {setState(() {_selectedRegionFilter = newValue;});}},items: _regions.map<DropdownMenuItem<String>>((String value) {return DropdownMenuItem<String>(value: value,child: Text(value,style: GoogleFonts.jetBrainsMono(fontSize: 10,fontWeight: FontWeight.w700,color: AppColors.onSurface,),),);}).toList(),),),),const SizedBox(width: 8),IconButton(icon: const Icon(Icons.filter_list, color: AppColors.onSurfaceMuted, size: 20),onPressed: () {setState(() {_selectedRegionFilter = "ALL REGIONS";});},tooltip: "Reset Region Filter",),],);

return Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    // Live stream header
    if (isDesktop)
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "Live Intelligence Stream",
            style: theme.textTheme.headlineMedium?.copyWith(
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          controls,
        ],
      )
    else
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Live Intelligence Stream",
            style: theme.textTheme.headlineMedium?.copyWith(
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          controls,
        ],
      ),
    const SizedBox(height: 24),

    // Live stream stream builder merged with mockup cards
    StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _databaseService.getCollectionStream(
        collectionPath: 'reports',
        queryBuilder: (query) => query.orderBy('createdAt', descending: true),
      ),
      builder: (context, snapshot) {
        List<Map<String, dynamic>> firestoreReports = [];
        List<DocumentReference> firestoreDocRefs = [];
        List<String> firestoreIds = [];

        if (snapshot.hasData) {
          for (var doc in snapshot.data!.docs) {
            final data = doc.data();
            data['id'] = doc.id;
            firestoreReports.add(data);
            firestoreDocRefs.add(doc.reference);
            firestoreIds.add(doc.id);
          }
        }

        // Combine Firestore reports + Preset mockup reports
        List<Map<String, dynamic>> allReports = [];
        List<DocumentReference?> docRefs = [];
        List<bool> isMocks = [];

        // Add Firestore ones first (newest)
        for (int i = 0; i < firestoreReports.length; i++) {
          allReports.add(firestoreReports[i]);
          docRefs.add(firestoreDocRefs[i]);
          isMocks.add(false);
        }

        // Add Preset Mockup reports
        for (int i = 0; i < _mockReports.length; i++) {
          allReports.add(_mockReports[i]);
          docRefs.add(null);
          isMocks.add(true);
        }

        // Apply region filter
        List<int> filteredIndices = [];
        for (int i = 0; i < allReports.length; i++) {
          final report = allReports[i];
          final region = (report['region'] as String).toUpperCase();
          
          if (_selectedRegionFilter == "ALL REGIONS" || region == _selectedRegionFilter) {
            filteredIndices.add(i);
          }
        }

        // Render responsive layout
        if (isDesktop) {
          return _buildDesktopGrid(context, theme, allReports, docRefs, isMocks, filteredIndices);
        } else {
          return _buildMobileStack(context, theme, allReports, docRefs, isMocks, filteredIndices);
        }
      },
    ),
  ],
);

}

Widget _buildDesktopGrid(BuildContext context,ThemeData theme,List<Map<String, dynamic>> allReports,List<DocumentReference?> docRefs,List<bool> isMocks,List<int> filteredIndices,) {// Collect list of widgets to display in gridList<Widget> streamCards = [];for (int idx in filteredIndices) {streamCards.add(_buildVoiceCard(context,theme,allReports[idx],docRefs[idx],isMocks[idx],expandDescription: true,),);}

// Bento elements
final bentoCard = _buildBentoInsightCard(theme);
final statsCard = _buildStatsCard(theme);

return Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    // 3-column layout for dynamic cards
    if (streamCards.isNotEmpty) ...[
      GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 20,
          mainAxisSpacing: 20,
          childAspectRatio: 1.15,
        ),
        itemCount: streamCards.length,
        itemBuilder: (context, index) => streamCards[index],
      ),
      const SizedBox(height: 20),
    ] else ...[
      Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40.0),
          child: Text(
            "No reports found in this region. Broadcast the first one!",
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.onSurfaceMuted.withOpacity(0.5),
            ),
          ),
        ),
      ),
    ],

    // 2-column Bento row below the grid (Bento card spans 2 flex columns, Stats spans 1)
    Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: bentoCard,
        ),
        const SizedBox(width: 20),
        Expanded(
          flex: 1,
          child: statsCard,
        ),
      ],
    ),
  ],
);

}

Widget _buildMobileStack(BuildContext context,ThemeData theme,List<Map<String, dynamic>> allReports,List<DocumentReference?> docRefs,List<bool> isMocks,List<int> filteredIndices,) {List<Widget> children = [];

for (int idx in filteredIndices) {
  children.add(
    Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: _buildVoiceCard(
        context,
        theme,
        allReports[idx],
        docRefs[idx],
        isMocks[idx],
        expandDescription: false,
      ),
    ),
  );
}

if (children.isEmpty) {
  children.add(
    Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20.0),
        child: Text(
          "No reports found in this region.",
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.onSurfaceMuted.withOpacity(0.5),
          ),
        ),
      ),
    ),
  );
}

children.add(
  Padding(
    padding: const EdgeInsets.only(bottom: 20.0),
    child: _buildBentoInsightCard(theme),
  ),
);

children.add(
  _buildStatsCard(theme),
);

return Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: children,
);

}

Widget _buildVoiceCard(BuildContext context,ThemeData theme,Map<String, dynamic> report,DocumentReference? docRef,bool isMock, {required bool expandDescription,}) {final String reportId = report['id'] ?? '';final String region = report['region'] ?? 'NATIONAL';final String severity = report['severity'] ?? 'MID';final String title = report['title'] ?? 'Pattern Report';final String description = report['description'] ?? '';

// Calculate display reports count (merge initial count with local verification additions)
int baseCount = 1;
if (report['reportsCount'] != null) {
  if (report['reportsCount'] is int) {
    baseCount = report['reportsCount'];
  } else {
    baseCount = int.tryParse(report['reportsCount'].toString()) ?? 1;
  }
}
final int localIncrement = _localVerificationIncrements[reportId] ?? 0;
final int displayCount = baseCount + localIncrement;
final bool isVerified = _locallyVerifiedReports.contains(reportId);
final descriptionText = Text(
  description,
  style: theme.textTheme.bodyMedium?.copyWith(
    fontSize: 13,
    height: 1.45,
    color: AppColors.onSurfaceMuted,
  ),
);

// Dynamic left border based on severity
Color borderSeverityColor = AppColors.border;
IconData severityIcon = Icons.info_outline;

switch (severity.toUpperCase()) {
  case "CRITICAL":
  case "HIGH":
    borderSeverityColor = theme.colorScheme.error;
    severityIcon = Icons.warning_rounded;
    break;
  case "OBSERVATION":
  case "MID":
    borderSeverityColor = AppColors.primary;
    severityIcon = Icons.info_rounded;
    break;
  case "RISING":
  case "DEVELOPING":
  case "LOW":
    borderSeverityColor = AppColors.tertiary;
    severityIcon = Icons.visibility_rounded;
    break;
}

return MouseRegion(
  cursor: SystemMouseCursors.click,
  child: Container(
    decoration: BoxDecoration(
      border: Border(
        left: BorderSide(color: borderSeverityColor, width: 4.0),
      ),
      borderRadius: const BorderRadius.only(
        topRight: Radius.circular(16),
        bottomRight: Radius.circular(16),
      ),
    ),
    child: GlassCard(
      padding: const EdgeInsets.all(24),
      borderRadius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "REGION: ${region.toUpperCase()}",
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurfaceMuted.withOpacity(0.7),
                ),
              ),
              Icon(
                severityIcon,
                color: borderSeverityColor,
                size: 18,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          if (expandDescription)
            Expanded(child: descriptionText)
          else
            descriptionText,
          const SizedBox(height: 16),
          Container(
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: AppColors.border, width: 0.5),
              ),
            ),
            padding: const EdgeInsets.only(top: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "REPORTS",
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: AppColors.onSurfaceMuted.withOpacity(0.6),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "$displayCount",
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 20),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "SEVERITY",
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: AppColors.onSurfaceMuted.withOpacity(0.6),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          severity.toUpperCase(),
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: borderSeverityColor,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  icon: Icon(
                    isVerified ? Icons.verified_user : Icons.add_moderator,
                    color: isVerified ? AppColors.primary : AppColors.onSurfaceMuted,
                  ),
                  onPressed: () => _verifySignal(reportId, isMock, docRef: docRef),
                  tooltip: "Verify & Back Signal",
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  ),
);

}

Widget _buildBentoInsightCard(ThemeData theme) {return Container(constraints: const BoxConstraints(minHeight: 320),child: Stack(children: [// Gradient Background styling (Bento Look)Positioned.fill(child: ClipRRect(borderRadius: BorderRadius.circular(16),child: Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft,end: Alignment.bottomRight,colors: [AppColors.surfaceContainerHigh,AppColors.surfaceContainer,AppColors.primary.withOpacity(0.04),],),),),),),GlassCard(borderRadius: 16,child: Column(crossAxisAlignment: CrossAxisAlignment.start,mainAxisAlignment: MainAxisAlignment.end,children: [Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.12),borderRadius: BorderRadius.circular(20),border: Border.all(color: AppColors.primary.withOpacity(0.3)),),child: Text("SYSTEMIC INSIGHT",style: GoogleFonts.jetBrainsMono(color: AppColors.primary,fontWeight: FontWeight.w700,fontSize: 9,letterSpacing: 1.0,),),),const SizedBox(height: 20),Text("Dispatch Pattern Correlated with Port Congestion",style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700,fontSize: 22,letterSpacing: -0.5,),),const SizedBox(height: 12),Text("Our collective intelligence has linked the rise in dispatch ghosting specifically to terminals with current turn-times exceeding 5 hours. Brokers are preemptively dropping loads to avoid detention payouts.",style: theme.textTheme.bodyMedium?.copyWith(fontSize: 14,height: 1.6,color: AppColors.onSurfaceMuted,),),const SizedBox(height: 28),Row(children: [InkWell(onTap: () {ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Findings copied to secure clipboard."),backgroundColor: AppColors.primaryContainer,),);},child: Row(children: [const Icon(Icons.share, color: AppColors.primary, size: 16),const SizedBox(width: 8),Text("Share Findings",style: GoogleFonts.jetBrainsMono(fontSize: 11,fontWeight: FontWeight.w700,color: AppColors.onSurface,),),],),),const SizedBox(width: 32),InkWell(onTap: () {ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Drafting Collective Arbitration petition..."),backgroundColor: AppColors.primaryContainer,),);},child: Row(children: [const Icon(Icons.gavel, color: AppColors.primary, size: 16),const SizedBox(width: 8),Text("Collective Action",style: GoogleFonts.jetBrainsMono(fontSize: 11,fontWeight: FontWeight.w700,color: AppColors.onSurface,),),],),),],),],),),],),);}

Widget _buildStatsCard(ThemeData theme) {return Container(constraints: const BoxConstraints(minHeight: 320),child: GlassCard(borderRadius: 16,padding: const EdgeInsets.all(28),child: Column(mainAxisAlignment: MainAxisAlignment.center,crossAxisAlignment: CrossAxisAlignment.center,children: [const Icon(Icons.hub_rounded,size: 48,color: AppColors.primary,),const SizedBox(height: 20),Text("NETWORK NODES",style: GoogleFonts.jetBrainsMono(fontSize: 11,color: AppColors.onSurfaceMuted.withOpacity(0.7),letterSpacing: 2.0,fontWeight: FontWeight.w700,),),const SizedBox(height: 8),Text("12,482",style: theme.textTheme.headlineLarge?.copyWith(fontSize: 36,fontWeight: FontWeight.w800,color: AppColors.primary,),),const SizedBox(height: 20),Text("Drivers contributing to the real-time truth graph across North America.",textAlign: TextAlign.center,style: theme.textTheme.bodyMedium?.copyWith(fontSize: 13,height: 1.5,color: AppColors.onSurfaceMuted,),),],),),);}}

// Dialog form for creating a new report patternclass _ReportPatternDialog extends StatefulWidget {final VoidCallback onReportSubmitted;

const _ReportPatternDialog({required this.onReportSubmitted});

@overrideState<_ReportPatternDialog> createState() => _ReportPatternDialogState();}

class _ReportPatternDialogState extends State<_ReportPatternDialog> {final _formKey = GlobalKey<FormState>();final AuthService _authService = AuthService();final DatabaseService _databaseService = DatabaseService();

final TextEditingController _titleController = TextEditingController();final TextEditingController _descriptionController = TextEditingController();

String _category = "Fuel Pricing";String _region = "Southwest";String _severity = "High";bool _submitting = false;

final List<String> _categories = ["Fuel Pricing","Dispatch Abuse","Terminal Delay","Safety Issue","Other"];

final List<String> _regions = ["Southwest","Northeast","Midwest","West Coast","Pacific","National"];

final List<String> _severities = ["Low","Mid","High","Critical"];

@overridevoid dispose() {_titleController.dispose();_descriptionController.dispose();super.dispose();}

void _submit() async {if (!_formKey.currentState!.validate()) return;

final user = _authService.currentUser;
if (user == null) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text("You must be authenticated to report patterns."),
      backgroundColor: Colors.redAccent,
    ),
  );
  Navigator.of(context).pop();
  return;
}

setState(() {
  _submitting = true;
});

try {
  final reportData = {
    'title': _titleController.text.trim(),
    'description': _descriptionController.text.trim(),
    'category': _category,
    'region': _region.toUpperCase(),
    'severity': _severity.toUpperCase(),
    'reportsCount': 1,
    'verifiedBy': [user.uid],
    'userId': user.uid,
  };

  await _databaseService.addDocument(
    collectionPath: 'reports',
    data: reportData,
  ).timeout(const Duration(seconds: 5));

  if (mounted) {
    widget.onReportSubmitted();
    Navigator.of(context).pop();
  }
} catch (e) {
  debugPrint("Error creating report: $e");
  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Submission failed: $e"),
        backgroundColor: Colors.redAccent,
      ),
    );
  }
} finally {
  if (mounted) {
    setState(() {
      _submitting = false;
    });
  }
}

}

@overrideWidget build(BuildContext context) {final isDesktop = MediaQuery.of(context).size.width > 768;

return Center(
  child: SingleChildScrollView(
    child: Material(
      color: Colors.transparent,
      child: Container(
        width: isDesktop ? 600 : double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        child: GlassCard(
          borderRadius: 20,
          padding: const EdgeInsets.all(28),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "REPORT SYSTEMIC PATTERN",
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                        letterSpacing: 1.5,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.onSurfaceMuted),
                      onPressed: () => Navigator.of(context).pop(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const RoadLineSeparator(color: AppColors.border),
                const SizedBox(height: 24),

                // Title Field
                Text(
                  "PATTERN SUMMARY / TITLE",
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurfaceMuted.withOpacity(0.8),
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _titleController,
                  style: GoogleFonts.inter(color: AppColors.onSurface, fontSize: 14),
                  decoration: const InputDecoration(
                    hintText: "e.g., Detention fee evasion at Terminal 3",
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "Summary is required.";
                    }
                    if (value.trim().length < 5) {
                      return "Summary must be at least 5 characters.";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Row of drop downs
                Row(
                  children: [
                    // Category Dropdown
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "CATEGORY",
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.onSurfaceMuted.withOpacity(0.8),
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildDropdownField(
                            value: _category,
                            items: _categories,
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _category = value;
                                });
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    
                    // Region Dropdown
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "REGION",
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.onSurfaceMuted.withOpacity(0.8),
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildDropdownField(
                            value: _region,
                            items: _regions,
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _region = value;
                                });
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Severity Dropdown
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "SEVERITY",
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurfaceMuted.withOpacity(0.8),
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildDropdownField(
                      value: _severity,
                      items: _severities,
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _severity = value;
                          });
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Description Field
                Text(
                  "DETAILED PATTERN DESCRIPTION",
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurfaceMuted.withOpacity(0.8),
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _descriptionController,
                  style: GoogleFonts.inter(color: AppColors.onSurface, fontSize: 14),
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: "Describe the pattern of systemic friction you have observed. Include locations, entities involved, and estimated impact. Ensure no sensitive personal identifers are broadcasted.",
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "Description is required.";
                    }
                    if (value.trim().length < 20) {
                      return "Please provide more detail (at least 20 characters).";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 28),

                // Submit & Cancel buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: _submitting ? null : () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.onSurface,
                        side: const BorderSide(color: AppColors.border),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        "CANCEL",
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: _submitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _submitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(AppColors.onPrimary),
                              ),
                            )
                          : Row(
                              children: [
                                const Icon(Icons.wifi_tethering, size: 16),
                                const SizedBox(width: 8),
                                Text(
                                  "BROADCAST SIGNAL",
                                  style: GoogleFonts.jetBrainsMono(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  ),
);