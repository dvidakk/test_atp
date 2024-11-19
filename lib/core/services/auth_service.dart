// lib/core/services/auth_service.dart

import 'package:bluesky/atproto.dart' as atp;
import 'package:bluesky/bluesky.dart' as bsky;
import 'package:bluesky/core.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService extends ChangeNotifier {
  bsky.Bluesky? _bluesky;
  bool _isAuthenticated = false;
  String? _errorMessage;

  // Getters
  bsky.Bluesky? get bluesky => _bluesky;
  bool get isAuthenticated => _isAuthenticated;
  String? get errorMessage => _errorMessage;

  // Initialize from stored session
  Future<bool> initializeFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final handle = prefs.getString('handle');
    final did = prefs.getString('did');
    final accessJwt = prefs.getString('accessJwt');
    final refreshJwt = prefs.getString('refreshJwt');
    final service = prefs.getString('last_server') ?? 'https://bsky.social';

    if (handle != null &&
        did != null &&
        accessJwt != null &&
        refreshJwt != null) {
      try {
        final sessionData = bsky.SessionData(
          handle: handle,
          did: did,
          accessJwt: accessJwt,
          refreshJwt: refreshJwt,
        );
        _bluesky = bsky.Bluesky.fromSession(sessionData, service: service);
        _isAuthenticated = true;
        notifyListeners();
        return true;
      } catch (e) {
        await logout(); // Clear invalid session
      }
    }
    return false;
  }

  // Login
  Future<bool> login({
    required String identifier,
    required String password,
    String service = 'https://bsky.social',
  }) async {
    try {
      _errorMessage = null;
      final response = await atp.createSession(
        identifier: identifier,
        password: password,
        service: service,
      );

      final sessionData = response.data;
      _bluesky = bsky.Bluesky.fromSession(sessionData, service: service);
      _isAuthenticated = true;

      // Save session
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('handle', sessionData.handle);
      await prefs.setString('did', sessionData.did);
      await prefs.setString('accessJwt', sessionData.accessJwt);
      await prefs.setString('refreshJwt', sessionData.refreshJwt);
      await prefs.setString('last_server', service);

      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Login failed: ${e.toString()}';
      _isAuthenticated = false;
      notifyListeners();
      return false;
    }
  }

  // Refresh session
  Future<bool> refreshSession() async {
    if (_bluesky == null) return false;

    try {
      final response = await atp.refreshSession(
        refreshJwt: _bluesky!.session.data.refreshJwt,
        service: _bluesky!.service,
      );
      final sessionData = response.data;

      // Update bluesky instance with new session data
      _bluesky =
          bsky.Bluesky.fromSession(sessionData, service: _bluesky!.service);

      // Save refreshed session
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('handle', sessionData.handle);
      await prefs.setString('did', sessionData.did);
      await prefs.setString('accessJwt', sessionData.accessJwt);
      await prefs.setString('refreshJwt', sessionData.refreshJwt);

      notifyListeners();
      return true;
    } catch (e) {
      await logout();
      return false;
    }
  }

  // Logout
  Future<void> logout() async {
    _bluesky = null;
    _isAuthenticated = false;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('handle');
    await prefs.remove('did');
    await prefs.remove('accessJwt');
    await prefs.remove('refreshJwt');
    await prefs.remove('last_server');

    notifyListeners();
  }

  // Check if session is valid and refresh if needed
  Future<bool> validateAndRefreshSession() async {
    if (_bluesky == null) return false;

    try {
      // Attempt to make a lightweight request
      await _bluesky!.actor.getProfile(
        actor: _bluesky!.session.data.handle,
      );
      return true;
    } catch (e) {
      // If unauthorized, try refreshing the session
      if (e is atp.UnauthorizedException) {
        return await refreshSession();
      } else {
        // For other errors, consider session invalid
        await logout();
        return false;
      }
    }
  }

  // Get last used server
  Future<String> getLastServer() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('last_server') ?? 'https://bsky.social';
  }
}
