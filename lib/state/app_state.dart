import 'dart:math';

import 'package:flutter/material.dart';

import 'package:claimy/core/theme/app_colors.dart';
import 'dart:async';
import 'package:claimy/services/auth_service.dart';
import 'package:claimy/core/api/complaints_api.dart';

enum CaseStatus { pending, inReview, needsInfo, approved, rejected }

extension CaseStatusX on CaseStatus {
  String get label {
    switch (this) {
      case CaseStatus.pending:
        return 'Pending';
      case CaseStatus.inReview:
        return 'In review';
      case CaseStatus.needsInfo:
        return 'Need info';
      case CaseStatus.approved:
        return 'Approved';
      case CaseStatus.rejected:
        return 'Declined';
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
  }) : history = List<CaseUpdate>.from(history);

  final String id;
  final String storeName;
  final String productName;
  final DateTime createdAt;
  CaseStatus status;
  final List<CaseUpdate> history;
  bool hasUnreadUpdates;
  String? pendingQuestion;

  DateTime get lastUpdated =>
      history.isNotEmpty ? history.last.timestamp : createdAt;

  bool get requiresAdditionalInfo => pendingQuestion != null;
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
  AppState() {
    _authService = AuthService();
    _api = ComplaintsApi();
    _authSub = _authService.authStateChanges().listen((user) {
      final newVal = user != null;
      if (newVal != _isAuthenticated) {
        _isAuthenticated = newVal;
        // Immediately notify so UI can transition to HomeShell/Login
        notifyListeners();
        if (_isAuthenticated) {
          // Load cases in the background; UI is already switched
          refreshCasesFromServer();
        } else {
          _cases.clear();
        }
      }
    });
  }

  late final AuthService _authService;
  late final ComplaintsApi _api;
  StreamSubscription? _authSub;

  final List<CaseModel> _cases = [];
  final List<Voucher> _vouchers = [];
  bool _isAuthenticated = false;
  HomeLanding _landingPreference = HomeLanding.cases;

  bool get isAuthenticated => _isAuthenticated;
  HomeLanding get landingPreference => _landingPreference;

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

  Future<void> signIn({required String email, required String password}) async {
    await _authService.signInWithEmail(email: email, password: password);
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    await _authService.registerWithEmail(email: email, password: password, displayName: name);
  }

  Future<void> sendPasswordReset(String email) async {
    await _authService.sendPasswordResetEmail(email);
  }

  Future<void> signOut() async {
    await _authService.signOut();
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

  Future<void> signInWithGoogle() async {
    await _authService.signInWithGoogle();
  }

  void respondToAdditionalInfo(String id, String response) {
    final caseModel = caseById(id);
    if (caseModel == null) return;
    caseModel.pendingQuestion = null;
    caseModel.status = CaseStatus.inReview;
    caseModel.history.add(
      CaseUpdate(
        status: CaseStatus.inReview,
        message: 'You responded: $response',
        timestamp: DateTime.now(),
        isCustomerAction: true,
      ),
    );
    caseModel.hasUnreadUpdates = false;
    notifyListeners();
  }

  Future<void> refreshCasesFromServer() async {
    try {
      final result = await _api.getCases(limit: 100, offset: 0);
      _cases
        ..clear()
        ..addAll(result.items.map(_mapServerCaseToModel));
      notifyListeners();
    } catch (e) {
      // If fetch fails, keep current state; no demo data
    }
  }

  CaseModel _mapServerCaseToModel(Map<String, dynamic> m) {
    final createdAtStr = (m['createdAt'] ?? m['created_at'] ?? '') as String?;
    final createdAt = createdAtStr != null && createdAtStr.isNotEmpty
        ? DateTime.tryParse(createdAtStr) ?? DateTime.now()
        : DateTime.now();
    final statusStr = (m['status'] ?? 'PENDING').toString().toUpperCase();
    final status = _statusFromServer(statusStr);

    return CaseModel(
      id: (m['id'] ?? m['_id'] ?? '').toString(),
      storeName: (m['store'] ?? '').toString(),
      productName: (m['product'] ?? '').toString(),
      createdAt: createdAt,
      status: status,
      history: [
        CaseUpdate(
          status: status,
          message: 'Submitted',
          timestamp: createdAt,
          isCustomerAction: true,
        ),
      ],
      hasUnreadUpdates: false,
    );
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

  void toggleVoucherUsed(String id) {
    final voucher = _vouchers.firstWhere(
      (v) => v.id == id,
      orElse: () => throw ArgumentError('Voucher not found'),
    );
    voucher.used = !voucher.used;
    notifyListeners();
  }

  // Local demo-only simulation; server-driven status updates should come from backend in the future
  void simulateProgress(String id) {
    final caseModel = caseById(id);
    if (caseModel == null) return;
    final now = DateTime.now();
    CaseStatus nextStatus;
    String message;
    switch (caseModel.status) {
      case CaseStatus.pending:
        nextStatus = CaseStatus.inReview;
        message = 'A specialist started reviewing your claim.';
        break;
      case CaseStatus.inReview:
        nextStatus = CaseStatus.needsInfo;
        message = 'We need the purchase date from your receipt.';
        caseModel.pendingQuestion =
            'Could you confirm the purchase date on your receipt?';
        break;
      case CaseStatus.needsInfo:
        nextStatus = CaseStatus.approved;
        message =
            'Great news! Your claim was approved. A reward voucher is ready.';
        caseModel.pendingQuestion = null;
        _grantVoucherForCase(caseModel);
        break;
      case CaseStatus.approved:
        nextStatus = CaseStatus.rejected;
        message = 'The case was closed.';
        break;
      case CaseStatus.rejected:
        nextStatus = CaseStatus.pending;
        message = 'Case reopened for review.';
        break;
    }
    caseModel.status = nextStatus;
    caseModel.history.add(
      CaseUpdate(
        status: nextStatus,
        message: message,
        timestamp: now,
        isCustomerAction: false,
      ),
    );
    caseModel.hasUnreadUpdates = true;
    notifyListeners();
  }

  void _grantVoucherForCase(CaseModel caseModel) {
    final random = Random();
    final code = 'THANKS${random.nextInt(9999).toString().padLeft(4, '0')}';
    final voucher = Voucher(
      id: 'voucher-${DateTime.now().millisecondsSinceEpoch}',
      storeName: caseModel.storeName,
      amountLabel: '15% off your next purchase',
      code: code,
      expiration: DateTime.now().add(const Duration(days: 60)),
      used: false,
    );
    _vouchers.add(voucher);
  }
}
