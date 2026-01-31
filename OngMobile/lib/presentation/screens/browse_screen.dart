import 'package:flutter/material.dart';
import '../../data/services/api_service.dart';
import '../../data/models/case_model.dart';
import '../widgets/wecare_case_card.dart';
import '../widgets/charify_widgets.dart';
import 'case_details_screen.dart';
import '../../core/theme/charify_theme.dart';
import 'package:ong_mobile_app/l10n/app_localizations.dart';

class BrowseScreen extends StatefulWidget {
  const BrowseScreen({super.key});

  @override
  State<BrowseScreen> createState() => _BrowseScreenState();
}

class _BrowseScreenState extends State<BrowseScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();

  late Future<List<CaseModel>> _casesFuture;
  String? _selectedCategory;
  String _searchQuery = '';

  // API/DB values (assuming these are what the backend expects)
  final List<String> _categories = [
    'Tous',
    'Santé',
    'Éducation',
    'Alimentation',
    'Logement',
    'Eau',
  ];

  @override
  void initState() {
    super.initState();
    _loadCases();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadCases() {
    setState(() {
      _casesFuture = _apiService.getCases(
        category: _selectedCategory == 'Tous' ? null : _selectedCategory,
      );
    });
  }

  List<CaseModel> _filterCases(List<CaseModel> cases) {
    if (_searchQuery.isEmpty) return cases;

    return cases.where((c) {
      final query = _searchQuery.toLowerCase();
      return c.title.toLowerCase().contains(query) ||
          (c.description?.toLowerCase().contains(query) ?? false) ||
          (c.category?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  String _getCategoryDisplay(String category, AppLocalizations loc) {
    switch (category) {
      case 'Tous':
        return loc.all;
      case 'Santé':
        return loc.health;
      case 'Éducation':
        return loc.education;
      case 'Alimentation':
        return loc.food;
      case 'Logement':
        return loc.housing;
      case 'Eau':
        return loc.water;
      default:
        return category;
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: CharifyTheme.backgroundGrey,
      body: SafeArea(
        child: Column(
          children: [
            // Header with search
            Padding(
              padding: const EdgeInsets.all(CharifyTheme.space16),
              child: Column(
                children: [
                  // Search bar
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: loc.searchCases,
                      prefixIcon: const Icon(
                        Icons.search,
                        color: CharifyTheme.mediumGrey,
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                setState(() {
                                  _searchController.clear();
                                  _searchQuery = '';
                                });
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: CharifyTheme.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          CharifyTheme.radiusMedium,
                        ),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: CharifyTheme.space16,
                        vertical: CharifyTheme.space12,
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                  const SizedBox(height: CharifyTheme.space16),

                  // Category filters
                  SizedBox(
                    height: 36,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _categories.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final category = _categories[index];
                        final isSelected =
                            _selectedCategory == category ||
                            (_selectedCategory == null && category == 'Tous');

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedCategory = category == 'Tous'
                                  ? null
                                  : category;
                              _loadCases();
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? CharifyTheme.primaryGreen
                                  : CharifyTheme.white,
                              borderRadius: BorderRadius.circular(
                                CharifyTheme.radiusRound,
                              ),
                              border: Border.all(
                                color: isSelected
                                    ? CharifyTheme.primaryGreen
                                    : CharifyTheme.lightGrey,
                              ),
                            ),
                            child: Text(
                              _getCategoryDisplay(category, loc),
                              style: TextStyle(
                                color: isSelected
                                    ? CharifyTheme.white
                                    : CharifyTheme.darkGrey,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Results
            Expanded(
              child: FutureBuilder<List<CaseModel>>(
                future: _casesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: CharifyTheme.primaryGreen,
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return CharifyEmptyState(
                      icon: Icons.error_outline_rounded,
                      title: loc.loadingError,
                      subtitle: loc.errorLoadingCases,
                      actionLabel: loc.retry,
                      onActionPressed: _loadCases,
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return CharifyEmptyState(
                      icon: Icons.inbox_outlined,
                      title: loc.noResults,
                      subtitle: loc.tryAdjustingSearch,
                    );
                  }

                  final allCases = snapshot.data!;
                  final filteredCases = _filterCases(allCases);

                  if (filteredCases.isEmpty) {
                    return CharifyEmptyState(
                      icon: Icons.search_off_rounded,
                      title: loc.noResults,
                      subtitle: loc.noCasesFoundSearch,
                    );
                  }

                  return Column(
                    children: [
                      // Results counter
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: CharifyTheme.space16,
                          vertical: CharifyTheme.space8,
                        ),
                        child: Row(
                          children: [
                            Text(
                              loc.searchResults,
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(color: CharifyTheme.mediumGrey),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: CharifyTheme.primaryGreen.withOpacity(
                                  0.1,
                                ),
                                borderRadius: BorderRadius.circular(
                                  CharifyTheme.radiusRound,
                                ),
                              ),
                              child: Text(
                                '${filteredCases.length} ${loc.found}',
                                style: const TextStyle(
                                  color: CharifyTheme.primaryGreen,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Cases list
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(
                            horizontal: CharifyTheme.space16,
                          ),
                          itemCount: filteredCases.length,
                          itemBuilder: (context, index) {
                            return WecareCaseCard(
                              socialCase: filteredCases[index],
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => CaseDetailsScreen(
                                      caseId: filteredCases[index].id,
                                    ),
                                  ),
                                );
                              },
                              isGridView: false, // List view
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
