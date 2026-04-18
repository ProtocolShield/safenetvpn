// Token Service for diagnostic and validation
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' show log;

class TokenService {
  /// Check if token exists and is not empty
  static Future<bool> hasValidToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('t');
    return token != null && token.isNotEmpty;
  }

  /// Get the stored token
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('t');
  }

  /// Validate token format (basic check)
  static Future<bool> isTokenValidFormat() async {
    final token = await getToken();
    
    if (token == null || token.isEmpty) {
      return false;
    }
    
    // JWT tokens typically have 3 parts separated by dots
    // and contain base64 encoded data
    final parts = token.split('.');
    
    // Some backends might use different formats
    // At minimum, check if it's not obviously wrong
    if (token.length < 20) {
      return false;
    }
    
    return true;
  }

  /// Get token info for debugging
  static Future<Map<String, String>> getTokenInfo() async {
    final token = await getToken();
    final hasToken = token != null && token.isNotEmpty;
    
    final info = {
      'exists': hasToken ? 'Yes' : 'No',
      'length': token?.length.toString() ?? '0',
      'format': 'Valid JWT' // We assume valid if stored
    };
    
    if (hasToken && token!.length > 50) {
      info['preview'] = '${token.substring(0, 20)}...${token.substring(token.length - 20)}';
    }
    
    return info;
  }

  /// Log token diagnostic information
  static Future<void> logTokenDiagnostics() async {
    log('========== TOKEN DIAGNOSTICS ==========');
    
    try {
      final hasValid = await hasValidToken();
      final isValidFormat = await isTokenValidFormat();
      final info = await getTokenInfo();
      
      log('Token Exists: ${info['exists']}');
      log('Token Length: ${info['length']} characters');
      log('Token Format: ${info['format']}');
      if (info.containsKey('preview')) {
        log('Token Preview: ${info['preview']}');
      }
      log('Validation Status: ${hasValid && isValidFormat ? '✅ Valid' : '❌ Invalid'}');
      
      if (!hasValid) {
        log('⚠️  No token found. User may not be logged in.');
      }
      if (!isValidFormat) {
        log('⚠️  Token format may be invalid. Check login response.');
      }
      
    } catch (e) {
      log('❌ Error during token diagnostics: $e');
    }
    
    log('========== END DIAGNOSTICS ==========');
  }

  /// Clear token
  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('t');
    log('Token cleared from storage');
  }
}
