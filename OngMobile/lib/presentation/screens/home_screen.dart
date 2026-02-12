import 'package:flutter/material.dart';
import '../../data/services/api_service.dart';
import '../../data/models/case_model.dart';
import '../widgets/wecare_case_card.dart';
import '../widgets/charify_widgets.dart';
import 'browse_screen.dart';
import 'case_details_screen.dart';
import 'notifications_screen.dart';
import '../../core/theme/charify_theme.dart';
import '../../data/models/notification_model.dart';

import 'package:ong_mobile_app/l10n/app_localizations.dart';

class HomeScreen extends StatefulWidget {
  final Function(Locale)? onLanguageChange;
  final Locale? currentLocale;

  const HomeScreen({super.key, this.onLanguageChange, this.currentLocale});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();
  Future<List<CaseModel>>? _casesFuture;
  Future<List<NotificationModel>>? _notificationsFuture;
  String? _selectedCategory;
  int _currentPage = 0;
  final int _itemsPerPage = 9;

  @override
  void initState() {
    super.initState();
    // Default load all cases
    _loadCases();
    _notificationsFuture = _apiService.getNotifications();
  }

  void _loadCases() {
    if (!mounted) return;
    // Map localized 'All' category back to 'Tous' or null for API if needed,
    // BUT since the API likely expects specific English or French strings, we need to handle mapping.
    // Assuming API takes French/Back-end values.
    // For now, let's keep the filter logic simple. If _selectedCategory matches the localized "All", send null/Tous.

    // Actually, storing the *localized* string in _selectedCategory is problematic if the language changes.
    // Ideally, we should store a distinct key (e.g., 'HEALTH') and map it to display text.
    // However, to minimize refactor risk right now, I will use the localized strings but reset if needed.
    // Or better: Let's assume the API expects the *French* terms (Santé, Éducation etc) as per original code.
    // So we need a map.

    setState(() {
      _casesFuture = _apiService.getCases(
        category: _selectedCategory == 'Tous' || _selectedCategory == null
            ? null
            : _selectedCategory,
      );
      _currentPage = 0;
    });
  }

  // Helper to map UI category to API category
  // Since the original code used the display string as the value, I will try to maintain that
  // but we need to be careful. The original code had: _selectedCategory == 'Tous' ? null : _selectedCategory

  // NOTE: The previous code laid out '_categories' as raw strings.
  // I will change the logic to rely on the index or a fixed key to avoid breakage when switching languages.

  // Let's use a mapping for safety.
  Map<String, String> _getCategoryMap(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return {
      loc.categoryAll: 'Tous',
      loc.categoryHealth: 'Santé',
      loc.categoryEducation: 'Éducation',
      loc.categoryFood: 'Alimentation',
      loc.categoryHousing: 'Logement',
    };
  }

  Future<void> _refresh() async {
    _loadCases();
    setState(() {
      _notificationsFuture = _apiService.getNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final categoryMap = _getCategoryMap(context);
    final categories = categoryMap.keys.toList();

    return Scaffold(
      backgroundColor: CharifyTheme.backgroundGrey,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          color: CharifyTheme.primaryGreen,
          child: CustomScrollView(
            slivers: [
              // Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(CharifyTheme.space16),
                  child: Row(
                    children: [
                      // Logo/Brand
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: CharifyTheme.primaryGreen,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.volunteer_activism_rounded,
                          color: CharifyTheme.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        loc.appTitle,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: CharifyTheme.darkGrey,
                            ),
                      ),
                      const Spacer(),
                      // Search icon
                      IconButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const BrowseScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.search_rounded),
                        color: CharifyTheme.darkGrey,
                      ),
                      // Notification icon
                      FutureBuilder<List<NotificationModel>>(
                        future: _notificationsFuture,
                        builder: (context, snapshot) {
                          final hasUnread =
                              snapshot.hasData &&
                              snapshot.data!.any((n) => !n.isRead);

                          return Stack(
                            children: [
                              IconButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const NotificationsScreen(),
                                    ),
                                  ).then((_) {
                                    // Refresh notifications when coming back
                                    setState(() {
                                      _notificationsFuture = _apiService
                                          .getNotifications();
                                    });
                                  });
                                },
                                icon: const Icon(Icons.notifications_outlined),
                                color: CharifyTheme.darkGrey,
                              ),
                              if (hasUnread)
                                Positioned(
                                  right: 12,
                                  top: 12,
                                  child: Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: CharifyTheme.dangerRed,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // Featured/Urgent Case (Hero Card)
              FutureBuilder<List<CaseModel>>(
                future: _casesFuture,
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                    final urgentCase = snapshot.data!.firstWhere(
                      (c) => c.status == 'Urgent',
                      orElse: () => snapshot.data!.first,
                    );

                    return SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: CharifyTheme.space16,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  loc.urgentCases, // Localized
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                TextButton(
                                  onPressed: () {},
                                  child: Text(loc.seeAll),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _buildHeroCard(urgentCase, loc),
                          ],
                        ),
                      ),
                    );
                  }
                  return const SliverToBoxAdapter(child: SizedBox.shrink());
                },
              ),

              // Category Filters
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: CharifyTheme.space16,
                    vertical: CharifyTheme.space20,
                  ),
                  child: SizedBox(
                    height: 36,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: categories.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final categoryDisplay = categories[index];
                        final categoryApiValue = categoryMap[categoryDisplay];

                        // Check logic: if _selectedCategory match the API value
                        final isSelected =
                            _selectedCategory == categoryApiValue ||
                            (_selectedCategory == null &&
                                categoryApiValue == 'Tous');

                        return _buildCategoryChip(
                          categoryDisplay,
                          categoryApiValue,
                          isSelected,
                        );
                      },
                    ),
                  ),
                ),
              ),

              // Cases Grid
              FutureBuilder<List<CaseModel>>(
                future: _casesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      (_casesFuture != null)) {
                    return const SliverToBoxAdapter(
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.all(40),
                          child: CircularProgressIndicator(
                            color: CharifyTheme.primaryGreen,
                          ),
                        ),
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return SliverToBoxAdapter(
                      child: CharifyEmptyState(
                        icon: Icons.error_outline_rounded,
                        title: loc.error,
                        subtitle: loc.errorLoadingCases,
                        actionLabel: loc.retry,
                        onActionPressed: _loadCases,
                      ),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return SliverToBoxAdapter(
                      child: CharifyEmptyState(
                        icon: Icons.inbox_outlined,
                        title: loc.noCases,
                        subtitle: loc.noCasesSubtitle,
                      ),
                    );
                  }

                  final cases = snapshot.data!;

                  // Pagination logic
                  final startIndex = _currentPage * _itemsPerPage;
                  final endIndex = (startIndex + _itemsPerPage).clamp(
                    0,
                    cases.length,
                  );
                  final paginatedCases = cases.sublist(
                    startIndex.clamp(0, cases.length),
                    endIndex,
                  );

                  return SliverPadding(
                    padding: const EdgeInsets.only(
                      left: CharifyTheme.space20,
                      right: CharifyTheme.space20,
                      top: CharifyTheme.space8,
                      bottom: CharifyTheme.space16,
                    ),
                    sliver: SliverGrid(
                      gridDelegate:
                          // Using MaxCrossAxisExtent for responsiveness
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 220,
                            childAspectRatio: 0.65,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                          ),
                      delegate: SliverChildBuilderDelegate((context, index) {
                        return WecareCaseCard(
                          socialCase: paginatedCases[index],
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CaseDetailsScreen(
                                  caseId: paginatedCases[index].id,
                                ),
                              ),
                            );
                          },
                          isGridView: true,
                        );
                      }, childCount: paginatedCases.length),
                    ),
                  );
                },
              ),

              // Pagination Controls
              FutureBuilder<List<CaseModel>>(
                future: _casesFuture,
                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const SliverToBoxAdapter(child: SizedBox.shrink());
                  }

                  final cases = snapshot.data!;
                  final totalPages = (cases.length / _itemsPerPage).ceil();

                  if (totalPages <= 1) {
                    return const SliverToBoxAdapter(child: SizedBox.shrink());
                  }

                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: CharifyTheme.space20,
                        vertical: CharifyTheme.space24,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Previous button
                          IconButton(
                            onPressed: _currentPage > 0
                                ? () {
                                    if (!mounted) return;
                                    setState(() {
                                      _currentPage--;
                                    });
                                  }
                                : null,
                            icon: const Icon(Icons.arrow_back_ios_rounded),
                            color: _currentPage > 0
                                ? CharifyTheme.primaryGreen
                                : CharifyTheme.mediumGrey,
                          ),
                          const SizedBox(width: 16),

                          // Page indicators
                          ...List.generate(totalPages, (pageIndex) {
                            return GestureDetector(
                              onTap: () {
                                if (!mounted) return;
                                setState(() {
                                  _currentPage = pageIndex;
                                });
                              },
                              child: Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                width: pageIndex == _currentPage ? 32 : 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: pageIndex == _currentPage
                                      ? CharifyTheme.primaryGreen
                                      : CharifyTheme.lightGrey,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            );
                          }),

                          const SizedBox(width: 16),

                          // Next button
                          IconButton(
                            onPressed: _currentPage < totalPages - 1
                                ? () {
                                    if (!mounted) return;
                                    setState(() {
                                      _currentPage++;
                                    });
                                  }
                                : null,
                            icon: const Icon(Icons.arrow_forward_ios_rounded),
                            color: _currentPage < totalPages - 1
                                ? CharifyTheme.primaryGreen
                                : CharifyTheme.mediumGrey,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              // Bottom spacing
              const SliverToBoxAdapter(
                child: SizedBox(height: CharifyTheme.space32),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroCard(CaseModel socialCase, AppLocalizations loc) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CaseDetailsScreen(caseId: socialCase.id),
          ),
        );
      },
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(CharifyTheme.radiusLarge),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(CharifyTheme.radiusLarge),
          child: Stack(
            fit: StackFit.expand,
            children: [
              CharifyNetworkImage(
                imageUrl: socialCase.mainImageUrl,
                fit: BoxFit.cover,
                borderRadius: BorderRadius.circular(CharifyTheme.radiusLarge),
              ),

              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.8),
                    ],
                    stops: const [0.3, 1.0],
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(CharifyTheme.space16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: CharifyTheme.dangerRed,
                        borderRadius: BorderRadius.circular(
                          CharifyTheme.radiusRound,
                        ),
                      ),
                      child: Text(
                        loc.urgent,
                        style: const TextStyle(
                          color: CharifyTheme.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    Text(
                      socialCase.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: CharifyTheme.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChip(
    String categoryLabel,
    String? apiValue,
    bool isSelected,
  ) {
    return GestureDetector(
      onTap: () {
        if (!mounted) return;
        setState(() {
          _selectedCategory = apiValue == 'Tous' ? null : apiValue;
          _loadCases();
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? CharifyTheme.primaryGreen : CharifyTheme.white,
          borderRadius: BorderRadius.circular(CharifyTheme.radiusRound),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: CharifyTheme.primaryGreen.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
          border: Border.all(
            color: isSelected
                ? CharifyTheme.primaryGreen
                : CharifyTheme.lightGrey,
          ),
        ),
        child: Text(
          categoryLabel,
          style: TextStyle(
            color: isSelected ? CharifyTheme.white : CharifyTheme.darkGrey,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
