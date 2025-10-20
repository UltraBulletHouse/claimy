import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';

class UploadsApi {
  UploadsApi({String? baseUrl}) : _baseUrl = baseUrl ?? _detectBaseUrl();

  final String _baseUrl;

  static String _detectBaseUrl() {
    const local = 'http://localhost:3000';
    // Android emulator cannot reach localhost on host machine
    try {
      // ignore: deprecated_member_use
      if (const bool.hasEnvironment('dart.library.io')) {}
    } catch (_) {}
    return const String.fromEnvironment('CLAIMY_API_BASE', defaultValue: local);
  }

  Uri _url(String path) => Uri.parse('$_baseUrl$path');

  Future<UploadResult> uploadImages({Uint8List? productBytes, Uint8List? receiptBytes}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('Not authenticated');
    }
    final idToken = await user.getIdToken(true);

    final request = http.MultipartRequest('POST', _url('/api/uploads'));
    request.headers['Authorization'] = 'Bearer $idToken';

    if (productBytes != null) {
      request.files.add(http.MultipartFile.fromBytes('product', productBytes, filename: 'product.jpg'));
    }
    if (receiptBytes != null) {
      request.files.add(http.MultipartFile.fromBytes('receipt', receiptBytes, filename: 'receipt.jpg'));
    }

    final streamed = await request.send();
    final resp = await http.Response.fromStream(streamed);
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      return UploadResult(
        productImageUrl: data['productImageUrl']?.toString(),
        receiptImageUrl: data['receiptImageUrl']?.toString(),
      );
    } else {
      throw Exception('Upload failed: ${resp.statusCode}');
    }
  }
}

class UploadResult {
  UploadResult({this.productImageUrl, this.receiptImageUrl});
  final String? productImageUrl;
  final String? receiptImageUrl;
}
