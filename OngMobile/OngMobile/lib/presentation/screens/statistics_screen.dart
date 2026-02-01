import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../data/services/api_service.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/charify_theme.dart';
import '../widgets/charify_widgets.dart';
import 'package:ong_mobile_app/l10n/app_localizations.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  final ApiService _apiService = ApiService();
  Map<String, dynamic>? _stats;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final stats = await _apiService.getStatistics();
      if (mounted) {
        setState(() {
          _stats = stats;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: CharifyTheme.backgroundGrey,
      appBar: AppBar(
        title: Text(loc.statistics),
        backgroundColor: CharifyTheme.white,
        foregroundColor: CharifyTheme.darkGrey,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadStats,
            color: CharifyTheme.primaryGreen,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    final loc = AppLocalizations.of(context)!;
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: CharifyTheme.primaryGreen),
      );
    }

    if (_errorMessage != null) {
      return CharifyEmptyState(
        icon: Icons.error_outline_rounded,
        title: loc.error,
        subtitle: _errorMessage,
        actionLabel: loc.retry,
        onActionPressed: _loadStats,
      );
    }

    if (_stats == null) {
      return CharifyEmptyState(
        icon: Icons.bar_chart_rounded,
        title: loc.unavailable,
        subtitle: loc.noStatsAvailable,
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(CharifyTheme.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildOverviewSection(),
          const SizedBox(height: CharifyTheme.space24),
          _buildStatusSection(),
          const SizedBox(height: CharifyTheme.space24),
          _buildWilayaSection(),
          const SizedBox(height: CharifyTheme.space48),
        ],
      ),
    );
  }

  Widget _buildOverviewSection() {
    final loc = AppLocalizations.of(context)!;
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.1,
      children: [
        CharifyStatCard(
          title: loc.total,
          value: _stats!['total_cases'].toString(),
          color: CharifyTheme.infoBlue,
          icon: Icons.folder_open_rounded,
        ),
        CharifyStatCard(
          title: loc.urgent,
          value: _stats!['urgent_cases'].toString(),
          color: CharifyTheme.dangerRed,
          icon: Icons.warning_rounded,
        ),
        CharifyStatCard(
          title: loc.statusResolved,
          value: _stats!['resolved_cases'].toString(),
          color: CharifyTheme.successGreen,
          icon: Icons.check_circle_rounded,
        ),
      ],
    ).animate().fadeIn().slideX();
  }

  Widget _buildStatusSection() {
    final loc = AppLocalizations.of(context)!;
    final statusData = _stats!['status_stats'] as List;
    return CharifyCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            loc.distributionByStatus,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: CharifyTheme.darkGrey,
            ),
          ),
          const SizedBox(height: CharifyTheme.space32),
          SizedBox(
            height: 180,
            child: PieChart(
              PieChartData(
                sections: statusData.map((s) {
                  final color = s['statut'] == 'Urgent'
                      ? CharifyTheme.dangerRed
                      : s['statut'] == 'Résolu'
                      ? CharifyTheme.successGreen
                      : CharifyTheme.accentOrange;
                  return PieChartSectionData(
                    value: s['count'].toDouble(),
                    title: '${s['count']}',
                    color: color,
                    radius: 40,
                    titleStyle: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  );
                }).toList(),
                sectionsSpace: 2,
                centerSpaceRadius: 35,
                borderData: FlBorderData(show: false),
              ),
            ),
          ),
          const SizedBox(height: CharifyTheme.space24),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: statusData.map((s) {
              final color = s['statut'] == 'Urgent'
                  ? CharifyTheme.dangerRed
                  : s['statut'] == 'Résolu'
                  ? CharifyTheme.successGreen
                  : CharifyTheme.warningYellow;

              String statusLabel = s['statut'];
              if (s['statut'] == 'Urgent')
                statusLabel = loc.urgent;
              else if (s['statut'] == 'Résolu')
                statusLabel = loc.statusResolved;
              else if (s['statut'] == 'En cours')
                statusLabel = loc.statusInProgress;

              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    statusLabel,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).scale();
  }

  Widget _buildWilayaSection() {
    final loc = AppLocalizations.of(context)!;
    final wilayaData = (_stats!['wilaya_stats'] as List).take(6).toList();
    return CharifyCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            loc.topWilayas,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: CharifyTheme.darkGrey,
            ),
          ),
          const SizedBox(height: CharifyTheme.space32),
          SizedBox(
            height: 250,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY:
                    (wilayaData.isNotEmpty
                            ? wilayaData.first['count'] as int
                            : 0)
                        .toDouble() +
                    2,
                barGroups: wilayaData.asMap().entries.map((e) {
                  return BarChartGroupData(
                    x: e.key,
                    barRods: [
                      BarChartRodData(
                        toY: e.value['count'].toDouble(),
                        color: CharifyTheme.primaryGreen,
                        width: 16,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4),
                        ),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY:
                              (wilayaData.first['count'] as int).toDouble() + 2,
                          color: CharifyTheme.lightGrey.withOpacity(0.5),
                        ),
                      ),
                    ],
                  );
                }).toList(),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= wilayaData.length) {
                          return const Text('');
                        }
                        final label = wilayaData[value.toInt()]['wilaya'];
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            label != null && label.length > 3
                                ? '${label.substring(0, 3)}..'
                                : label ?? '',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: CharifyTheme.mediumGrey,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1);
  }
}
