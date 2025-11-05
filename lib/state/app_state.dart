import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:claimy/core/api/complaints_api.dart';
import 'package:claimy/core/localization/app_localizations.dart';
import 'package:claimy/core/theme/app_colors.dart';
import 'package:claimy/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum CaseStatus { pending, inReview, needsInfo, approved, rejected }

extension CaseStatusX on CaseStatus {
  String label(AppLocalizations l10n) {
    switch (this) {
      case CaseStatus.pending:
        return l10n.statusPending;
      case CaseStatus.inReview:
        return l10n.statusInReview;
      case CaseStatus.needsInfo:
        return l10n.statusNeedsInfo;
      case CaseStatus.approved:
        return l10n.statusApproved;
      case CaseStatus.rejected:
        return l10n.statusRejected;
    }
  }

  Color get color {
    switch (this) {
      case CaseStatus.pending:
        return AppColors.info;
      case CaseStatus.inReview:
        return const Color(0xFF7A6CFF);
      case CaseStatus.needsInfo:
        return AppColors.warning;
      case CaseStatus.approved:
        return AppColors.success;
      case CaseStatus.rejected:
        return AppColors.danger;
    }
  }

  Color get backgroundColor => fadeColor(color, 0.12);

  IconData get icon {
    switch (this) {
      case CaseStatus.pending:
        return Icons.schedule_rounded;
      case CaseStatus.inReview:
        return Icons.loop_rounded;
      case CaseStatus.needsInfo:
        return Icons.help_outline_rounded;
      case CaseStatus.approved:
        return Icons.verified_rounded;
      case CaseStatus.rejected:
        return Icons.highlight_off_rounded;
    }
  }
}

enum HomeLanding { cases, rewards }

class CaseUpdate {
  CaseUpdate({
    required this.status,
    required this.message,
    required this.timestamp,
    this.isCustomerAction = false,
  });

  final CaseStatus status;
  final String message;
  final DateTime timestamp;
  final bool isCustomerAction;
}

class InfoRequestItem {
  InfoRequestItem({
    required this.id,
    required this.message,
    required this.requiresFile,
    required this.requiresYesNo,
    required this.requestedAt,
    required this.status,
  });

  final String id;
  final String message;
  final bool requiresFile;
  final bool requiresYesNo;
  final DateTime requestedAt;
  final String status; // PENDING, ANSWERED, SUPERSEDED
}

class InfoResponseItem {
  InfoResponseItem({
    required this.id,
    required this.requestId,
    this.answer,
    this.fileUrl,
    this.fileName,
    required this.submittedAt,
  });

  final String id;
  final String requestId;
  final String? answer;
  final String? fileUrl;
  final String? fileName;
  final DateTime submittedAt;
}

class CaseModel {
  CaseModel({
    required this.id,
    required this.storeName,
    required this.productName,
    required this.createdAt,
    required this.status,
    required List<CaseUpdate> history,
    this.hasUnreadUpdates = false,
    this.pendingQuestion,
    this.productImageUrl,
    this.receiptImageUrl,
    this.requiresFile = false,
    List<InfoRequestItem>? infoRequestHistory,
    List<InfoResponseItem>? infoResponseHistory,
  }) : history = List<CaseUpdate>.from(history),
       infoRequestHistory = infoRequestHistory ?? [],
       infoResponseHistory = infoResponseHistory ?? [];

  final String id;
  final String storeName;
  final String productName;
  final DateTime createdAt;
  CaseStatus status;
  final List<CaseUpdate> history;
  bool hasUnreadUpdates;
  String? pendingQuestion;
  String? productImageUrl;
  String? receiptImageUrl;
  bool requiresFile;

  // NEW: History arrays
  final List<InfoRequestItem> infoRequestHistory;
  final List<InfoResponseItem> infoResponseHistory;

  DateTime get lastUpdated =>
      history.isNotEmpty ? history.last.timestamp : createdAt;

  bool get requiresAdditionalInfo => pendingQuestion != null;

  // Helper: Get all pending requests
  List<InfoRequestItem> get pendingRequests =>
      infoRequestHistory.where((r) => r.status == 'PENDING').toList();

  // Helper: Check if request has response
  bool hasResponse(String requestId) =>
      infoResponseHistory.any((r) => r.requestId == requestId);
}

class Voucher {
  Voucher({
    required this.id,
    required this.storeName,
    required this.amountLabel,
    required this.code,
    required this.expiration,
    this.used = false,
  });

  final String id;
  final String storeName;
  final String amountLabel;
  final String code;
  final DateTime expiration;
  bool used;
}

class AppState extends ChangeNotifier {
  static const Duration _cacheStaleAfter = Duration(minutes: 5);
  static const String _casesCacheKeyPrefix = 'app_state.cases';
  static const String _storesCacheKeyPrefix = 'app_state.stores';
  static const String _localeStorageKey = 'app_state.locale';

  AppState() {
    unawaited(_loadLocale());
    _authService = AuthService();
    _api = ComplaintsApi();
    _authSub = _authService.authStateChanges().listen((user) {
      final previousUser = _currentUser;
      _currentUser = user;
      final newVal = user != null;
      if (newVal != _isAuthenticated) {
        _isAuthenticated = newVal;
        if (_isAuthenticated) {
          // Immediately notify so UI can transition to HomeShell
          notifyListeners();
          if (user != null) {
            unawaited(_restoreCachesForUser(user.uid));
          }
          // Load cases in the background; UI is already switched
          refreshCasesFromServer();
          refreshStoresFromServer(force: true);
        } else {
          _resetCasesState();
          _clearStoresState();
          notifyListeners();
        }
      } else if (previousUser?.uid != _currentUser?.uid ||
          previousUser?.displayName != _currentUser?.displayName) {
        notifyListeners();
      }
    });
  }

  late final AuthService _authService;
  late final ComplaintsApi _api;
  StreamSubscription? _authSub;
  User? _currentUser;
  Locale _locale = const Locale('en');

  final List<CaseModel> _cases = [];
  final List<Voucher> _vouchers = [];
  final List<StoreCatalogEntry> _stores = [];
  bool _isLoadingStores = false;
  String? _storesError;
  bool _isLoadingCases = false;
  String? _casesError;
  DateTime? _casesFetchedAt;
  DateTime? _storesFetchedAt;
  bool _isAuthenticated = false;
  HomeLanding _landingPreference = HomeLanding.cases;

  bool get isAuthenticated => _isAuthenticated;
  HomeLanding get landingPreference => _landingPreference;
  Locale get locale => _locale;

  List<CaseModel> get cases {
    final sorted = [..._cases];
    sorted.sort((a, b) => b.lastUpdated.compareTo(a.lastUpdated));
    return List.unmodifiable(sorted);
  }

  List<Voucher> get vouchers {
    final sorted = [..._vouchers];
    sorted.sort(
      (a, b) => a.used == b.used
          ? a.expiration.compareTo(b.expiration)
          : (a.used ? 1 : -1),
    );
    return List.unmodifiable(sorted);
  }

  List<StoreCatalogEntry> get stores => List.unmodifiable(_stores);
  bool get isLoadingStores => _isLoadingStores;
  String? get storesError => _storesError;
  bool get isLoadingCases => _isLoadingCases;
  String? get casesError => _casesError;

  Future<void> signIn({required String email, required String password}) async {
    await _authService.signInWithEmail(email: email, password: password);
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    await _authService.registerWithEmail(
      email: email,
      password: password,
      displayName: name,
    );
  }

  Future<void> sendPasswordReset(String email) async {
    await _authService.sendPasswordResetEmail(email);
  }

  Future<void> signOut() async {
    await _authService.signOut();
    _currentUser = null;
  }

  void setLandingPreference(HomeLanding view) {
    if (_landingPreference != view) {
      _landingPreference = view;
      notifyListeners();
    }
  }

  CaseModel? caseById(String id) {
    try {
      return _cases.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  void markCaseUpdatesRead(String id) {
    final caseModel = caseById(id);
    if (caseModel != null && caseModel.hasUnreadUpdates) {
      caseModel.hasUnreadUpdates = false;
      notifyListeners();
    }
  }

  void setLocale(Locale locale) {
    if (_locale.languageCode == locale.languageCode) {
      return;
    }
    _locale = locale;
    notifyListeners();
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString(_localeStorageKey, locale.languageCode);
    }).catchError((_) {
      // ignore persistence errors
    });
  }

  Future<void> signInWithGoogle() async {
    await _authService.signInWithGoogle();
  }

  String get greetingName {
    final displayName = _currentUser?.displayName?.trim();
    if (displayName != null && displayName.isNotEmpty) {
      return displayName.split(' ').first;
    }
    final email = _currentUser?.email?.trim();
    if (email != null && email.isNotEmpty) {
      return email.split('@').first;
    }
    return 'there';
  }

  Future<void> respondToAdditionalInfoServer(
    String id, {
    String? requestId,
    required String response,
    Uint8List? attachment,
  }) async {
    final caseModel = caseById(id);
    if (caseModel == null) return;
    try {
      await _api.submitInfoResponse(
        caseId: id,
        requestId: requestId,
        answer: response,
        attachmentBytes: attachment,
      );
      await refreshCasesFromServer();
    } catch (_) {
      // optionally show error
    }
  }

  void _resetCasesState() {
    _cases.clear();
    _casesError = null;
    _isLoadingCases = false;
  }

  void _clearStoresState() {
    _stores.clear();
    _storesError = null;
    _isLoadingStores = false;
  }

  Future<void> refreshStoresFromServer({bool force = false}) async {
    if (!_isAuthenticated) {
      final hadData =
          _stores.isNotEmpty || _storesError != null || _isLoadingStores;
      _clearStoresState();
      if (hadData) {
        notifyListeners();
      }
      return;
    }

    if (_isLoadingStores) {
      return;
    }

    if (!force && _stores.isNotEmpty) {
      final isStale =
          _storesFetchedAt == null ||
          DateTime.now().difference(_storesFetchedAt!) > _cacheStaleAfter;
      if (!isStale) {
        return;
      }
    }

    _isLoadingStores = true;
    _storesError = null;
    notifyListeners();

    try {
      final results = await _api.getStoreCatalog();
      _stores
        ..clear()
        ..addAll(results);
      _storesError = null;
      final fetchedAt = DateTime.now();
      _storesFetchedAt = fetchedAt;
      final userId = _currentUser?.uid;
      if (userId != null) {
        unawaited(_saveStoresToCache(userId, results, fetchedAt));
      }
    } catch (e) {
      _storesError = e.toString();
    } finally {
      _isLoadingStores = false;
      notifyListeners();
    }
  }

  Future<void> refreshCasesFromServer() async {
    if (!_isAuthenticated) {
      final hadData =
          _cases.isNotEmpty || _casesError != null || _isLoadingCases;
      _resetCasesState();
      if (hadData) {
        notifyListeners();
      }
      return;
    }

    if (_isLoadingCases) {
      return;
    }

    _isLoadingCases = true;
    _casesError = null;
    notifyListeners();

    try {
      final result = await _api.getCases(limit: 100, offset: 0);
      _cases
        ..clear()
        ..addAll(result.items.map(_mapServerCaseToModel));
      
      // Extract vouchers from approved cases
      _extractVouchersFromCases(result.items);
      
      _casesError = null;
      final fetchedAt = DateTime.now();
      _casesFetchedAt = fetchedAt;
      final userId = _currentUser?.uid;
      if (userId != null) {
        unawaited(_saveCasesToCache(userId, result.items, fetchedAt));
      }
    } catch (e) {
      _casesError = e.toString();
    } finally {
      _isLoadingCases = false;
      notifyListeners();
    }
  }

  void _extractVouchersFromCases(List<Map<String, dynamic>> rawCases) {
    _vouchers.clear();
    
    for (final caseData in rawCases) {
      final statusStr = (caseData['status'] ?? '').toString().toUpperCase();
      if (statusStr != 'APPROVED') continue;
      
      final resolution = caseData['resolution'];
      if (resolution == null || resolution is! Map) continue;
      
      final code = resolution['code']?.toString();
      if (code == null || code.isEmpty) continue;
      
      final expiryStr = resolution['expiryDate']?.toString();
      if (expiryStr == null || expiryStr.isEmpty) continue;
      
      final expiry = DateTime.tryParse(expiryStr);
      if (expiry == null) continue;
      
      final caseId = (caseData['id'] ?? caseData['_id'] ?? '').toString();
      final storeName = (caseData['store'] ?? caseData['storeName'] ?? 'Store').toString();
      final productName = (caseData['product'] ?? caseData['productName'] ?? 'Product').toString();
      
      // Check if voucher is already marked as used (we'll store this in resolution)
      final used = resolution['used'] == true;
      
      _vouchers.add(
        Voucher(
          id: caseId,
          storeName: storeName,
          amountLabel: productName,
          code: code,
          expiration: expiry,
          used: used,
        ),
      );
    }
  }

  Future<void> _saveCasesToCache(
    String uid,
    List<Map<String, dynamic>> rawCases,
    DateTime timestamp,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_casesCacheKey(uid), jsonEncode(rawCases));
      await prefs.setInt(
        _casesCacheTimestampKey(uid),
        timestamp.millisecondsSinceEpoch,
      );
    } catch (_) {
      // Ignore caching errors; fresh data will still be shown.
    }
  }

  Future<void> _saveStoresToCache(
    String uid,
    List<StoreCatalogEntry> stores,
    DateTime timestamp,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final payload = stores.map((s) => s.toJson()).toList(growable: false);
      await prefs.setString(_storesCacheKey(uid), jsonEncode(payload));
      await prefs.setInt(
        _storesCacheTimestampKey(uid),
        timestamp.millisecondsSinceEpoch,
      );
    } catch (_) {
      // Ignore caching errors; fresh data will still be shown.
    }
  }

  Future<void> _loadLocale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString(_localeStorageKey);
      if (stored != null && stored.isNotEmpty && stored != _locale.languageCode) {
        _locale = Locale(stored);
        notifyListeners();
      }
    } catch (_) {
      // Ignore locale restore failures; defaults will apply.
    }
  }

  Future<void> _restoreCachesForUser(String uid) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      bool updated = false;

      final casesJson = prefs.getString(_casesCacheKey(uid));
      final casesTimestamp = prefs.getInt(_casesCacheTimestampKey(uid));
      _casesFetchedAt = casesTimestamp != null
          ? DateTime.fromMillisecondsSinceEpoch(casesTimestamp)
          : null;
      if (casesJson != null && casesJson.isNotEmpty) {
        final decoded = jsonDecode(casesJson);
        if (decoded is List) {
          final rawCases = <Map<String, dynamic>>[];
          for (final item in decoded) {
            if (item is Map) {
              rawCases.add(Map<String, dynamic>.from(item));
            }
          }
          if (rawCases.isNotEmpty) {
            _cases
              ..clear()
              ..addAll(rawCases.map(_mapServerCaseToModel));
            
            // Extract vouchers from cached cases
            _extractVouchersFromCases(rawCases);
            
            _casesError = null;
            updated = true;
          }
        }
      }

      final storesJson = prefs.getString(_storesCacheKey(uid));
      final storesTimestamp = prefs.getInt(_storesCacheTimestampKey(uid));
      _storesFetchedAt = storesTimestamp != null
          ? DateTime.fromMillisecondsSinceEpoch(storesTimestamp)
          : null;
      if (storesJson != null && storesJson.isNotEmpty) {
        final decoded = jsonDecode(storesJson);
        if (decoded is List) {
          final restoredStores = <StoreCatalogEntry>[];
          for (final item in decoded) {
            if (item is Map) {
              final entry = StoreCatalogEntry.fromJson(
                Map<String, dynamic>.from(item),
              );
              if (entry.storeId.isNotEmpty && entry.name.isNotEmpty) {
                restoredStores.add(entry);
              }
            }
          }
          if (restoredStores.isNotEmpty) {
            _stores
              ..clear()
              ..addAll(restoredStores);
            _storesError = null;
            updated = true;
          }
        }
      }

      if (updated) {
        notifyListeners();
      }
    } catch (_) {
      // Ignore cache restore failures; live fetch will populate data shortly.
    }
  }

  String _casesCacheKey(String uid) => '$_casesCacheKeyPrefix.$uid.data';

  String _casesCacheTimestampKey(String uid) => '$_casesCacheKeyPrefix.$uid.ts';

  String _storesCacheKey(String uid) => '$_storesCacheKeyPrefix.$uid.data';

  String _storesCacheTimestampKey(String uid) =>
      '$_storesCacheKeyPrefix.$uid.ts';

  CaseModel _mapServerCaseToModel(Map<String, dynamic> m) {
    final createdAtStr = (m['createdAt'] ?? m['created_at'] ?? '') as String?;
    final createdAt = createdAtStr != null && createdAtStr.isNotEmpty
        ? DateTime.tryParse(createdAtStr) ?? DateTime.now()
        : DateTime.now();
    final statusStr = (m['status'] ?? 'PENDING').toString().toUpperCase();
    final status = _statusFromServer(statusStr);
    final infoReq = (m['infoRequest'] is Map)
        ? (m['infoRequest'] as Map)
        : null;
    final pendingQuestionServer = (status == CaseStatus.needsInfo)
        ? (infoReq?['message']?.toString() ?? '')
        : '';
    final requiresFileServer = (infoReq?['requiresFile'] == true);

    final productImageUrl = (m['productImageUrl'] ?? m['product_image_url'])
        ?.toString();
    final images = (m['images'] as List?)?.cast<dynamic>() ?? const [];

    // NEW: Parse info request history
    final List<dynamic> rawInfoRequestHistory =
        (m['infoRequestHistory'] is List)
        ? (m['infoRequestHistory'] as List)
        : const [];
    final List<InfoRequestItem> infoRequestHistory = rawInfoRequestHistory
        .whereType<Map>()
        .map((entry) {
          final id = (entry['id'] ?? '').toString();
          final message = (entry['message'] ?? '').toString();
          final requiresFile = entry['requiresFile'] == true;
          final requiresYesNo = entry['requiresYesNo'] == true;
          final requestedAtStr = (entry['requestedAt'] ?? '').toString();
          final requestedAt = requestedAtStr.isNotEmpty
              ? (DateTime.tryParse(requestedAtStr) ?? DateTime.now())
              : DateTime.now();
          final status = (entry['status'] ?? 'PENDING').toString();
          return InfoRequestItem(
            id: id,
            message: message,
            requiresFile: requiresFile,
            requiresYesNo: requiresYesNo,
            requestedAt: requestedAt,
            status: status,
          );
        })
        .toList();

    // NEW: Parse info response history
    final List<dynamic> rawInfoResponseHistory =
        (m['infoResponseHistory'] is List)
        ? (m['infoResponseHistory'] as List)
        : const [];
    final List<InfoResponseItem> infoResponseHistory = rawInfoResponseHistory
        .whereType<Map>()
        .map((entry) {
          final id = (entry['id'] ?? '').toString();
          final requestId = (entry['requestId'] ?? '').toString();
          final answer = entry['answer']?.toString();
          final fileUrl = entry['fileUrl']?.toString();
          final fileName = entry['fileName']?.toString();
          final submittedAtStr = (entry['submittedAt'] ?? '').toString();
          final submittedAt = submittedAtStr.isNotEmpty
              ? (DateTime.tryParse(submittedAtStr) ?? DateTime.now())
              : DateTime.now();
          return InfoResponseItem(
            id: id,
            requestId: requestId,
            answer: answer,
            fileUrl: fileUrl,
            fileName: fileName,
            submittedAt: submittedAt,
          );
        })
        .toList();

    // Map backend statusHistory into our CaseUpdate timeline
    final List<dynamic> rawHistory = (m['statusHistory'] is List)
        ? (m['statusHistory'] as List)
        : const [];

    List<CaseUpdate> timeline = rawHistory.whereType<Map>().map((entry) {
      final statusRaw = (entry['status'] ?? '').toString().toUpperCase();
      final s = _statusFromServer(statusRaw);
      final note = (entry['note'] ?? '').toString();
      final atStr = (entry['at'] ?? entry['timestamp'] ?? '').toString();
      final at = atStr.isNotEmpty
          ? (DateTime.tryParse(atStr) ?? createdAt)
          : createdAt;
      final msg = _statusMessageForTimeline(s, note);
      return CaseUpdate(
        status: s,
        message: msg,
        timestamp: at,
        isCustomerAction: false,
      );
    }).toList()..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    // Ensure there's an initial submitted entry at createdAt
    final hasSubmitted = timeline.any((e) => e.status == CaseStatus.pending);
    if (!hasSubmitted) {
      timeline.insert(
        0,
        CaseUpdate(
          status: CaseStatus.pending,
          message: 'Submitted',
          timestamp: createdAt,
          isCustomerAction: true,
        ),
      );
    }

    return CaseModel(
      id: (m['id'] ?? m['_id'] ?? '').toString(),
      storeName: (m['store'] ?? '').toString(),
      productName: (m['product'] ?? '').toString(),
      createdAt: createdAt,
      status: status,
      history: timeline,
      hasUnreadUpdates: false,
      productImageUrl: productImageUrl?.isNotEmpty == true
          ? productImageUrl
          : (images.isNotEmpty ? images.first?.toString() : null),
      receiptImageUrl:
          ((m['receiptImageUrl'] ?? m['receipt_image_url'])
                  ?.toString()
                  .isNotEmpty ??
              false)
          ? (m['receiptImageUrl'] ?? m['receipt_image_url']).toString()
          : (images.length > 1 ? images[1]?.toString() : null),
      pendingQuestion: pendingQuestionServer.isNotEmpty
          ? pendingQuestionServer
          : null,
      requiresFile: requiresFileServer,
      infoRequestHistory: infoRequestHistory,
      infoResponseHistory: infoResponseHistory,
    );
  }

  String _statusMessageForTimeline(CaseStatus status, String note) {
    final hasNote = note.trim().isNotEmpty;
    switch (status) {
      case CaseStatus.pending:
        return 'Submitted';
      case CaseStatus.inReview:
        return hasNote ? note : 'We\'re reviewing your claim';
      case CaseStatus.needsInfo:
        return hasNote ? note : 'We\'ve requested additional info';
      case CaseStatus.approved:
        return hasNote ? note : 'Approved';
      case CaseStatus.rejected:
        return hasNote ? note : 'Declined';
    }
  }

  CaseStatus _statusFromServer(String value) {
    switch (value) {
      case 'IN_REVIEW':
        return CaseStatus.inReview;
      case 'NEED_INFO':
        return CaseStatus.needsInfo;
      case 'APPROVED':
        return CaseStatus.approved;
      case 'REJECTED':
        return CaseStatus.rejected;
      case 'PENDING':
      default:
        return CaseStatus.pending;
    }
  }

  Future<void> createCase({
    required String storeName,
    required String productName,
    required String description,
    required bool includedProductPhoto,
    required bool includedReceiptPhoto,
    bool alreadySubmitted = false,
  }) async {
    // If the caller already submitted to backend, just refresh
    if (alreadySubmitted) {
      await refreshCasesFromServer();
      return;
    }

    // Otherwise, call backend to persist the case for the logged-in user
    try {
      final api = ComplaintsApi();
      await api.submitComplaint(
        store: storeName,
        product: productName,
        description: description,
        images: [
          if (includedProductPhoto) 'product://photo',
          if (includedReceiptPhoto) 'receipt://photo',
        ],
      );
      await refreshCasesFromServer();
    } catch (e) {
      // On failure, do not create local mock data
    }
  }

  Future<void> toggleVoucherUsed(String id) async {
    final voucher = _vouchers.firstWhere(
      (v) => v.id == id,
      orElse: () => throw ArgumentError('Voucher not found'),
    );
    
    // Toggle locally first for instant UI feedback
    final newUsedState = !voucher.used;
    voucher.used = newUsedState;
    notifyListeners();
    
    // Persist to server
    try {
      await _api.updateVoucherUsedStatus(caseId: id, used: newUsedState);
    } catch (e) {
      // Revert on error
      voucher.used = !newUsedState;
      notifyListeners();
      // Could show error to user here
    }
  }
}
