import 'package:flutter/material.dart';
import '../screens/home_screen.dart';
import '../screens/browse_screen.dart';
import '../screens/map_screen.dart';
import '../screens/statistics_screen.dart';
import '../screens/profile/profile_screen.dart';
import 'wecare_bottom_nav.dart';

/// Main navigation wrapper for Wecare layout
class WecareNavigation extends StatefulWidget {
  final Locale currentLocale;
  final Function(Locale) onLanguageChange;

  const WecareNavigation({
    super.key,
    required this.currentLocale,
    required this.onLanguageChange,
  });

  @override
  State<WecareNavigation> createState() => _WecareNavigationState();
}

class _WecareNavigationState extends State<WecareNavigation> {
  int _currentIndex = 0;

  // Changed from late final to a getter so it rebuilds when widget updates
  List<Widget> get _screens => [
    HomeScreen(
      currentLocale: widget.currentLocale,
      onLanguageChange: widget.onLanguageChange,
    ),
    const BrowseScreen(),
    const MapScreen(),
    const StatisticsScreen(),
    ProfileScreen(
      currentLocale: widget.currentLocale,
      onLanguageChange: widget.onLanguageChange,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: WecareBottomNav(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}
