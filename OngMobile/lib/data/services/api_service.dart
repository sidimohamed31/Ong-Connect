import 'dart:convert';
import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../../core/constants/api_constants.dart';
import '../models/case_model.dart';
import '../models/notification_model.dart';
import 'auth_service.dart';

class ApiService {
  final http.Client client;

  ApiService({http.Client? client}) : client = client ?? http.Client();

  // Helper to handle HTTP responses safely
  dynamic _processResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      try {
        return json.decode(response.body);
      } catch (e) {
        log('JSON Decode Error: ${response.body}');
        throw FormatException('Invalid JSON response from server');
      }
    } else {
      // Try to parse error message from JSON, otherwise throw generic
      String errorMessage = 'Server error: ${response.statusCode}';
      try {
        final errorData = json.decode(response.body);
        if (errorData is Map && errorData.containsKey('error')) {
          errorMessage = errorData['error'];
        } else if (errorData is Map && errorData.containsKey('message')) {
          errorMessage = errorData['message'];
        }
      } catch (_) {
        // If body is HTML or plain text, use generic message but log body
        log(
          'Non-JSON Error Response (${response.statusCode}): ${response.body}',
        );
      }
      throw Exception(errorMessage);
    }
  }

  Future<List<CaseModel>> getCases({String? category, String? ongId}) async {
    final uri = Uri.parse(ApiConstants.casesEndpoint).replace(
      queryParameters: {
        if (category != null) 'category': category,
        if (ongId != null) 'ong_id': ongId,
      },
    );

    try {
      final response = await client.get(uri);
      final data = _processResponse(response);

      if (data != null && data['status'] == 'success') {
        return (data['data'] as List)
            .map((e) => CaseModel.fromJson(e))
            .toList();
      }
      return [];
    } catch (e) {
      log('Error fetching cases: $e');
      rethrow;
    }
  }

  Future<CaseModel> getCaseDetails(int id) async {
    try {
      final response = await client.get(
        Uri.parse(ApiConstants.getCaseDetails(id)),
      );
      final data = _processResponse(response);

      if (data != null && data['status'] == 'success') {
        return CaseModel.fromJson(data['data']);
      }
      throw Exception('Failed to load case details');
    } catch (e) {
      log('Error fetching case details: $e');
      rethrow;
    }
  }

  Future<List<dynamic>> getCategories() async {
    try {
      final response = await client.get(
        Uri.parse(ApiConstants.categoriesEndpoint),
      );

      if (response.statusCode == 200) {
        try {
          final data = json.decode(response.body);
          if (data is Map && data['success'] == true) {
            return data['categories'];
          }
        } catch (_) {}
      }
      return [];
    } catch (e) {
      log('Error fetching categories: $e');
      return [];
    }
  }

  Future<List<dynamic>> getOngs() async {
    try {
      final response = await client.get(Uri.parse(ApiConstants.ongsEndpoint));
      final data = _processResponse(response);
      if (data != null && data['success'] == true) {
        return data['ongs'];
      }
      return [];
    } catch (e) {
      log('Error fetching ONGs: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> getStatistics() async {
    try {
      final response = await client.get(
        Uri.parse(ApiConstants.statisticsEndpoint),
      );
      final data = _processResponse(response);
      if (data != null && data['status'] == 'success') {
        return data['data'];
      }
      throw Exception('Failed to load statistics');
    } catch (e) {
      log('Error fetching statistics: $e');
      rethrow;
    }
  }

  // --- CRUD Operations for ONG Cases ---

  Future<bool> registerOng(
    Map<String, String> fields, {
    XFile? logo,
    XFile? doc,
  }) async {
    try {
      final uri = Uri.parse(ApiConstants.registerOngEndpoint);
      var request = http.MultipartRequest('POST', uri);

      fields.forEach((key, value) {
        request.fields[key] = value;
      });

      if (logo != null) {
        if (kIsWeb) {
          request.files.add(
            http.MultipartFile.fromBytes(
              'logo',
              await logo.readAsBytes(),
              filename: logo.name,
            ),
          );
        } else {
          request.files.add(
            await http.MultipartFile.fromPath('logo', logo.path),
          );
        }
      }

      if (doc != null) {
        if (kIsWeb) {
          request.files.add(
            http.MultipartFile.fromBytes(
              'verification_doc',
              await doc.readAsBytes(),
              filename: doc.name,
            ),
          );
        } else {
          request.files.add(
            await http.MultipartFile.fromPath('verification_doc', doc.path),
          );
        }
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      final data = _processResponse(response);
      return data != null && data['success'] == true;
    } catch (e) {
      log('Error registering ONG: $e');
      return false;
    }
  }

  Future<bool> addCase(Map<String, String> fields, List<XFile> images) async {
    try {
      final uri = Uri.parse(ApiConstants.addCaseEndpoint);
      var request = http.MultipartRequest('POST', uri);

      if (AuthService().token != null) {
        request.headers['Authorization'] = 'Bearer ${AuthService().token}';
      }

      fields.forEach((key, value) {
        request.fields[key] = value;
      });

      for (var image in images) {
        if (kIsWeb) {
          request.files.add(
            http.MultipartFile.fromBytes(
              'media',
              await image.readAsBytes(),
              filename: image.name,
            ),
          );
        } else {
          request.files.add(
            await http.MultipartFile.fromPath('media', image.path),
          );
        }
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      final data = _processResponse(response);
      return data != null && data['success'] == true;
    } catch (e) {
      log('Error adding case: $e');
      return false;
    }
  }

  Future<bool> updateCase(
    int id,
    Map<String, String> fields,
    List<XFile> images,
  ) async {
    try {
      final uri = Uri.parse(ApiConstants.updateCaseDetailsEndpoint(id));
      var request = http.MultipartRequest(
        'POST',
        uri,
      ); // Using POST for update often usually uses PUT or POST

      if (AuthService().token != null) {
        request.headers['Authorization'] = 'Bearer ${AuthService().token}';
      }

      fields.forEach((key, value) {
        request.fields[key] = value;
      });

      for (var image in images) {
        if (kIsWeb) {
          request.files.add(
            http.MultipartFile.fromBytes(
              'media',
              await image.readAsBytes(),
              filename: image.name,
            ),
          );
        } else {
          request.files.add(
            await http.MultipartFile.fromPath('media', image.path),
          );
        }
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      final data = _processResponse(response);
      return data != null && data['success'] == true;
    } catch (e) {
      log('Error updating case: $e');
      return false;
    }
  }

  Future<bool> updateOngProfile(Map<String, String> fields, XFile? logo) async {
    try {
      final uri = Uri.parse('${ApiConstants.rootUrl}/api/ong/profile/update');
      var request = http.MultipartRequest('POST', uri);

      if (AuthService().token != null) {
        request.headers['Authorization'] = 'Bearer ${AuthService().token}';
      }

      fields.forEach((key, value) {
        request.fields[key] = value;
      });

      if (logo != null) {
        if (kIsWeb) {
          request.files.add(
            http.MultipartFile.fromBytes(
              'logo',
              await logo.readAsBytes(),
              filename: logo.name,
            ),
          );
        } else {
          request.files.add(
            await http.MultipartFile.fromPath('logo', logo.path),
          );
        }
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      final data = _processResponse(response);
      return data != null && data['success'] == true;
    } catch (e) {
      log('Error updating profile: $e');
      return false;
    }
  }

  Future<bool> deleteCase(int id) async {
    try {
      final uri = Uri.parse('${ApiConstants.casesEndpoint}/$id');
      final response = await client.delete(
        uri,
        headers: {'Authorization': 'Bearer ${AuthService().token}'},
      );

      final data = _processResponse(response);
      return data != null && data['status'] == 'success';
    } catch (e) {
      log('Error deleting case: $e');
      return false;
    }
  }

  // --- Admin Operations ---

  Future<List<dynamic>> getPendingOngs() async {
    try {
      final response = await client.get(
        Uri.parse(ApiConstants.adminPendingOngsEndpoint),
        headers: {'Authorization': 'Bearer ${AuthService().token}'},
      );

      final data = _processResponse(response);
      if (data != null && data['success'] == true) {
        return data['data'];
      }
      throw Exception('Failed to load pending ONGs');
    } catch (e) {
      log('Error fetching pending ONGs: $e');
      rethrow;
    }
  }

  Future<List<dynamic>> getPendingCases() async {
    try {
      final response = await client.get(
        Uri.parse(ApiConstants.adminPendingCasesEndpoint),
        headers: {'Authorization': 'Bearer ${AuthService().token}'},
      );

      final data = _processResponse(response);
      if (data != null && data['success'] == true) {
        return data['data'];
      }
      throw Exception('Failed to load pending cases');
    } catch (e) {
      log('Error fetching pending cases: $e');
      rethrow;
    }
  }

  Future<bool> approveOng(int id) async {
    try {
      final response = await client.post(
        Uri.parse(ApiConstants.adminApproveOngEndpoint(id)),
        headers: {'Authorization': 'Bearer ${AuthService().token}'},
      );
      _processResponse(response); // Will throw if error
      return true;
    } catch (e) {
      log('Error approving ONG: $e');
      return false;
    }
  }

  Future<bool> rejectOng(int id) async {
    try {
      final response = await client.post(
        Uri.parse(ApiConstants.adminRejectOngEndpoint(id)),
        headers: {'Authorization': 'Bearer ${AuthService().token}'},
      );
      _processResponse(response);
      return true;
    } catch (e) {
      log('Error rejecting ONG: $e');
      return false;
    }
  }

  Future<bool> approveCase(int id) async {
    try {
      final response = await client.post(
        Uri.parse(ApiConstants.adminApproveCaseEndpoint(id)),
        headers: {'Authorization': 'Bearer ${AuthService().token}'},
      );
      _processResponse(response);
      return true;
    } catch (e) {
      log('Error approving case: $e');
      return false;
    }
  }

  Future<bool> rejectCase(int id) async {
    try {
      final response = await client.post(
        Uri.parse(ApiConstants.adminRejectCaseEndpoint(id)),
        headers: {'Authorization': 'Bearer ${AuthService().token}'},
      );
      _processResponse(response);
      return true;
    } catch (e) {
      log('Error rejecting case: $e');
      return false;
    }
  }

  Future<List<NotificationModel>> getNotifications() async {
    try {
      final response = await client.get(
        Uri.parse(ApiConstants.notificationsEndpoint),
      );
      final data = _processResponse(response);

      if (data != null && data['success'] == true) {
        return (data['data'] as List)
            .map((e) => NotificationModel.fromJson(e))
            .toList();
      }
      return [];
    } catch (e) {
      log('Error fetching notifications: $e');
      return [];
    }
  }
}
