import 'package:bluesky/atproto.dart' as atp;
import 'package:bluesky/bluesky.dart' as bsky;
import 'package:bluesky/core.dart';
import 'package:flutter/material.dart';
import 'package:jwt_decode/jwt_decode.dart' as jwt_decode;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

import 'package:test_atp/core/models/stored_account.dart';

class AuthService extends ChangeNotifier {
  bsky.Bluesky? _bluesky;
  bool _isAuthenticated = false;
  String? _errorMessage;
  DateTime? _accessTokenExpiry;

  final _secureStorage = const FlutterSecureStorage();

  List<StoredAccount> _storedAccounts = [];

  bsky.Bluesky? get bluesky => _bluesky;
  bool get isAuthenticated => _isAuthenticated;
  String? get errorMessage => _errorMessage;

  List<StoredAccount> get storedAccounts => _storedAccounts;

  Future<bool> initializeFromStorage() async {
    final handle = await _secureStorage.read(key: 'handle');
    final did = await _secureStorage.read(key: 'did');
    final accessJwt = await _secureStorage.read(key: 'accessJwt');
    final refreshJwt = await _secureStorage.read(key: 'refreshJwt');
    final service =
        await _secureStorage.read(key: 'last_server') ?? 'https://bsky.social';

    if (handle != null &&
        did != null &&
        accessJwt != null &&
        refreshJwt != null) {
      try {
        final sessionData = Session(
          handle: handle,
          did: did,
          accessJwt: accessJwt,
          refreshJwt: refreshJwt,
        );

        // Decode JWT to get expiration time
        _accessTokenExpiry = _getExpiryDateFromJwt(accessJwt);

        _bluesky = bsky.Bluesky.fromSession(sessionData);
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
        //service: service,
      );

      final sessionData = response.data;

      // Decode JWT to get expiration time
      _accessTokenExpiry = _getExpiryDateFromJwt(sessionData.accessJwt);

      _bluesky = bsky.Bluesky.fromSession(sessionData);
      _isAuthenticated = true;

      // Save session securely
      await _secureStorage.write(key: 'handle', value: sessionData.handle);
      await _secureStorage.write(key: 'did', value: sessionData.did);
      await _secureStorage.write(
          key: 'accessJwt', value: sessionData.accessJwt);
      await _secureStorage.write(
          key: 'refreshJwt', value: sessionData.refreshJwt);
      await _secureStorage.write(key: 'last_server', value: service);
      await _secureStorage.write(
        key: 'accessJwtExpiry',
        value: (_accessTokenExpiry?.millisecondsSinceEpoch ?? 0).toString(),
      );

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
        refreshJwt: _bluesky!.session?.refreshJwt ?? '',
        service: _bluesky!.service,
      );
      final sessionData = response.data;

      // Decode JWT to get expiration time
      _accessTokenExpiry = _getExpiryDateFromJwt(sessionData.accessJwt);

      // Update bluesky instance with new session data
      _bluesky = bsky.Bluesky.fromSession(sessionData);
      _isAuthenticated = true;

      // Save refreshed session securely
      await _secureStorage.write(key: 'handle', value: sessionData.handle);
      await _secureStorage.write(key: 'did', value: sessionData.did);
      await _secureStorage.write(
          key: 'accessJwt', value: sessionData.accessJwt);
      await _secureStorage.write(
          key: 'refreshJwt', value: sessionData.refreshJwt);
      await _secureStorage.write(
        key: 'accessJwtExpiry',
        value: (_accessTokenExpiry?.millisecondsSinceEpoch ?? 0).toString(),
      );

      notifyListeners();
      return true;
    } catch (e) {
      await logout();
      return false;
    }
  }

  // Check if access token is expired
  Future<bool> isAccessTokenExpired() async {
    if (_accessTokenExpiry == null) {
      return true; // Assume expired if expiry date is not available
    }
    return DateTime.now().isAfter(_accessTokenExpiry!);
  }

  // Validate and refresh session if needed
  Future<bool> validateAndRefreshSession() async {
    if (await isAccessTokenExpired()) {
      return await refreshSession();
    }
    return true;
  }

  // Logout
  Future<void> logout() async {
    _bluesky = null;
    _isAuthenticated = false;
    _accessTokenExpiry = null;

    await _secureStorage.deleteAll();

    notifyListeners();
  }

  // Helper method to decode JWT and get expiry date
  DateTime? _getExpiryDateFromJwt(String token) {
    try {
      Map<String, dynamic> payload = jwt_decode.Jwt.parseJwt(token);
      int exp = payload['exp'] as int;
      return DateTime.fromMillisecondsSinceEpoch(exp * 1000);
    } catch (e) {
      return null;
    }
  }

  Future<String> getLastServer() async {
    return await _secureStorage.read(key: 'last_server') ??
        'https://bsky.social';
  }

  Future<void> _loadStoredAccounts() async {
    final accountsJson = await _secureStorage.read(key: 'stored_accounts');
    if (accountsJson != null) {
      final List<dynamic> decoded = jsonDecode(accountsJson);
      _storedAccounts = decoded.map((e) => StoredAccount.fromJson(e)).toList();
    }
  }

  Future<void> _saveStoredAccounts() async {
    final accountsJson =
        jsonEncode(_storedAccounts.map((e) => e.toJson()).toList());
    await _secureStorage.write(key: 'stored_accounts', value: accountsJson);
  }

  Future<void> addStoredAccount(StoredAccount account) async {
    if (!_storedAccounts.any((a) => a.did == account.did)) {
      _storedAccounts.add(account);
      await _saveStoredAccounts();
      notifyListeners();
    }
  }

  Future<void> removeStoredAccount(String did) async {
    _storedAccounts.removeWhere((a) => a.did == did);
    await _saveStoredAccounts();
    notifyListeners();
  }

  // Add a method to handle API calls with auto-refresh
  Future<T> authenticatedRequest<T>(Future<T> Function() request) async {
    try {
      // Check if token needs refresh before making request
      if (await isAccessTokenExpired()) {
        final refreshed = await refreshSession();
        if (!refreshed) {
          throw Exception('Failed to refresh session');
        }
      }

      return await request();
    } catch (e) {
      if (e.toString().contains('Token has expired')) {
        // Try refreshing token and retrying request once
        final refreshed = await refreshSession();
        if (refreshed) {
          return await request();
        }
      }

      // If refresh failed or other error, logout and rethrow
      await logout();
      rethrow;
    }
  }
}
