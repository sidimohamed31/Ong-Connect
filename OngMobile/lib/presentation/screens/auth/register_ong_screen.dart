import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../data/services/api_service.dart';

class RegisterOngScreen extends StatefulWidget {
  const RegisterOngScreen({super.key});

  @override
  State<RegisterOngScreen> createState() => _RegisterOngScreenState();
}

class _RegisterOngScreenState extends State<RegisterOngScreen> {
  final _formKey = GlobalKey<FormState>();
  final _apiService = ApiService();
  bool _isLoading = false;

  // Fields
  String _nomOng = '';
  String _email = '';
  String _phone = '';
  String _adresse = '';
  String _password = '';
  List<String> _selectedDomains = [];
  XFile? _logoFile;
  XFile? _docFile;

  // Data
  List<dynamic> _categories = [];
  bool _isLoadingCategories = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final cats = await _apiService.getCategories();
      if (mounted) {
        setState(() {
          _categories = cats;
          _isLoadingCategories = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingCategories = false);
    }
  }

  Future<void> _pickImage(bool isLogo) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        if (isLogo) {
          _logoFile = picked;
        } else {
          _docFile = picked;
        }
      });
    }
  }

  Future<void> _showDomainDialog() async {
    final loc = AppLocalizations.of(context)!;
    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(loc.selectDomains),
              content: SingleChildScrollView(
                child: ListBody(
                  children: _categories.map((cat) {
                    final name = cat['nomCategorie'] as String;
                    final isSelected = _selectedDomains.contains(name);
                    return CheckboxListTile(
                      value: isSelected,
                      title: Text(name),
                      onChanged: (bool? value) {
                        setDialogState(() {
                          if (value == true) {
                            _selectedDomains.add(name);
                          } else {
                            _selectedDomains.remove(name);
                          }
                        });
                        setState(() {}); // Update parent widget too
                      },
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(loc.back), // Reusing 'Back' or can allow 'Ok'
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _submit() async {
    final loc = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;

    if (_logoFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${loc.fieldRequired}: ${loc.logo}')),
      );
      return;
    }
    if (_docFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${loc.fieldRequired}: ${loc.verificationFile}'),
        ),
      );
      return;
    }

    _formKey.currentState!.save();
    setState(() => _isLoading = true);

    try {
      final success = await _apiService.registerOng(
        {
          'nom_ong': _nomOng,
          'email': _email,
          'telephone': _phone,
          'adresse': _adresse,
          'mot_de_passe': _password,
          'domaine_intervation': _selectedDomains.join(','),
        },
        logo: _logoFile,
        doc: _docFile,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(loc.registerSuccess)));
        Navigator.pop(context);
      } else if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(loc.operationFailed)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(loc.error)));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(loc.createOngAccount)),
      body: _isLoadingCategories
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: loc.ongName,
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.business),
                      ),
                      validator: (v) =>
                          v?.isEmpty == true ? loc.fieldRequired : null,
                      onSaved: (v) => _nomOng = v ?? '',
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: loc.email,
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.email),
                      ),
                      validator: (v) =>
                          v?.isEmpty == true ? loc.fieldRequired : null,
                      onSaved: (v) => _email = v ?? '',
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: loc.phone,
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.phone),
                      ),
                      validator: (v) =>
                          v?.isEmpty == true ? loc.fieldRequired : null,
                      onSaved: (v) => _phone = v ?? '',
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: loc.specificAddress,
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.location_on),
                      ),
                      validator: (v) =>
                          v?.isEmpty == true ? loc.fieldRequired : null,
                      onSaved: (v) => _adresse = v ?? '',
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: loc.password,
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.lock),
                      ),
                      obscureText: true,
                      validator: (v) =>
                          v?.isEmpty == true ? loc.fieldRequired : null,
                      onSaved: (v) => _password = v ?? '',
                    ),
                    const SizedBox(height: 24),

                    // Domain Selection
                    ListTile(
                      title: Text(loc.domains),
                      subtitle: Text(
                        _selectedDomains.isEmpty
                            ? loc.selectDomains
                            : _selectedDomains.join(', '),
                      ),
                      trailing: const Icon(Icons.arrow_drop_down),
                      shape: RoundedRectangleBorder(
                        side: const BorderSide(color: Colors.grey),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      onTap: _showDomainDialog,
                    ),
                    const SizedBox(height: 24),

                    // Logo Upload
                    Text(
                      loc.logo,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () => _pickImage(true),
                      child: Container(
                        height: 100,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: _logoFile != null
                            ? (kIsWeb
                                  ? Image.network(
                                      _logoFile!.path,
                                      fit: BoxFit.contain,
                                    )
                                  : Image.file(
                                      File(_logoFile!.path),
                                      fit: BoxFit.contain,
                                    ))
                            : Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.image,
                                      size: 40,
                                      color: Colors.grey,
                                    ),
                                    Text(loc.selectImages),
                                  ],
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Doc Upload
                    Text(
                      loc.verificationFile,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () => _pickImage(false),
                      child: Container(
                        height: 80,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.grey[100],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.attach_file,
                              color: _docFile != null
                                  ? Colors.green
                                  : Colors.grey,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _docFile != null
                                    ? _docFile!.name
                                    : loc.selectImages,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator()
                          : Text(loc.registerAction),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
