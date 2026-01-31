import 'package:flutter/material.dart';
import '../../../data/services/api_service.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/models/pending_ong_model.dart';
import '../../../core/constants/api_constants.dart';
import 'package:ong_mobile_app/l10n/app_localizations.dart';
import 'ong_validation_screen.dart';
import 'case_validation_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  final _apiService = ApiService();
  final _authService = AuthService();
  late TabController _tabController;

  List<PendingOngModel> _pendingOngs = [];
  List<dynamic> _pendingCases = [];
  bool _isLoadingOngs = true;
  bool _isLoadingCases = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await Future.wait([_loadPendingOngs(), _loadPendingCases()]);
  }

  Future<void> _loadPendingOngs() async {
    setState(() => _isLoadingOngs = true);
    try {
      final data = await _apiService.getPendingOngs();
      if (mounted) {
        setState(() {
          _pendingOngs = data.map((e) => PendingOngModel.fromJson(e)).toList();
          _isLoadingOngs = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingOngs = false);
    }
  }

  Future<void> _loadPendingCases() async {
    setState(() => _isLoadingCases = true);
    try {
      final data = await _apiService.getPendingCases();
      if (mounted) {
        setState(() {
          _pendingCases = data;
          _isLoadingCases = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingCases = false);
    }
  }

  Future<void> _logout() async {
    await _authService.logout();
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.adminDashboard),
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              text: loc.pendingOngs,
              icon: Badge(
                label: Text('${_pendingOngs.length}'),
                child: const Icon(Icons.business),
              ),
            ),
            Tab(
              text: loc.pendingCases,
              icon: Badge(
                label: Text('${_pendingCases.length}'),
                child: const Icon(Icons.assignment),
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildOngsTab(loc), _buildCasesTab(loc)],
      ),
    );
  }

  Widget _buildOngsTab(AppLocalizations loc) {
    if (_isLoadingOngs) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_pendingOngs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, size: 64, color: Colors.green),
            const SizedBox(height: 16),
            Text(loc.noPendingItems),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPendingOngs,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _pendingOngs.length,
        itemBuilder: (context, index) {
          final ong = _pendingOngs[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: CircleAvatar(
                backgroundImage: ong.logoUrl != null
                    ? NetworkImage(
                        '${ApiConstants.rootUrl}/static/${ong.logoUrl}',
                      )
                    : null,
                child: ong.logoUrl == null ? const Icon(Icons.business) : null,
              ),
              title: Text(ong.name),
              subtitle: Text('${ong.email}\n${ong.domains}'),
              isThreeLine: true,
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => OngValidationScreen(ong: ong),
                  ),
                );
                if (result == true) {
                  _loadPendingOngs();
                }
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildCasesTab(AppLocalizations loc) {
    if (_isLoadingCases) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_pendingCases.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, size: 64, color: Colors.green),
            const SizedBox(height: 16),
            Text(loc.noPendingItems),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPendingCases,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _pendingCases.length,
        itemBuilder: (context, index) {
          final caseData = _pendingCases[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: caseData['image_url'] != null
                  ? Image.network(
                      '${ApiConstants.rootUrl}/static/${caseData['image_url']}',
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.broken_image),
                    )
                  : const Icon(Icons.image_not_supported),
              title: Text(caseData['title'] ?? ''),
              subtitle: Text(
                '${caseData['category'] ?? ''} • ${caseData['ong_name'] ?? ''}',
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CaseValidationScreen(caseData: caseData),
                  ),
                );
                if (result == true) {
                  _loadPendingCases();
                }
              },
            ),
          );
        },
      ),
    );
  }
}
