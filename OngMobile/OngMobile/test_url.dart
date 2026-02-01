import 'package:flutter/material.dart';

void main() {
  // Test URL construction
  const String rootUrl = 'http://127.0.0.1:5000';
  const String imagePath = 'uploads/media/20251224232316_test.webp';

  final url = '$rootUrl/static/$imagePath';
  print('Constructed URL: $url');
  print(
    'Expected: http://127.0.0.1:5000/static/uploads/media/20251224232316_test.webp',
  );
}
