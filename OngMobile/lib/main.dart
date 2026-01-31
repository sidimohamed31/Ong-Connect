import 'presentation/widgets/wecare_navigation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:ong_mobile_app/l10n/app_localizations.dart'; // Import generated localizations
import 'core/theme/charify_theme.dart'; // Updated theme import

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Locale _locale = const Locale('ar', 'MR'); // Default to Arabic

  void _changeLanguage(Locale newLocale) {
    setState(() {
      _locale = newLocale;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ONG Connect',
      debugShowCheckedModeBanner: false,
      theme: CharifyTheme.getLightTheme(_locale.languageCode),

      // Localization for Arabic & French support
      localizationsDelegates: const [
        AppLocalizations.delegate, // Add this
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales:
          AppLocalizations.supportedLocales, // Use generated supported locales
      locale: _locale,

      // Set text direction based on language
      builder: (context, child) {
        return Directionality(
          textDirection: _locale.languageCode == 'ar'
              ? TextDirection.rtl
              : TextDirection.ltr,
          child: child!,
        );
      },

      home: WecareNavigation(
        currentLocale: _locale,
        onLanguageChange: _changeLanguage,
      ),
    );
  }
}
