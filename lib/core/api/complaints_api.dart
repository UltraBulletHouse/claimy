import 'dart:convert';
import 'dart:io' show Platform;
import 'package:http/http.dart' as http;

class ComplaintsApi {
  ComplaintsApi({String? baseUrl}) : _baseUrl = baseUrl ?? _detectBaseUrl();

  final String _baseUrl;

  static String _detectBaseUrl() {
    // Default dev backend
    const local = 'http://localhost:3000';
    // Android emulator cannot reach localhost on host machine
    if (_isAndroid) return 'http://10.0.2.2:3000';
    return const String.fromEnvironment('CLAIMY_API_BASE', defaultValue: local);
  }

  static bool get _isAndroid {
    try {
      return Platform.isAndroid;
    } catch (_) {
      return false;
    }
  }

  Uri _url(String path) => Uri.parse('$_baseUrl$path');

  Future<SubmitResult> submitComplaint({
    required String store,
    required String product,
    String? description,
    List<String>? images,
    String? name,
    String? email,
  }) async {
    final payload = {
      'store': store,
      'product': product,
      if (description != null && description.trim().isNotEmpty)
        'description': description.trim(),
      if (images != null) 'images': images,
      if (name != null && name.trim().isNotEmpty) 'name': name.trim(),
      if (email != null && email.trim().isNotEmpty) 'email': email.trim(),
    };

    final resp = await http.post(
      _url('/api/complaints'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );

    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      return SubmitResult(
        ok: data['ok'] == true,
        id: data['id']?.toString(),
        emailSent: data['emailSent'] == true,
        message: data['message']?.toString(),
      );
    }

    String message;
    try {
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      message = data['error']?.toString() ?? 'Request failed (${resp.statusCode})';
    } catch (_) {
      message = 'Request failed (${resp.statusCode})';
    }
    throw SubmitException(message, statusCode: resp.statusCode);
  }
}

class SubmitResult {
  SubmitResult({required this.ok, this.id, this.emailSent, this.message});
  final bool ok;
  final String? id;
  final bool? emailSent;
  final String? message;
}

class SubmitException implements Exception {
  SubmitException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;
  @override
  String toString() => 'SubmitException(${statusCode ?? ''}): $message';
}
