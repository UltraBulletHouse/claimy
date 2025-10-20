import 'dart:convert';
import 'dart:io' show Platform;
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

class ComplaintsApi {
  ComplaintsApi({String? baseUrl}) : _baseUrl = baseUrl ?? _detectBaseUrl();

  // Fetch only the current user's cases
  Future<GetCasesResult> getCases({int limit = 50, int offset = 0, String sort = '-createdAt'}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw SubmitException('Not authenticated', statusCode: 401);
    }
    final idToken = await user.getIdToken(true);

    final resp = await http.get(
      _url('/api/cases?limit=$limit&offset=$offset&sort=${Uri.encodeQueryComponent(sort)}'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
    );

    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final items = (data['items'] as List<dynamic>? ?? const [])
          .cast<Map<String, dynamic>>();
      return GetCasesResult(
        items: items,
        total: (data['total'] as num?)?.toInt() ?? items.length,
        limit: (data['limit'] as num?)?.toInt() ?? limit,
        offset: (data['offset'] as num?)?.toInt() ?? offset,
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

    // Acquire Firebase ID token if logged-in
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw SubmitException('Not authenticated', statusCode: 401);
    }
    final idToken = await user.getIdToken(true);

    final resp = await http.post(
      _url('/api/cases'),
      headers: {
        'Content-Type': 'application/json',
        if (idToken != null) 'Authorization': 'Bearer $idToken',
      },
      body: jsonEncode(payload),
    );

    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      try {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        return SubmitResult(
          ok: true, // Treat any 2xx as success
          id: (data['id'] ?? data['_id'])?.toString(),
          emailSent: data['emailSent'] == true,
          message: data['message']?.toString(),
        );
      } catch (e) {
        // ignore: avoid_print
        print('[ComplaintsApi.submitComplaint] JSON parse error: $e');
        // No strict schema; still return success since server succeeded
        return SubmitResult(ok: true);
      }
    }

    String message;
    try {
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      message = data['error']?.toString() ?? 'Request failed (${resp.statusCode})';
    } catch (e) {
      // ignore: avoid_print
      print('[ComplaintsApi.submitComplaint] error JSON parse: $e');
      message = 'Request failed (${resp.statusCode})';
    }
    throw SubmitException(message, statusCode: resp.statusCode);
  }
}

class GetCasesResult {
 GetCasesResult({required this.items, required this.total, required this.limit, required this.offset});
 final List<Map<String, dynamic>> items;
 final int total;
 final int limit;
 final int offset;
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
