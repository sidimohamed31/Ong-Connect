import 'package:flutter/material.dart';
import '../../../data/services/auth_service.dart';
import '../../widgets/ong_case_card.dart'; // We will create this
import '../../../data/services/api_service.dart';
import '../../../data/models/case_model.dart';
import '../auth/login_screen.dart';
import '../auth/register_ong_screen.dart';
import '../cases/add_edit_case_screen.dart'; // We will create this
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

    final ong = _auth.currentOng;

    return Scaffold(
      appBar: AppBar(
        title: Text(ong?.name ?? loc.profile),
        actions: [
          IconButton(
            icon: const Icon(Icons.language),
            onPressed: () => _showLanguageSelector(context),
          ),
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddEditCaseScreen()),
          );
          if (result == true) _loadMyCases();
        },
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: _loadMyCases,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ONG Header
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundImage: ong?.logoUrl.isNotEmpty == true
                            ? NetworkImage(ong!.logoUrl)
                            : null,
                        child: ong?.logoUrl.isEmpty == true
                            ? const Icon(Icons.business)
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ong?.name ?? '',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            if (ong?.email != null) Text(ong!.email!),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                loc.myCases,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),

              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else if (_myCases.isEmpty)
                Center(child: Text(loc.noCasesFound))
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _myCases.length,
                  itemBuilder: (context, index) {
                    final caseItem = _myCases[index];
                    return Card(
                      // Temporary simple card until we separate OngCaseCard
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: caseItem.mainImageUrl.isNotEmpty
                            ? Image.network(
                                caseItem.mainImageUrl,
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                                errorBuilder: (c, e, s) =>
                                    const Icon(Icons.image_not_supported),
                              )
                            : const Icon(Icons.image_not_supported),
                        title: Text(caseItem.title),
                        subtitle: Text(caseItem.status ?? 'En cours'),
                        trailing: IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    AddEditCaseScreen(caseModel: caseItem),
                              ),
                            );
                            if (result == true) _loadMyCases();
                          },
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
