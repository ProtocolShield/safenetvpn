import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_analytics/observer.dart';
import 'package:flutter/material.dart';

/// Singleton service for Firebase Analytics
class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  late FirebaseAnalytics _analytics;
  late FirebaseAnalyticsObserver _observer;

  /// Initialize Firebase Analytics
  Future<void> init() async {
    _analytics = FirebaseAnalytics.instance;
    _observer = FirebaseAnalyticsObserver(analytics: _analytics);

    // Enable analytics collection
    await _analytics.setAnalyticsCollectionEnabled(true);
  }

  /// Get Firebase Analytics instance
  FirebaseAnalytics get analytics => _analytics;

  /// Get Firebase Analytics Observer
  FirebaseAnalyticsObserver get observer => _observer;

  /// Track login event
  Future<void> trackLogin(String method) async {
    try {
      await _analytics.logLogin(loginMethod: method);
    } catch (e) {
      debugPrint('Analytics login error: $e');
    }
  }

  /// Track signup event
  Future<void> trackSignUp(String method) async {
    try {
      await _analytics.logSignUp(signUpMethod: method);
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
    try {
      await _analytics.logEvent(
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
    try {
      await _analytics.logEvent(
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
    try {
      await _analytics.logEvent(
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
    try {
      await _analytics.logEvent(
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
    try {
      await _analytics.logEvent(
        name: 'premium_upgrade',
        parameters: <String, Object>{'plan_name': planName, 'price': price},
      );
    } catch (e) {
      debugPrint('Analytics premium upgrade error: $e');
    }
  }

  /// Track screen view
  Future<void> trackScreen(String screenName) async {
    try {
      await _analytics.logScreenView(screenName: screenName);
    } catch (e) {
      debugPrint('Analytics screen view error: $e');
    }
  }

  /// Track user property
  Future<void> setUserProperty(String name, String? value) async {
    try {
      await _analytics.setUserProperty(name: name, value: value);
    } catch (e) {
      debugPrint('Analytics set user property error: $e');
    }
  }

  /// Track custom event
  Future<void> trackEvent(
    String name, {
    Map<String, Object>? parameters,
  }) async {
    try {
      await _analytics.logEvent(name: name, parameters: parameters);
    } catch (e) {
      debugPrint('Analytics custom event error: $e');
    }
  }

  /// Set user ID
  Future<void> setUserId(String? userId) async {
    try {
      await _analytics.setUserId(id: userId);
    } catch (e) {
      debugPrint('Analytics set user ID error: $e');
    }
  }

  /// Set analytics collection enabled
  Future<void> setAnalyticsCollectionEnabled(bool enabled) async {
    try {
      await _analytics.setAnalyticsCollectionEnabled(enabled);
    } catch (e) {
      debugPrint('Analytics set collection enabled error: $e');
    }
  }

  /// Set session timeout duration
  Future<void> setSessionTimeoutDuration(Duration duration) async {
    try {
      await _analytics.setSessionTimeoutDuration(duration);
    } catch (e) {
      debugPrint('Analytics set session timeout error: $e');
    }
  }

  /// Reset analytics data
  Future<void> resetAnalyticsData() async {
    try {
      await _analytics.resetAnalyticsData();
    } catch (e) {
      debugPrint('Analytics reset data error: $e');
    }
  }
}
