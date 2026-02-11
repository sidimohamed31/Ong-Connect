import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'dart:convert';
import 'package:ong_mobile_app/data/services/api_service.dart';

void main() {
  group('ApiService Error Handling', () {
    test('getCases throws Exception on 404 HTML response', () async {
      final client = MockClient((request) async {
        return http.Response('<html>404 Not Found</html>', 404);
      });
      final apiService = ApiService(client: client);

      expect(apiService.getCases(), throwsA(isA<Exception>()));
    });

    test('getCases throws Exception on 500 HTML response', () async {
      final client = MockClient((request) async {
        return http.Response('<html>500 Server Error</html>', 500);
      });
      final apiService = ApiService(client: client);

      expect(apiService.getCases(), throwsA(isA<Exception>()));
    });

    test('getCases throws FormatException on 200 invalid JSON', () async {
      final client = MockClient((request) async {
        return http.Response('{invalid_json}', 200);
      });
      final apiService = ApiService(client: client);

      expect(apiService.getCases(), throwsA(isA<FormatException>()));
    });

    test('getPendingOngs throws Exception on 403 Forbidden', () async {
      final client = MockClient((request) async {
        return http.Response('Forbidden', 403);
      });
      final apiService = ApiService(client: client);

      expect(apiService.getPendingOngs(), throwsA(isA<Exception>()));
    });

    test('deleteCase returns true on success', () async {
      final client = MockClient((request) async {
        return http.Response(json.encode({'status': 'success'}), 200);
      });
      final apiService = ApiService(client: client);

      expect(await apiService.deleteCase(1), true);
    });

    test('deleteCase returns false on failure', () async {
      final client = MockClient((request) async {
        return http.Response(json.encode({'status': 'error'}), 500);
      });
      final apiService = ApiService(client: client);

      expect(await apiService.deleteCase(1), false);
    });
  });
}
