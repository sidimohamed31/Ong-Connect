import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
    Locale('fr'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'ONG Connect'**
  String get appTitle;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @browse.
  ///
  /// In en, this message translates to:
  /// **'Browse'**
  String get browse;

  /// No description provided for @stats.
  ///
  /// In en, this message translates to:
  /// **'Stats'**
  String get stats;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @urgentCases.
  ///
  /// In en, this message translates to:
  /// **'Urgent Cases'**
  String get urgentCases;

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See All'**
  String get seeAll;

  /// No description provided for @urgent.
  ///
  /// In en, this message translates to:
  /// **'Urgent'**
  String get urgent;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @errorLoadingCases.
  ///
  /// In en, this message translates to:
  /// **'Failed to load cases'**
  String get errorLoadingCases;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @noCases.
  ///
  /// In en, this message translates to:
  /// **'No Cases'**
  String get noCases;

  /// No description provided for @noCasesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'No cases available at the moment'**
  String get noCasesSubtitle;

  /// No description provided for @noNotifications.
  ///
  /// In en, this message translates to:
  /// **'No new notifications'**
  String get noNotifications;

  /// No description provided for @categoryAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get categoryAll;

  /// No description provided for @categoryHealth.
  ///
  /// In en, this message translates to:
  /// **'Health'**
  String get categoryHealth;

  /// No description provided for @categoryEducation.
  ///
  /// In en, this message translates to:
  /// **'Education'**
  String get categoryEducation;

  /// No description provided for @categoryFood.
  ///
  /// In en, this message translates to:
  /// **'Food'**
  String get categoryFood;

  /// No description provided for @categoryHousing.
  ///
  /// In en, this message translates to:
  /// **'Housing'**
  String get categoryHousing;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back'**
  String get welcomeBack;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get alreadyHaveAccount;

  /// No description provided for @loginAction.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get loginAction;

  /// No description provided for @registerAction.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get registerAction;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @help.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get help;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @donate.
  ///
  /// In en, this message translates to:
  /// **'Donate'**
  String get donate;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @contactUs.
  ///
  /// In en, this message translates to:
  /// **'Contact Us'**
  String get contactUs;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @addCase.
  ///
  /// In en, this message translates to:
  /// **'Add Case'**
  String get addCase;

  /// No description provided for @editCase.
  ///
  /// In en, this message translates to:
  /// **'Edit Case'**
  String get editCase;

  /// No description provided for @title.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get title;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @wilaya.
  ///
  /// In en, this message translates to:
  /// **'Wilaya'**
  String get wilaya;

  /// No description provided for @moughataa.
  ///
  /// In en, this message translates to:
  /// **'Moughataa'**
  String get moughataa;

  /// No description provided for @specificAddress.
  ///
  /// In en, this message translates to:
  /// **'Specific Address'**
  String get specificAddress;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @selectImages.
  ///
  /// In en, this message translates to:
  /// **'Select Images'**
  String get selectImages;

  /// No description provided for @updateCase.
  ///
  /// In en, this message translates to:
  /// **'Update Case'**
  String get updateCase;

  /// No description provided for @operationFailed.
  ///
  /// In en, this message translates to:
  /// **'Operation failed'**
  String get operationFailed;

  /// No description provided for @pleaseSelectCategory.
  ///
  /// In en, this message translates to:
  /// **'Please select a category'**
  String get pleaseSelectCategory;

  /// No description provided for @pleaseSelectWilaya.
  ///
  /// In en, this message translates to:
  /// **'Please select a Wilaya'**
  String get pleaseSelectWilaya;

  /// No description provided for @fieldRequired.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get fieldRequired;

  /// No description provided for @statusInProgress.
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get statusInProgress;

  /// No description provided for @statusResolved.
  ///
  /// In en, this message translates to:
  /// **'Resolved'**
  String get statusResolved;

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'ONG Login'**
  String get loginTitle;

  /// No description provided for @loginError.
  ///
  /// In en, this message translates to:
  /// **'Invalid email or password'**
  String get loginError;

  /// No description provided for @genericError.
  ///
  /// In en, this message translates to:
  /// **'An error occurred. Please try again.'**
  String get genericError;

  /// No description provided for @pleaseEnterEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email'**
  String get pleaseEnterEmail;

  /// No description provided for @pleaseEnterPassword.
  ///
  /// In en, this message translates to:
  /// **'Please enter your password'**
  String get pleaseEnterPassword;

  /// No description provided for @notConnected.
  ///
  /// In en, this message translates to:
  /// **'You are not connected'**
  String get notConnected;

  /// No description provided for @connectAsOng.
  ///
  /// In en, this message translates to:
  /// **'Connect as ONG'**
  String get connectAsOng;

  /// No description provided for @myCases.
  ///
  /// In en, this message translates to:
  /// **'My Cases'**
  String get myCases;

  /// No description provided for @noCasesFound.
  ///
  /// In en, this message translates to:
  /// **'No cases found'**
  String get noCasesFound;

  /// No description provided for @caseStatus.
  ///
  /// In en, this message translates to:
  /// **'Case Status'**
  String get caseStatus;

  /// No description provided for @publishedOn.
  ///
  /// In en, this message translates to:
  /// **'Published on'**
  String get publishedOn;

  /// No description provided for @organizer.
  ///
  /// In en, this message translates to:
  /// **'Organizer'**
  String get organizer;

  /// No description provided for @verifiedOng.
  ///
  /// In en, this message translates to:
  /// **'Verified ONG'**
  String get verifiedOng;

  /// No description provided for @call.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get call;

  /// No description provided for @sendEmail.
  ///
  /// In en, this message translates to:
  /// **'Send Email'**
  String get sendEmail;

  /// No description provided for @shareText.
  ///
  /// In en, this message translates to:
  /// **'Check out this urgent case on ONG Connect: {title}\n\n{description}\n\nLocation: {wilaya}'**
  String shareText(String title, String description, String wilaya);

  /// No description provided for @errorLoadingDetails.
  ///
  /// In en, this message translates to:
  /// **'Failed to load details'**
  String get errorLoadingDetails;

  /// No description provided for @caseNotFound.
  ///
  /// In en, this message translates to:
  /// **'Case not found'**
  String get caseNotFound;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @searchCases.
  ///
  /// In en, this message translates to:
  /// **'Search cases...'**
  String get searchCases;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @water.
  ///
  /// In en, this message translates to:
  /// **'Water'**
  String get water;

  /// No description provided for @health.
  ///
  /// In en, this message translates to:
  /// **'Health'**
  String get health;

  /// No description provided for @education.
  ///
  /// In en, this message translates to:
  /// **'Education'**
  String get education;

  /// No description provided for @food.
  ///
  /// In en, this message translates to:
  /// **'Food'**
  String get food;

  /// No description provided for @housing.
  ///
  /// In en, this message translates to:
  /// **'Housing'**
  String get housing;

  /// No description provided for @noResults.
  ///
  /// In en, this message translates to:
  /// **'No results'**
  String get noResults;

  /// No description provided for @tryAdjustingSearch.
  ///
  /// In en, this message translates to:
  /// **'Try adjusting your search'**
  String get tryAdjustingSearch;

  /// No description provided for @noCasesFoundSearch.
  ///
  /// In en, this message translates to:
  /// **'No cases match your search'**
  String get noCasesFoundSearch;

  /// No description provided for @searchResults.
  ///
  /// In en, this message translates to:
  /// **'Search results'**
  String get searchResults;

  /// No description provided for @found.
  ///
  /// In en, this message translates to:
  /// **'found'**
  String get found;

  /// No description provided for @mapsTitle.
  ///
  /// In en, this message translates to:
  /// **'Case Map'**
  String get mapsTitle;

  /// No description provided for @loadingError.
  ///
  /// In en, this message translates to:
  /// **'Loading error'**
  String get loadingError;

  /// No description provided for @viewDetails.
  ///
  /// In en, this message translates to:
  /// **'View Details'**
  String get viewDetails;

  /// No description provided for @approximateLocation.
  ///
  /// In en, this message translates to:
  /// **'Approximate Location (Wilaya)'**
  String get approximateLocation;

  /// No description provided for @statistics.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get statistics;

  /// No description provided for @unavailable.
  ///
  /// In en, this message translates to:
  /// **'Unavailable'**
  String get unavailable;

  /// No description provided for @noStatsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No statistics available yet'**
  String get noStatsAvailable;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @distributionByStatus.
  ///
  /// In en, this message translates to:
  /// **'Distribution by Status'**
  String get distributionByStatus;

  /// No description provided for @topWilayas.
  ///
  /// In en, this message translates to:
  /// **'Top Wilayas'**
  String get topWilayas;

  /// No description provided for @processed.
  ///
  /// In en, this message translates to:
  /// **'processed'**
  String get processed;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @oneDay.
  ///
  /// In en, this message translates to:
  /// **'1 day'**
  String get oneDay;

  /// No description provided for @days.
  ///
  /// In en, this message translates to:
  /// **'days'**
  String get days;

  /// No description provided for @months.
  ///
  /// In en, this message translates to:
  /// **'months'**
  String get months;

  /// No description provided for @general.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get general;

  /// No description provided for @noDescription.
  ///
  /// In en, this message translates to:
  /// **'No description available'**
  String get noDescription;

  /// No description provided for @ongName.
  ///
  /// In en, this message translates to:
  /// **'NGO Name'**
  String get ongName;

  /// No description provided for @logo.
  ///
  /// In en, this message translates to:
  /// **'Logo'**
  String get logo;

  /// No description provided for @verificationFile.
  ///
  /// In en, this message translates to:
  /// **'Verification Document'**
  String get verificationFile;

  /// No description provided for @domains.
  ///
  /// In en, this message translates to:
  /// **'Intervention Domains'**
  String get domains;

  /// No description provided for @createOngAccount.
  ///
  /// In en, this message translates to:
  /// **'Create NGO Account'**
  String get createOngAccount;

  /// No description provided for @registerSuccess.
  ///
  /// In en, this message translates to:
  /// **'Account created! Awaiting admin validation.'**
  String get registerSuccess;

  /// No description provided for @selectDomains.
  ///
  /// In en, this message translates to:
  /// **'Select Domains'**
  String get selectDomains;

  /// No description provided for @adminDashboard.
  ///
  /// In en, this message translates to:
  /// **'Admin Dashboard'**
  String get adminDashboard;

  /// No description provided for @pendingOngs.
  ///
  /// In en, this message translates to:
  /// **'Pending ONGs'**
  String get pendingOngs;

  /// No description provided for @pendingCases.
  ///
  /// In en, this message translates to:
  /// **'Pending Cases'**
  String get pendingCases;

  /// No description provided for @noPendingItems.
  ///
  /// In en, this message translates to:
  /// **'No pending items'**
  String get noPendingItems;

  /// No description provided for @validationDetails.
  ///
  /// In en, this message translates to:
  /// **'Validation Details'**
  String get validationDetails;

  /// No description provided for @approve.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get approve;

  /// No description provided for @confirmApprove.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to approve this item?'**
  String get confirmApprove;

  /// No description provided for @approveSuccess.
  ///
  /// In en, this message translates to:
  /// **'Approved successfully'**
  String get approveSuccess;

  /// No description provided for @reject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get reject;

  /// No description provided for @confirmReject.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to reject this item?'**
  String get confirmReject;

  /// No description provided for @rejectSuccess.
  ///
  /// In en, this message translates to:
  /// **'Rejected successfully'**
  String get rejectSuccess;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @ong.
  ///
  /// In en, this message translates to:
  /// **'ONG'**
  String get ong;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @verificationDocument.
  ///
  /// In en, this message translates to:
  /// **'Verification Document'**
  String get verificationDocument;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
