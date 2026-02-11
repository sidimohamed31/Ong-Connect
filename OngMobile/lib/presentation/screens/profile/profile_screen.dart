import 'package:flutter/material.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/api_service.dart';
import '../../../data/models/case_model.dart';
import '../auth/login_screen.dart';
import '../auth/register_ong_screen.dart';
import '../cases/add_edit_case_screen.dart'; // We will create this
import '../admin/admin_dashboard_screen.dart';
import 'package:ong_mobile_app/l10n/app_localizations.dart';

class ProfileScreen extends StatefulWidget {
  final Locale? currentLocale;
  final Function(Locale)? onLanguageChange;

  const ProfileScreen({super.key, this.currentLocale, this.onLanguageChange});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _auth = AuthService();
  bool _isLoading = false;
  List<CaseModel> _myCases = [];

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    await _auth.init();
    if (mounted) setState(() {});
    if (_auth.isLoggedIn) {
      _loadMyCases();
    }
  }

  Future<void> _loadMyCases() async {
    setState(() => _isLoading = true);
    try {
      final cases = await ApiService().getCases(
        ongId: _auth.currentOng?.id.toString(),
      );
      if (mounted) {
        setState(() {
          _myCases = cases;
        });
      }
    } catch (e) {
      print('Error loading cases: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    await _auth.logout();
    if (mounted)
      setState(() {
        _myCases = [];
      });
  }

  void _showLanguageSelector(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(loc.language),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLanguageOption(
              context: dialogContext,
              locale: const Locale('ar', 'MR'),
              flag: '🇲🇷',
              label: 'العربية',
            ),
            const Divider(),
            _buildLanguageOption(
              context: dialogContext,
              locale: const Locale('fr', 'FR'),
              flag: '🇫🇷',
              label: 'Français',
            ),
            const Divider(),
            _buildLanguageOption(
              context: dialogContext,
              locale: const Locale('en', 'US'),
              flag: '🇺🇸',
              label: 'English',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageOption({
    required BuildContext context,
    required Locale locale,
    required String flag,
    required String label,
  }) {
    final isSelected =
        widget.currentLocale?.languageCode == locale.languageCode;

    return ListTile(
      leading: Text(flag, style: const TextStyle(fontSize: 32)),
      title: Text(label),
      trailing: isSelected
          ? const Icon(Icons.check, color: Colors.green)
          : null,
      onTap: () {
        if (widget.onLanguageChange != null) {
          widget.onLanguageChange!(locale);
        }
        Navigator.pop(context);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    if (!_auth.isLoggedIn) {
      return Scaffold(
        appBar: AppBar(
          title: Text(loc.profile),
          actions: [
            IconButton(
              icon: const Icon(Icons.language),
              onPressed: () => _showLanguageSelector(context),
            ),
          ],
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.account_circle, size: 80, color: Colors.grey),
              const SizedBox(height: 16),
              Text(loc.notConnected, style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                  if (result == true) {
                    _checkAuth();
                  }
                },
                child: Text(loc.connectAsOng),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                  if (result == true) {
                    _checkAuth();
                  }
                },
                child: Text(loc.adminLogin),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const RegisterOngScreen(),
                    ),
                  );
                },
                child: Text(loc.createOngAccount),
              ),
            ],
          ),
        ),
      );
    }

    if (_auth.isAdmin) {
      return AdminDashboardScreen(onLogout: _logout);
    }

    final ong = _auth.currentOng;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200.0,
            floating: false,
            pinned: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.language),
                onPressed: () => _showLanguageSelector(context),
              ),
              IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Theme.of(context).primaryColor,
                      Theme.of(context).primaryColor.withOpacity(0.7),
                    ],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.white,
                        child: CircleAvatar(
                          radius: 38,
                          backgroundImage: ong?.logoUrl.isNotEmpty == true
                              ? NetworkImage(ong!.logoUrl)
                              : null,
                          child: ong?.logoUrl.isEmpty == true
                              ? Text(
                                  ong?.name.substring(0, 1).toUpperCase() ?? '',
                                  style: const TextStyle(fontSize: 32),
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        ong?.name ?? '',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (ong?.email != null)
                        Text(
                          ong!.email!,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stats Section
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 5,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem('Total Cases', '${_myCases.length}'),
                        // Add more stats here if available in future
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        loc.myCases,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      ElevatedButton.icon(
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AddEditCaseScreen(),
                            ),
                          );
                          if (result == true) _loadMyCases();
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Add Case'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: _isLoading
                ? const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  )
                : _myCases.isEmpty
                ? SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.folder_open,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(loc.noCasesFound),
                        ],
                      ),
                    ),
                  )
                : SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final caseItem = _myCases[index];
                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.only(bottom: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            ListTile(
                              contentPadding: const EdgeInsets.all(12),
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: caseItem.mainImageUrl.isNotEmpty
                                    ? Image.network(
                                        caseItem.mainImageUrl,
                                        width: 60,
                                        height: 60,
                                        fit: BoxFit.cover,
                                        errorBuilder: (c, e, s) => Container(
                                          width: 60,
                                          height: 60,
                                          color: Colors.grey[200],
                                          child: const Icon(
                                            Icons.image_not_supported,
                                          ),
                                        ),
                                      )
                                    : Container(
                                        width: 60,
                                        height: 60,
                                        color: Colors.grey[200],
                                        child: const Icon(
                                          Icons.image_not_supported,
                                        ),
                                      ),
                              ),
                              title: Text(
                                caseItem.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(caseItem.status ?? 'En cours'),
                                  const SizedBox(height: 4),
                                  Text(
                                    caseItem.date ?? '',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Divider(height: 1),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton.icon(
                                  icon: const Icon(Icons.edit, size: 18),
                                  label: const Text('Edit'),
                                  onPressed: () async {
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => AddEditCaseScreen(
                                          caseModel: caseItem,
                                        ),
                                      ),
                                    );
                                    if (result == true) _loadMyCases();
                                  },
                                ),
                                const SizedBox(width: 8),
                                TextButton.icon(
                                  icon: const Icon(
                                    Icons.delete,
                                    size: 18,
                                    color: Colors.red,
                                  ),
                                  label: const Text(
                                    'Delete',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                  onPressed: () => _confirmDelete(caseItem),
                                ),
                                const SizedBox(width: 8),
                              ],
                            ),
                          ],
                        ),
                      );
                    }, childCount: _myCases.length),
                  ),
          ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
      ],
    );
  }

  Future<void> _confirmDelete(CaseModel caseItem) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Case'),
        content: Text('Are you sure you want to delete "${caseItem.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      final success = await ApiService().deleteCase(caseItem.id);
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Case deleted successfully')),
          );
          _loadMyCases();
        }
      } else {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to delete case')),
          );
        }
      }
    }
  }
}
