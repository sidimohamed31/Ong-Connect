import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants/api_constants.dart';
import '../models/case_model.dart';
import 'auth_service.dart';
import 'dart:developer';

class ApiService {
  Future<List<CaseModel>> getCases({String? category, String? ongId}) async {
    final uri = Uri.parse(ApiConstants.casesEndpoint).replace(
      queryParameters: {
        if (category != null) 'category': category,
        if (ongId != null) 'ong_id': ongId,
      },
    );

    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          return (data['data'] as List)
              .map((e) => CaseModel.fromJson(e))
              .toList();
        }
      }
      throw Exception('Failed to load cases: ${response.body}');
    } catch (e) {
      log('Error fetching cases from ${uri.toString()}: $e');
      print('API Error: $e'); // Also print for debugging
      rethrow;
    }
  }

  Future<CaseModel> getCaseDetails(int id) async {
    try {
      final response = await http.get(
        Uri.parse(ApiConstants.getCaseDetails(id)),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          return CaseModel.fromJson(data['data']);
        }
      }
      throw Exception('Failed to load case details');
    } catch (e) {
      log('Error fetching case details: $e');
      rethrow;
    }
  }

  Future<List<dynamic>> getCategories() async {
    try {
      final response = await http.get(
        Uri.parse(ApiConstants.categoriesEndpoint),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return data['categories'];
        }
      }
      return [];
    } catch (e) {
      log('Error fetching categories: $e');
      return [];
    }
  }

  Future<List<dynamic>> getOngs() async {
    try {
      final response = await http.get(Uri.parse(ApiConstants.ongsEndpoint));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return data['ongs'];
        }
      }
      return [];
    } catch (e) {
      log('Error fetching ONGs: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> getStatistics() async {
    try {
      final response = await http.get(
        Uri.parse(ApiConstants.statisticsEndpoint),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          return data['data'];
        }
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
    String? logoPath,
    String? docPath,
  }) async {
    try {
      final uri = Uri.parse(ApiConstants.registerOngEndpoint);
      var request = http.MultipartRequest('POST', uri);

      fields.forEach((key, value) {
        request.fields[key] = value;
      });

      if (logoPath != null) {
        request.files.add(await http.MultipartFile.fromPath('logo', logoPath));
      }

      if (docPath != null) {
        request.files.add(
          await http.MultipartFile.fromPath('verification_doc', docPath),
        );
      }

      final response = await request.send();
      final respStr = await response.stream.bytesToString();

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(respStr);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      log('Error registering ONG: $e');
      return false;
    }
  }

  Future<bool> addCase(
    Map<String, String> fields,
    List<String> imagePaths,
  ) async {
    try {
      final uri = Uri.parse(ApiConstants.addCaseEndpoint);
      var request = http.MultipartRequest('POST', uri);

      // Add Auth Header
      if (AuthService().token != null) {
        request.headers['Authorization'] = 'Bearer ${AuthService().token}';
      }

      // Add fields
      fields.forEach((key, value) {
        request.fields[key] = value;
      });

      // Add files
      for (var path in imagePaths) {
        request.files.add(await http.MultipartFile.fromPath('media', path));
      }

      final response = await request.send();
      final respStr = await response.stream.bytesToString();

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(respStr);
        return data['success'] == true;
      }
      log('Failed to add case: ${response.statusCode} - $respStr');
      return false;
    } catch (e) {
      log('Error adding case: $e');
      return false;
    }
  }

  Future<bool> updateCase(
    int id,
    Map<String, String> fields,
    List<String> imagePaths,
  ) async {
    try {
      final uri = Uri.parse(ApiConstants.updateCaseDetailsEndpoint(id));
      var request = http.MultipartRequest('POST', uri);

      if (AuthService().token != null) {
        request.headers['Authorization'] = 'Bearer ${AuthService().token}';
      }

      fields.forEach((key, value) {
        request.fields[key] = value;
      });

      for (var path in imagePaths) {
        request.files.add(await http.MultipartFile.fromPath('media', path));
      }

      final response = await request.send();
      if (response.statusCode == 200) {
        return true;
      }
      return false;
    } catch (e) {
      log('Error updating case: $e');
      return false;
    }
  }

  // --- Admin Operations ---

  Future<List<dynamic>> getPendingOngs() async {
    try {
      final response = await http.get(
        Uri.parse(ApiConstants.adminPendingOngsEndpoint),
        headers: {'Authorization': 'Bearer ${AuthService().token}'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return data['data'];
        }
      }
      throw Exception('Failed to load pending ONGs');
    } catch (e) {
      log('Error fetching pending ONGs: $e');
      rethrow;
    }
  }

  Future<List<dynamic>> getPendingCases() async {
    try {
      final response = await http.get(
        Uri.parse(ApiConstants.adminPendingCasesEndpoint),
        headers: {'Authorization': 'Bearer ${AuthService().token}'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return data['data'];
        }
      }
      throw Exception('Failed to load pending cases');
    } catch (e) {
      log('Error fetching pending cases: $e');
      rethrow;
    }
  }

  Future<bool> approveOng(int id) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.adminApproveOngEndpoint(id)),
        headers: {'Authorization': 'Bearer ${AuthService().token}'},
      );

      return response.statusCode == 200;
    } catch (e) {
      log('Error approving ONG: $e');
      return false;
    }
  }

  Future<bool> rejectOng(int id) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.adminRejectOngEndpoint(id)),
        headers: {'Authorization': 'Bearer ${AuthService().token}'},
      );

      return response.statusCode == 200;
    } catch (e) {
      log('Error rejecting ONG: $e');
      return false;
    }
  }

  Future<bool> approveCase(int id) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.adminApproveCaseEndpoint(id)),
        headers: {'Authorization': 'Bearer ${AuthService().token}'},
      );

      return response.statusCode == 200;
    } catch (e) {
      log('Error approving case: $e');
      return false;
    }
  }

  Future<bool> rejectCase(int id) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.adminRejectCaseEndpoint(id)),
        headers: {'Authorization': 'Bearer ${AuthService().token}'},
      );

      return response.statusCode == 200;
    } catch (e) {
      log('Error rejecting case: $e');
      return false;
    }
  }
}
