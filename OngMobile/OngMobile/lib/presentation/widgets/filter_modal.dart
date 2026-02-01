import 'package:flutter/material.dart';
import '../../data/services/api_service.dart';
import '../../core/theme/charify_theme.dart';
import 'charify_widgets.dart';

class FilterModal extends StatefulWidget {
  final Function(String? category, String? ongId) onApply;

  const FilterModal({super.key, required this.onApply});

  @override
  State<FilterModal> createState() => _FilterModalState();
}

class _FilterModalState extends State<FilterModal> {
  final ApiService _apiService = ApiService();

  List<dynamic> _categories = [];
  List<dynamic> _ongs = [];

  String? _selectedCategory;
  String? _selectedOngId;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFilterData();
  }

  Future<void> _loadFilterData() async {
    try {
      final categories = await _apiService.getCategories();
      final ongs = await _apiService.getOngs();

      if (mounted) {
        setState(() {
          _categories = categories;
          _ongs = ongs;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(CharifyTheme.space24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Filtrer les cas',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: CharifyTheme.darkGrey,
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.close_rounded,
                  color: CharifyTheme.mediumGrey,
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: CharifyTheme.space24),

          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else ...[
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Catégorie',
                prefixIcon: Icon(
                  Icons.category_outlined,
                  color: CharifyTheme.mediumGrey,
                ),
              ),
              value: _selectedCategory,
              icon: const Icon(Icons.keyboard_arrow_down_rounded),
              items: _categories.map<DropdownMenuItem<String>>((cat) {
                return DropdownMenuItem(
                  value: cat['nomCategorie'].toString(),
                  child: Text(cat['nomCategorie'].toString()),
                );
              }).toList(),
              onChanged: (value) => setState(() => _selectedCategory = value),
            ),
            const SizedBox(height: CharifyTheme.space16),

            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Organisation (ONG)',
                prefixIcon: Icon(
                  Icons.business_outlined,
                  color: CharifyTheme.mediumGrey,
                ),
              ),
              value: _selectedOngId,
              icon: const Icon(Icons.keyboard_arrow_down_rounded),
              items: _ongs.map<DropdownMenuItem<String>>((ong) {
                return DropdownMenuItem(
                  value: ong['id_ong'].toString(),
                  child: Text(ong['nom_ong'].toString()),
                );
              }).toList(),
              onChanged: (value) => setState(() => _selectedOngId = value),
            ),
            const SizedBox(height: CharifyTheme.space32),

            CharifyGradientButton(
              label: 'Appliquer les filtres',
              icon: Icons.check_circle_outline,
              onPressed: () {
                widget.onApply(_selectedCategory, _selectedOngId);
                Navigator.pop(context);
              },
            ),

            const SizedBox(height: CharifyTheme.space16),

            TextButton(
              onPressed: () {
                setState(() {
                  _selectedCategory = null;
                  _selectedOngId = null;
                });
                widget.onApply(null, null);
                Navigator.pop(context);
              },
              style: TextButton.styleFrom(
                foregroundColor: CharifyTheme.mediumGrey,
              ),
              child: const Text('Réinitialiser'),
            ),
            const SizedBox(height: CharifyTheme.space12),
          ],
        ],
      ),
    );
  }
}
