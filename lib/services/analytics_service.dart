import 'dart:io';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_analytics/observer.dart';
import 'package:flutter/material.dart';

/// Singleton service for Firebase Analytics
class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  FirebaseAnalytics? _analytics;
  FirebaseAnalyticsObserver? _observer;
  bool _initialized = false;

  /// Initialize Firebase Analytics
  Future<void> init() async {
    try {
      // Firebase Analytics is not supported on Windows/Linux/macOS
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        debugPrint('Firebase Analytics not available on this platform');
        _initialized = false;
        return;
      }

      _analytics = FirebaseAnalytics.instance;
      _observer = FirebaseAnalyticsObserver(analytics: _analytics!);

      // Enable analytics collection
      await _analytics?.setAnalyticsCollectionEnabled(true);
      _initialized = true;
    } catch (e) {
      debugPrint('Analytics initialization error: $e');
      _initialized = false;
    }
  }

  /// Get Firebase Analytics instance
  FirebaseAnalytics? get analytics => _analytics;

  /// Get Firebase Analytics Observer
  FirebaseAnalyticsObserver? get observer => _observer;

  /// Check if analytics is initialized
  bool get isInitialized => _initialized;

  /// Track login event
  Future<void> trackLogin(String method) async {
    if (_analytics == null) return;
    try {
      await _analytics?.logLogin(loginMethod: method);
    } catch (e) {
      debugPrint('Analytics login error: $e');
    }
  }

  /// Track signup event
  Future<void> trackSignUp(String method) async {
    if (_analytics == null) return;
    try {
      await _analytics?.logSignUp(signUpMethod: method);
    } catch (e) {
      debugPrint('Analytics signup error: $e');
    }
  }

  /// Track VPN connection event
  Future<void> trackVpnConnection({
    required String protocol,
    required String serverLocation,
    bool success = true,
  }) async {
    if (_analytics == null) return;
    try {
      await _analytics?.logEvent(
        name: 'vpn_connection',
        parameters: <String, Object>{
          'protocol': protocol,
          'server_location': serverLocation,
          'success': success,
        },
      );
    } catch (e) {
      debugPrint('Analytics VPN connection error: $e');
    }
  }

  /// Track VPN disconnection event
  Future<void> trackVpnDisconnection({
    required String protocol,
    required String serverLocation,
  }) async {
    if (_analytics == null) return;
    try {
      await _analytics?.logEvent(
        name: 'vpn_disconnection',
        parameters: <String, Object>{
          'protocol': protocol,
          'server_location': serverLocation,
        },
      );
    } catch (e) {
      debugPrint('Analytics VPN disconnection error: $e');
    }
  }

  /// Track payment button click
  Future<void> trackPaymentClick(String planName) async {
    if (_analytics == null) return;
    try {
      await _analytics?.logEvent(
        name: 'payment_button_click',
        parameters: <String, Object>{'plan_name': planName},
      );
    } catch (e) {
      debugPrint('Analytics payment click error: $e');
    }
  }

  /// Track purchase event
  Future<void> trackPurchase({
    required String planName,
    required String price,
    required String currency,
  }) async {
    if (_analytics == null) return;
    try {
      await _analytics?.logEvent(
        name: 'purchase',
        parameters: <String, Object>{
          'plan_name': planName,
          'price': price,
          'currency': currency,
        },
      );
    } catch (e) {
      debugPrint('Analytics purchase error: $e');
    }
  }

  /// Track premium upgrade
  Future<void> trackPremiumUpgrade({
    required String planName,
    required String price,
  }) async {
    if (_analytics == null) return;
    try {
      await _analytics?.logEvent(
        name: 'premium_upgrade',
        parameters: <String, Object>{'plan_name': planName, 'price': price},
      );
    } catch (e) {
      debugPrint('Analytics premium upgrade error: $e');
    }
  }

  /// Track screen view
  Future<void> trackScreen(String screenName) async {
    if (_analytics == null) return;
    try {
      await _analytics?.logScreenView(screenName: screenName);
    } catch (e) {
      debugPrint('Analytics screen view error: $e');
    }
  }

  /// Track user property
  Future<void> setUserProperty(String name, String? value) async {
    if (_analytics == null) return;
    try {
      await _analytics?.setUserProperty(name: name, value: value);
    } catch (e) {
      debugPrint('Analytics set user property error: $e');
    }
  }

  /// Track custom event
  Future<void> trackEvent(
    String name, {
    Map<String, Object>? parameters,
  }) async {
    if (_analytics == null) return;
    try {
      await _analytics?.logEvent(name: name, parameters: parameters);
    } catch (e) {
      debugPrint('Analytics custom event error: $e');
    }
  }

  /// Set user ID
  Future<void> setUserId(String? userId) async {
    if (_analytics == null) return;
    try {
      await _analytics?.setUserId(id: userId);
    } catch (e) {
      debugPrint('Analytics set user ID error: $e');
    }
  }

  /// Set analytics collection enabled
  Future<void> setAnalyticsCollectionEnabled(bool enabled) async {
    if (_analytics == null) return;
    try {
      await _analytics?.setAnalyticsCollectionEnabled(enabled);
    } catch (e) {
      debugPrint('Analytics set collection enabled error: $e');
    }
  }

  /// Set session timeout duration
  Future<void> setSessionTimeoutDuration(Duration duration) async {
    if (_analytics == null) return;
    try {
      await _analytics?.setSessionTimeoutDuration(duration);
    } catch (e) {
      debugPrint('Analytics set session timeout error: $e');
    }
  }

  /// Reset analytics data
  Future<void> resetAnalyticsData() async {
    if (_analytics == null) return;
    try {
      await _analytics?.resetAnalyticsData();
    } catch (e) {
      debugPrint('Analytics reset data error: $e');
    }
  }
}
