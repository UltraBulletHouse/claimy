import 'dart:async';
import 'dart:convert';

import 'package:claimy/core/api/complaints_api.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;

typedef CaseNotificationHandler = Future<void> Function(String caseId);

class PushNotificationsService {
  PushNotificationsService({http.Client? httpClient})
    : _client = httpClient ?? http.Client();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final http.Client _client;

  final _caseLinkController = StreamController<String>.broadcast();
  Stream<String> get caseLinks => _caseLinkController.stream;

  CaseNotificationHandler? _caseUpdateHandler;
  StreamSubscription<String>? _tokenRefreshSub;
  User? _currentUser;
  bool _initialized = false;

  static const AndroidNotificationChannel _androidChannel =
      AndroidNotificationChannel(
        'case_status_updates',
        'Case status updates',
        description: 'Realtime alerts when your case status changes.',
        importance: Importance.high,
      );

  bool get _isSupportedPlatform {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }
    _initialized = true;

    if (!_isSupportedPlatform) {
      return;
    }

    await _messaging.setAutoInitEnabled(true);
    await _requestPermissions();
    await _setupLocalNotifications();
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    FirebaseMessaging.onMessage.listen((message) {
      unawaited(
        _handleIncomingMessage(message, showForegroundNotification: true),
      );
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _handleNotificationTap(message);
      unawaited(_notifyCaseHandler(message));
    });

    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
      await _notifyCaseHandler(initialMessage);
    }
  }

  void registerCaseUpdateHandler(CaseNotificationHandler handler) {
    _caseUpdateHandler = handler;
  }

  Future<void> onUserAuthenticated(User user) async {
    if (!_isSupportedPlatform) return;
    _currentUser = user;
    await _syncFcmToken();
    await _tokenRefreshSub?.cancel();
    _tokenRefreshSub = _messaging.onTokenRefresh.listen((token) {
      unawaited(_syncFcmToken(tokenOverride: token));
    });
  }

  Future<void> onUserSignedOut() async {
    await _tokenRefreshSub?.cancel();
    _tokenRefreshSub = null;
    _currentUser = null;
  }

  Future<void> _requestPermissions() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      debugPrint('Push notifications permission denied.');
    }
  }

  Future<void> _setupLocalNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iOSInit = DarwinInitializationSettings();
    final initSettings = InitializationSettings(
      android: androidInit,
      iOS: iOSInit,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        final payload = details.payload;
        if (payload != null && payload.isNotEmpty) {
          _caseLinkController.add(payload);
        }
      },
    );

    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidPlugin?.createNotificationChannel(_androidChannel);
  }

  Future<void> _handleIncomingMessage(
    RemoteMessage message, {
    required bool showForegroundNotification,
  }) async {
    await _notifyCaseHandler(message);
    if (showForegroundNotification) {
      await _showLocalNotification(message);
    }
  }

  Future<void> _notifyCaseHandler(RemoteMessage message) async {
    final caseId = _extractCaseId(message);
    if (caseId == null || caseId.isEmpty) {
      return;
    }
    if (_caseUpdateHandler != null) {
      await _caseUpdateHandler!(caseId);
    }
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    final title = notification?.title ?? message.data['title'] ?? 'Case update';
    final body =
        notification?.body ??
        message.data['body'] ??
        'One of your cases changed status.';
    final caseId = _extractCaseId(message);

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _androidChannel.id,
        _androidChannel.name,
        channelDescription: _androidChannel.description,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: const DarwinNotificationDetails(),
    );

    await _localNotifications.show(
      message.hashCode,
      title,
      body,
      details,
      payload: caseId,
    );
  }

  void _handleNotificationTap(RemoteMessage message) {
    final caseId = _extractCaseId(message);
    if (caseId == null || caseId.isEmpty) {
      return;
    }
    _caseLinkController.add(caseId);
  }

  String? _extractCaseId(RemoteMessage message) {
    return message.data['caseId'] ?? message.data['caseID'];
  }

  Future<void> _syncFcmToken({String? tokenOverride}) async {
    final user = _currentUser;
    if (user == null) return;
    final token = tokenOverride ?? await _messaging.getToken();
    if (token == null) return;

    try {
      final idToken = await user.getIdToken(true);
      final endpoint = Uri.parse(
        '${ComplaintsApi.resolveBaseUrl()}/api/graphql',
      );
      final response = await _client.post(
        endpoint,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode({
          'query':
              'mutation UpdateFcmToken(\$token: String!) { updateFcmToken(token: \$token) { id } }',
          'variables': {'token': token},
        }),
      );

      if (response.statusCode >= 400) {
        debugPrint(
          'Failed to sync FCM token (${response.statusCode}): ${response.body}',
        );
      }
    } catch (error) {
      debugPrint('Failed to sync FCM token: $error');
    }
  }
}
