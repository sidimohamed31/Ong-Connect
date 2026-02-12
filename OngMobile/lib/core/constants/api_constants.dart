import 'package:flutter/foundation.dart';

class ApiConstants {
  // IMPORTANT: Change this to your computer's local IP address when using a physical device
  static const String _physicalDeviceBaseUrl = 'http://10.9.165.203:3000/api';
  static const String _emulatorBaseUrl = 'http://10.0.2.2:3000/api';
  static const String _localBaseUrl = 'http://127.0.0.1:3000/api';

  // Set this to true when testing on a physical device, false for emulator
  static const bool _usePhysicalDevice = true;

  static String get baseUrl {
    if (kIsWeb) return _localBaseUrl;
    // On Android
    if (defaultTargetPlatform == TargetPlatform.android) {
      return _usePhysicalDevice ? _physicalDeviceBaseUrl : _emulatorBaseUrl;
    }
    // For iOS, Windows, macOS, Linux use localhost
    return _localBaseUrl;
  }

  static String get rootUrl {
    final base = baseUrl;
    // Remove '/api' from the end if present to get the root for static files
    if (base.endsWith('/api')) {
      return base.substring(0, base.length - 4);
    }
    return base;
  }

  static String get casesEndpoint => '$baseUrl/cases'; // For public cases
  static String get legacyCasesEndpoint =>
      '$baseUrl/cases_legacy'; // Keep if you use legacy endpoint somewhere or ensure using correct one
  static String get ongsEndpoint => '$baseUrl/ongs';
  static String get categoriesEndpoint => '$baseUrl/categories';
  static String get statisticsEndpoint => '$baseUrl/statistics';

  // Auth
  static String get loginEndpoint => '$baseUrl/auth/login';
  static String get registerEndpoint => '$baseUrl/auth/register';

  // ONG Actions
  static String get myCasesEndpoint => '$baseUrl/cases'; // GET with ong_id
  static String get addCaseEndpoint => '$baseUrl/cases/add'; // POST
  static String get updateCaseEndpoint =>
      '$baseUrl/cases/update'; // POST needs ID logic or use cases/edit/id
  static String deleteCaseEndpoint(int id) => '$baseUrl/cases/delete/$id';
  static String updateCaseStatusEndpoint(int id) =>
      '$baseUrl/cases/update-status/$id';
  static String updateCaseDetailsEndpoint(int id) => '$baseUrl/cases/edit/$id';

  static String getCaseDetails(int id) => '$casesEndpoint/$id';
  static String get registerOngEndpoint => '$baseUrl/ngos/register';

  // Admin endpoints
  static String get adminPendingOngsEndpoint => '$baseUrl/admin/pending-ongs';
  static String get adminPendingCasesEndpoint => '$baseUrl/admin/pending-cases';
  static String adminApproveOngEndpoint(int id) =>
      '$baseUrl/admin/ong/$id/approve';
  static String adminRejectOngEndpoint(int id) =>
      '$baseUrl/admin/ong/$id/reject';
  static String adminApproveCaseEndpoint(int id) =>
      '$baseUrl/admin/case/$id/approve';
  static String adminRejectCaseEndpoint(int id) =>
      '$baseUrl/admin/case/$id/reject';

  static String get notificationsEndpoint => '$baseUrl/notifications';
}
