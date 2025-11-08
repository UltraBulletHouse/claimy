import 'dart:convert';
import 'dart:io' show Platform;
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

class ComplaintsApi {
  ComplaintsApi({String? baseUrl}) : _baseUrl = baseUrl ?? _detectBaseUrl();

  // Fetch only the current user's cases
  Future<GetCasesResult> getCases({
    int limit = 50,
    int offset = 0,
    String sort = '-createdAt',
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw SubmitException('Not authenticated', statusCode: 401);
    }
    final idToken = await user.getIdToken(true);

    final resp = await http.get(
      _url(
        '/cases?limit=$limit&offset=$offset&sort=${Uri.encodeQueryComponent(sort)}',
      ),
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
      message =
          data['error']?.toString() ?? 'Request failed (${resp.statusCode})';
    } catch (_) {
      message = 'Request failed (${resp.statusCode})';
    }
    throw SubmitException(message, statusCode: resp.statusCode);
  }

  final String _baseUrl;

  Future<List<StoreCatalogEntry>> getStoreCatalog() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw SubmitException('Not authenticated', statusCode: 401);
    }
    final idToken = await user.getIdToken(true);

    final resp = await http.get(
      _url('/stores'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
    );

    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      final decoded = jsonDecode(resp.body) as Map<String, dynamic>;
      final rawItems = decoded['items'];
      final List<StoreCatalogEntry> stores = [];
      if (rawItems is List) {
        for (final item in rawItems) {
          if (item is Map<String, dynamic>) {
            final storeId = item['storeId']?.toString();
            final name = item['name']?.toString();
            final primaryColor = item['primaryColor']?.toString();
            final secondaryColorRaw = item['secondaryColor']?.toString();
            final email = item['email']?.toString();
            if (storeId != null &&
                name != null &&
                primaryColor != null &&
                email != null &&
                storeId.isNotEmpty &&
                name.isNotEmpty &&
                primaryColor.isNotEmpty &&
                email.isNotEmpty) {
              final secondaryColor =
                  (secondaryColorRaw != null && secondaryColorRaw.isNotEmpty)
                  ? secondaryColorRaw
                  : primaryColor;
              stores.add(
                StoreCatalogEntry(
                  storeId: storeId,
                  name: name,
                  primaryColor: primaryColor,
                  secondaryColor: secondaryColor,
                  email: email,
                ),
              );
            }
          }
        }
      }
      return stores;
    }

    String message;
    try {
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      message =
          data['error']?.toString() ?? 'Request failed (${resp.statusCode})';
    } catch (_) {
      message = 'Request failed (${resp.statusCode})';
    }
    throw SubmitException(message, statusCode: resp.statusCode);
  }

  static String _detectBaseUrl() {
    const env = String.fromEnvironment('CLAIMY_API_BASE');
    if (env.isNotEmpty) return env;

    const useLocal = bool.fromEnvironment('CLAIMY_USE_LOCAL_API');
    if (useLocal) return _localBaseUrl();

    return _productionBaseUrl;
  }

  static String _localBaseUrl() {
    if (_isAndroid) return 'http://10.0.2.2:3000';
    return 'http://localhost:3000';
  }

  static const String _productionBaseUrl = 'https://claimy-backend.vercel.app';

  static String resolveBaseUrl() {
    return _detectBaseUrl();
  }

  static bool get _isAndroid {
    try {
      return Platform.isAndroid;
    } catch (_) {
      return false;
    }
  }

  Uri _url(String path) => Uri.parse('$_baseUrl/api/public$path');

  Future<void> updateVoucherUsedStatus({
    required String caseId,
    required bool used,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw SubmitException('Not authenticated', statusCode: 401);
    }
    final idToken = await user.getIdToken(true);

    final resp = await http.patch(
      _url('/cases/$caseId/voucher-used'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
      body: jsonEncode({'used': used}),
    );

    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw SubmitException(
        'Request failed (${resp.statusCode})',
        statusCode: resp.statusCode,
      );
    }
  }

  Future<void> submitInfoResponse({
    required String caseId,
    String? requestId,
    String? answer,
    Uint8List? attachmentBytes,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw SubmitException('Not authenticated', statusCode: 401);
    }
    final idToken = await user.getIdToken(true);
    final url = _url('/cases/$caseId/info-response');

    if (attachmentBytes != null) {
      final request = http.MultipartRequest('POST', url);
      request.headers['Authorization'] = 'Bearer $idToken';
      if (requestId != null && requestId.trim().isNotEmpty) {
        request.fields['requestId'] = requestId.trim();
      }
      if (answer != null && answer.trim().isNotEmpty) {
        request.fields['answer'] = answer.trim();
      }
      request.files.add(
        http.MultipartFile.fromBytes(
          'attachment',
          attachmentBytes,
          filename: 'attachment.jpg',
        ),
      );
      final streamed = await request.send();
      final resp = await http.Response.fromStream(streamed);
      if (resp.statusCode < 200 || resp.statusCode >= 300) {
        throw SubmitException(
          'Request failed (${resp.statusCode})',
          statusCode: resp.statusCode,
        );
      }
    } else {
      final body = <String, dynamic>{};
      if (requestId != null && requestId.trim().isNotEmpty) {
        body['requestId'] = requestId.trim();
      }
      if (answer != null && answer.trim().isNotEmpty) {
        body['answer'] = answer.trim();
      }
      final resp = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode(body),
      );
      if (resp.statusCode < 200 || resp.statusCode >= 300) {
        throw SubmitException(
          'Request failed (${resp.statusCode})',
          statusCode: resp.statusCode,
        );
      }
    }
  }

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
      _url('/cases'),
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
      message =
          data['error']?.toString() ?? 'Request failed (${resp.statusCode})';
    } catch (e) {
      // ignore: avoid_print
      print('[ComplaintsApi.submitComplaint] error JSON parse: $e');
      message = 'Request failed (${resp.statusCode})';
    }
    throw SubmitException(message, statusCode: resp.statusCode);
  }
}

class GetCasesResult {
  GetCasesResult({
    required this.items,
    required this.total,
    required this.limit,
    required this.offset,
  });
  final List<Map<String, dynamic>> items;
  final int total;
  final int limit;
  final int offset;
}

class StoreCatalogEntry {
  StoreCatalogEntry({
    required this.storeId,
    required this.name,
    required this.primaryColor,
    required this.secondaryColor,
    required this.email,
  });

  final String storeId;
  final String name;
  final String primaryColor;
  final String secondaryColor;
  final String email;

  factory StoreCatalogEntry.fromJson(Map<String, dynamic> json) {
    return StoreCatalogEntry(
      storeId: (json['storeId'] ?? json['store_id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      primaryColor: (json['primaryColor'] ?? json['primary_color'] ?? '')
          .toString(),
      secondaryColor: (json['secondaryColor'] ?? json['secondary_color'] ?? '')
          .toString(),
      email: (json['email'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'storeId': storeId,
    'name': name,
    'primaryColor': primaryColor,
    'secondaryColor': secondaryColor,
    'email': email,
  };
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
