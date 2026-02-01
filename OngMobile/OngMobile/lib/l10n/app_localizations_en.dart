// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'ONG Connect';

  @override
  String get home => 'Home';

  @override
  String get browse => 'Browse';

  @override
  String get stats => 'Stats';

  @override
  String get profile => 'Profile';

  @override
  String get urgentCases => 'Urgent Cases';

  @override
  String get seeAll => 'See All';

  @override
  String get urgent => 'Urgent';

  @override
  String get error => 'Error';

  @override
  String get errorLoadingCases => 'Failed to load cases';

  @override
  String get retry => 'Retry';

  @override
  String get noCases => 'No Cases';

  @override
  String get noCasesSubtitle => 'No cases available at the moment';

  @override
  String get noNotifications => 'No new notifications';

  @override
  String get categoryAll => 'All';

  @override
  String get categoryHealth => 'Health';

  @override
  String get categoryEducation => 'Education';

  @override
  String get categoryFood => 'Food';

  @override
  String get categoryHousing => 'Housing';

  @override
  String get search => 'Search';

  @override
  String get login => 'Login';

  @override
  String get register => 'Register';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get forgotPassword => 'Forgot Password?';

  @override
  String get welcomeBack => 'Welcome Back';

  @override
  String get createAccount => 'Create Account';

  @override
  String get fullName => 'Full Name';

  @override
  String get phone => 'Phone';

  @override
  String get confirmPassword => 'Confirm Password';

  @override
  String get alreadyHaveAccount => 'Already have an account?';

  @override
  String get loginAction => 'Login';

  @override
  String get registerAction => 'Register';

  @override
  String get logout => 'Logout';

  @override
  String get settings => 'Settings';

  @override
  String get language => 'Language';

  @override
  String get help => 'Help';

  @override
  String get about => 'About';

  @override
  String get donate => 'Donate';

  @override
  String get share => 'Share';

  @override
  String get contactUs => 'Contact Us';

  @override
  String get notifications => 'Notifications';

  @override
  String get addCase => 'Add Case';

  @override
  String get editCase => 'Edit Case';

  @override
  String get title => 'Title';

  @override
  String get description => 'Description';

  @override
  String get category => 'Category';

  @override
  String get wilaya => 'Wilaya';

  @override
  String get moughataa => 'Moughataa';

  @override
  String get specificAddress => 'Specific Address';

  @override
  String get status => 'Status';

  @override
  String get selectImages => 'Select Images';

  @override
  String get updateCase => 'Update Case';

  @override
  String get operationFailed => 'Operation failed';

  @override
  String get pleaseSelectCategory => 'Please select a category';

  @override
  String get pleaseSelectWilaya => 'Please select a Wilaya';

  @override
  String get fieldRequired => 'Required';

  @override
  String get statusInProgress => 'In Progress';

  @override
  String get statusResolved => 'Resolved';

  @override
  String get loginTitle => 'ONG Login';

  @override
  String get loginError => 'Invalid email or password';

  @override
  String get genericError => 'An error occurred. Please try again.';

  @override
  String get pleaseEnterEmail => 'Please enter your email';

  @override
  String get pleaseEnterPassword => 'Please enter your password';

  @override
  String get notConnected => 'You are not connected';

  @override
  String get connectAsOng => 'Connect as ONG';

  @override
  String get myCases => 'My Cases';

  @override
  String get noCasesFound => 'No cases found';

  @override
  String get caseStatus => 'Case Status';

  @override
  String get publishedOn => 'Published on';

  @override
  String get organizer => 'Organizer';

  @override
  String get verifiedOng => 'Verified ONG';

  @override
  String get call => 'Call';

  @override
  String get sendEmail => 'Send Email';

  @override
  String shareText(String title, String description, String wilaya) {
    return 'Check out this urgent case on ONG Connect: $title\n\n$description\n\nLocation: $wilaya';
  }

  @override
  String get errorLoadingDetails => 'Failed to load details';

  @override
  String get caseNotFound => 'Case not found';

  @override
  String get back => 'Back';

  @override
  String get searchCases => 'Search cases...';

  @override
  String get all => 'All';

  @override
  String get water => 'Water';

  @override
  String get health => 'Health';

  @override
  String get education => 'Education';

  @override
  String get food => 'Food';

  @override
  String get housing => 'Housing';

  @override
  String get noResults => 'No results';

  @override
  String get tryAdjustingSearch => 'Try adjusting your search';

  @override
  String get noCasesFoundSearch => 'No cases match your search';

  @override
  String get searchResults => 'Search results';

  @override
  String get found => 'found';

  @override
  String get mapsTitle => 'Case Map';

  @override
  String get loadingError => 'Loading error';

  @override
  String get viewDetails => 'View Details';

  @override
  String get approximateLocation => 'Approximate Location (Wilaya)';

  @override
  String get statistics => 'Statistics';

  @override
  String get unavailable => 'Unavailable';

  @override
  String get noStatsAvailable => 'No statistics available yet';

  @override
  String get total => 'Total';

  @override
  String get distributionByStatus => 'Distribution by Status';

  @override
  String get topWilayas => 'Top Wilayas';

  @override
  String get processed => 'processed';

  @override
  String get today => 'Today';

  @override
  String get oneDay => '1 day';

  @override
  String get days => 'days';

  @override
  String get months => 'months';

  @override
  String get general => 'General';

  @override
  String get noDescription => 'No description available';

  @override
  String get ongName => 'NGO Name';

  @override
  String get logo => 'Logo';

  @override
  String get verificationFile => 'Verification Document';

  @override
  String get domains => 'Intervention Domains';

  @override
  String get createOngAccount => 'Create NGO Account';

  @override
  String get registerSuccess => 'Account created! Awaiting admin validation.';

  @override
  String get selectDomains => 'Select Domains';

  @override
  String get adminDashboard => 'Admin Dashboard';

  @override
  String get pendingOngs => 'Pending ONGs';

  @override
  String get pendingCases => 'Pending Cases';

  @override
  String get noPendingItems => 'No pending items';

  @override
  String get validationDetails => 'Validation Details';

  @override
  String get approve => 'Approve';

  @override
  String get confirmApprove => 'Are you sure you want to approve this item?';

  @override
  String get approveSuccess => 'Approved successfully';

  @override
  String get reject => 'Reject';

  @override
  String get confirmReject => 'Are you sure you want to reject this item?';

  @override
  String get rejectSuccess => 'Rejected successfully';

  @override
  String get cancel => 'Cancel';

  @override
  String get ong => 'ONG';

  @override
  String get location => 'Location';

  @override
  String get verificationDocument => 'Verification Document';
}
