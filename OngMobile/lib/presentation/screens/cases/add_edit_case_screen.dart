import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../data/models/case_model.dart';
import '../../../data/services/api_service.dart';
import 'package:ong_mobile_app/l10n/app_localizations.dart';

class AddEditCaseScreen extends StatefulWidget {
  final CaseModel? caseModel;

  const AddEditCaseScreen({super.key, this.caseModel});

  @override
  State<AddEditCaseScreen> createState() => _AddEditCaseScreenState();
}

class _AddEditCaseScreenState extends State<AddEditCaseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _addressController = TextEditingController();
  final _dateController = TextEditingController();

  String? _selectedCategory;
  String? _selectedWilaya;
  String? _selectedMoughataa;
  String? _selectedStatus;

  List<XFile> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  List<dynamic> _categories = [];
  // Mock Wilayas data for now - ideally fetch from API or hardcoded map
  final Map<String, List<String>> _locations = {
    'Nouakchott Nord': ['Teyarett', 'Dar Naim', 'Toujounine'],
    'Nouakchott Ouest': ['Ksar', 'Sebkha', 'Tevragh Zeina'],
    'Nouakchott Sud': ['Arafat', 'El Mina', 'Riyad'],
    'Nouadhibou': ['Nouadhibou'],
    'Trarza': ['Rosso', 'Rkiz'],
  };

  @override
  void initState() {
    super.initState();
    _loadCategories();
    if (widget.caseModel != null) {
      final c = widget.caseModel!;
      _titleController.text = c.title;
      _descController.text = c.description ?? '';
      _addressController.text = c.address ?? '';
      _selectedWilaya = c.location.wilaya;
      _selectedMoughataa = c.location.moughataa;
      _selectedStatus = c.status;
      _dateController.text =
          c.date ?? DateTime.now().toIso8601String().split('T')[0];
    } else {
      _dateController.text = DateTime.now().toIso8601String().split('T')[0];
    }
  }

  Future<void> _loadCategories() async {
    final cats = await ApiService().getCategories();
    if (mounted) {
      setState(() {
        _categories = cats;
        if (widget.caseModel != null && widget.caseModel!.category != null) {
          final existingName = widget.caseModel!.category!;
          final match = cats.firstWhere(
            (cat) => cat['nomCategorie'] == existingName,
            orElse: () => null,
          );
          if (match != null) {
            _selectedCategory = match['idCategorie'].toString();
          }
        }
      });
    }
  }

  Future<void> _pickImage() async {
    final List<XFile> images = await _picker.pickMultiImage();
    if (images.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(images);
      });
    }
  }

  Future<void> _submit() async {
    final loc = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(loc.pleaseSelectCategory)));
      return;
    }
    if (_selectedWilaya == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(loc.pleaseSelectWilaya)));
      return;
    }

    setState(() => _isLoading = true);

    final fields = {
      'titre': _titleController.text,
      'description': _descController.text,
      'adresse': _addressController.text,
      'category_id': _selectedCategory!,
      'wilaya': _selectedWilaya!,
      'moughataa': _selectedMoughataa ?? '',
      'statut': _selectedStatus ?? 'En cours',
      'date_publication': _dateController.text,
      'latitude': '0.0',
      'longitude': '0.0',
    };

    bool success;
    if (widget.caseModel != null) {
      success = await ApiService().updateCase(
        widget.caseModel!.id,
        fields,
        _selectedImages,
      );
    } else {
      success = await ApiService().addCase(fields, _selectedImages);
    }

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(loc.operationFailed)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.caseModel != null ? loc.editCase : loc.addCase),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: loc.title,
                  border: const OutlineInputBorder(),
                ),
                validator: (v) => v?.isEmpty == true ? loc.fieldRequired : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descController,
                decoration: InputDecoration(
                  labelText: loc.description,
                  border: const OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (v) => v?.isEmpty == true ? loc.fieldRequired : null,
              ),
              const SizedBox(height: 16),

              // Category
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: loc.category,
                  border: const OutlineInputBorder(),
                ),
                value: _selectedCategory,
                items: _categories.map<DropdownMenuItem<String>>((cat) {
                  return DropdownMenuItem(
                    value: cat['idCategorie'].toString(),
                    child: Text(cat['nomCategorie']),
                  );
                }).toList(),
                onChanged: (v) => setState(() => _selectedCategory = v),
              ),
              const SizedBox(height: 16),

              // Location
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: loc.wilaya,
                        border: const OutlineInputBorder(),
                      ),
                      value: _selectedWilaya,
                      items: _locations.keys
                          .map(
                            (w) => DropdownMenuItem(value: w, child: Text(w)),
                          )
                          .toList(),
                      onChanged: (v) {
                        setState(() {
                          _selectedWilaya = v;
                          _selectedMoughataa = null;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: loc.moughataa,
                        border: const OutlineInputBorder(),
                      ),
                      value: _selectedMoughataa,
                      items: _selectedWilaya == null
                          ? []
                          : (_locations[_selectedWilaya] ?? [])
                                .map(
                                  (m) => DropdownMenuItem(
                                    value: m,
                                    child: Text(m),
                                  ),
                                )
                                .toList(),
                      onChanged: (v) => setState(() => _selectedMoughataa = v),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: InputDecoration(
                  labelText: loc.specificAddress,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Status (Edit only or always?)
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: loc.status,
                  border: const OutlineInputBorder(),
                ),
                value: _selectedStatus ?? 'En cours',
                items: ['En cours', 'Urgent', 'Résolu'].map((s) {
                  String label = s;
                  if (s == 'En cours') label = loc.statusInProgress;
                  if (s == 'Résolu') label = loc.statusResolved;
                  if (s == 'Urgent') label = loc.urgent; // Re-use urgent
                  return DropdownMenuItem(
                    value: s,
                    child: Text(label),
                  ); // Value stays as API expects
                }).toList(),
                onChanged: (v) => setState(() => _selectedStatus = v),
              ),
              const SizedBox(height: 16),

              // Date Publication
              TextFormField(
                controller: _dateController,
                decoration: InputDecoration(
                  labelText: loc.date,
                  border: const OutlineInputBorder(),
                  suffixIcon: const Icon(Icons.calendar_today),
                ),
                readOnly:
                    true, // Make it pre-filled and read-only as requested "Auto-Incremented"
                onTap: () async {
                  DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2101),
                  );
                  if (pickedDate != null) {
                    setState(() {
                      _dateController.text = pickedDate.toIso8601String().split(
                        'T',
                      )[0];
                    });
                  }
                },
              ),
              const SizedBox(height: 24),

              // Images
              ElevatedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.image),
                label: Text(loc.selectImages),
              ),
              if (_selectedImages.isNotEmpty)
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _selectedImages.length,
                    itemBuilder: (ctx, i) => Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: kIsWeb
                          ? Image.network(
                              _selectedImages[i].path,
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                            )
                          : Image.file(
                              File(_selectedImages[i].path),
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                            ),
                    ),
                  ),
                ),

              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : Text(
                        widget.caseModel != null ? loc.updateCase : loc.addCase,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
