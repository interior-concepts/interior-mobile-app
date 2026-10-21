import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:clerk_flutter/clerk_flutter.dart';
import '../data/user/user_api_service.dart';

class UserSessionManager {
  static const _cacheFileName = 'crm_user_cache.json';
  static CurrentUser? _memoryUser;
  static bool _listenerAttached = false;

  /// Retrieves the cached user from disk (or in-memory cache)
  static Future<CurrentUser?> getCachedUser() async {
    if (_memoryUser != null) return _memoryUser;

    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}${Platform.pathSeparator}$_cacheFileName');
      if (await file.exists()) {
        final content = await file.readAsString();
        if (content.isNotEmpty) {
          final data = jsonDecode(content) as Map<String, dynamic>;
          _memoryUser = CurrentUser.fromJson(data);
          return _memoryUser;
        }
      }
    } catch (e) {
      debugPrint('⚠️ [SessionManager] Failed to read user cache: $e');
    }
    return null;
  }

  /// Saves the user to disk cache and memory
  static Future<void> saveUser(CurrentUser user) async {
    _memoryUser = user;
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}${Platform.pathSeparator}$_cacheFileName');
      await file.writeAsString(jsonEncode(user.toJson()));
      debugPrint('✅ [SessionManager] Saved user cache for ${user.fullName} (${user.id})');
    } catch (e) {
      debugPrint('⚠️ [SessionManager] Failed to save user cache: $e');
    }
  }

  /// Clears the user cache upon intentional sign out
  static Future<void> clearUser() async {
    _memoryUser = null;
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}${Platform.pathSeparator}$_cacheFileName');
      if (await file.exists()) {
        await file.delete();
      }
      debugPrint('🗑️ [SessionManager] User cache cleared');
    } catch (e) {
      debugPrint('⚠️ [SessionManager] Failed to clear user cache: $e');
    }
  }

  /// Ensures the Clerk Client object with the active user session is persisted
  /// into Clerk persistor so that cold-starts never lose the logged-in state.
  static void persistClerkClient(ClerkAuthState authState) {
    try {
      final client = authState.client;
      if (client.user != null) {
        authState.config.persistor.write(r'$client', jsonEncode(client.toJson()));
      }
    } catch (e) {
      debugPrint('⚠️ [SessionManager] Failed to persist clerk client: $e');
    }
  }

  /// Automatically monitors authState and keeps the session persisted
  static void setupAutoPersist(ClerkAuthState authState) {
    if (_listenerAttached) return;
    _listenerAttached = true;

    // Immediately persist if signed in
    persistClerkClient(authState);

    authState.addListener(() {
      if (authState.isSignedIn) {
        persistClerkClient(authState);
      }
    });
  }
}
