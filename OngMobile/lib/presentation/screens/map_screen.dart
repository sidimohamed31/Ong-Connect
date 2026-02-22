import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../data/models/case_model.dart';
import '../../data/services/api_service.dart';
import 'case_details_screen.dart';
import '../../core/theme/charify_theme.dart';
import '../widgets/charify_widgets.dart';
import 'package:ong_mobile_app/l10n/app_localizations.dart';

final Map<String, LatLng> wilayaCoordinates = {
  "Adrar": LatLng(20.5169, -13.0499),
  "Assaba": LatLng(16.6166, -11.4),
  "Brakna": LatLng(17.05, -13.9167),
  "Dakhlet Nouadhibou": LatLng(20.9451, -17.0362),
  "Gorgol": LatLng(16.1464, -13.5041),
  "Guidimaka": LatLng(15.1561, -12.1824),
  "Hodh Ech Chargui": LatLng(16.6162, -7.2635),
  "Hodh El Gharbi": LatLng(16.6614, -9.6149),
  "Inchiri": LatLng(19.75, -14.3833),
  "Nouakchott Nord": LatLng(18.12, -15.92),
  "Nouakchott Ouest": LatLng(18.09, -15.97),
  "Nouakchott Sud": LatLng(18.04, -15.95),
  "Tagant": LatLng(18.5564, -11.4272),
  "Tiris Zemmour": LatLng(22.7441, -12.4539),
  "Trarza": LatLng(17.5, -15.5),
};

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final ApiService _apiService = ApiService();
  List<CaseModel> _cases = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCases();
  }

  Future<void> _loadCases() async {
    try {
      final cases = await _apiService.getCases();
      if (mounted) {
        setState(() {
          _cases = cases;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        final loc = AppLocalizations.of(context)!;
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('${loc.loadingError}: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Center on Mauritania
    final center = LatLng(20.0, -12.0);
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(loc.mapsTitle),
        backgroundColor: CharifyTheme.primaryGreen,
        elevation: 0,
        foregroundColor: CharifyTheme.white,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                CharifyTheme.primaryGreen.withOpacity(0.9),
                CharifyTheme.primaryGreen.withOpacity(0.0),
              ],
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: CharifyTheme.primaryGreen,
              ),
            )
          : FlutterMap(
              options: MapOptions(initialCenter: center, initialZoom: 5.5),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.ongconnect.app',
                ),
                MarkerLayer(
                  markers: _cases
                      .map((socialCase) {
                        LatLng? point;
                        bool isApproximate = false;

                        if (socialCase.location.lat != null &&
                            socialCase.location.lng != null) {
                          point = LatLng(
                            socialCase.location.lat!,
                            socialCase.location.lng!,
                          );
                        } else if (socialCase.location.wilaya != null &&
                            wilayaCoordinates.containsKey(
                              socialCase.location.wilaya,
                            )) {
                          point =
                              wilayaCoordinates[socialCase.location.wilaya]!;
                          isApproximate = true;
                        }

                        if (point == null) return null;

                        return Marker(
                          point: point,
                          width: 50,
                          height: 50,
                          child: GestureDetector(
                            onTap: () {
                              _showCaseInfo(socialCase, isApproximate);
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: CharifyTheme.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 6,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.location_on_rounded,
                                color: isApproximate
                                    ? CharifyTheme.accentOrange
                                    : CharifyTheme.dangerRed,
                                size: 30,
                              ),
                            ),
                          ),
                        );
                      })
                      .whereType<Marker>()
                      .toList(),
                ),
              ],
            ),
    );
  }

  void _showCaseInfo(CaseModel socialCase, bool isApproximate) {
    final loc = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.all(CharifyTheme.space16),
        decoration: BoxDecoration(
          color: CharifyTheme.white,
          borderRadius: BorderRadius.circular(CharifyTheme.radiusLarge),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(CharifyTheme.space20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      socialCase.title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (socialCase.status != null)
                    _buildSmallStatusBadge(socialCase.status!),
                ],
              ),
              const SizedBox(height: CharifyTheme.space8),
              if (isApproximate)
                Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      size: 14,
                      color: CharifyTheme.warningYellow,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      loc.approximateLocation,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: CharifyTheme.warningYellow,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: CharifyTheme.space16),

              Row(
                children: [
                  const Icon(
                    Icons.location_city_rounded,
                    size: 18,
                    color: CharifyTheme.mediumGrey,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${socialCase.location.wilaya ?? "---"} > ${socialCase.location.moughataa ?? "---"}',
                    style: const TextStyle(color: CharifyTheme.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: CharifyTheme.space24),
              CharifyGradientButton(
                label: loc.viewDetails,
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CaseDetailsScreen(caseId: socialCase.id),
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

  Widget _buildSmallStatusBadge(String status) {
    Color color;
    final loc = AppLocalizations.of(context)!;
    String displayStatus = status;

    if (status == 'Urgent') {
      color = CharifyTheme.dangerRed;
      displayStatus = loc.urgent;
    } else if (status == 'Résolu') {
      color = CharifyTheme.successGreen;
      displayStatus = loc.statusResolved;
    } else {
      color = CharifyTheme.infoBlue;
      displayStatus = loc.statusInProgress;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        displayStatus.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}
