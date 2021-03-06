import 'dart:convert';
import 'dart:developer';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:resurgence/authentication/token.dart';
import 'package:sentry/sentry.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _LOG_TAG = 'AUTHENTICATION_STATE: ';

class AuthenticationState with ChangeNotifier {
  static const _ACCESS_TOKEN_KEY = 'access_token';
  static const _REFRESH_TOKEN_KEY = 'refresh_token';

  Token _token;
  FirebaseAnalytics _analytics;

  AuthenticationState({FirebaseAnalytics analytics}) {
    log('$_LOG_TAG Constructor called.');
    _getToken()
        .then((token) => this.login(token))
        .catchError((e) => log('$_LOG_TAG token read error $e. Do nothing!'));
    this._analytics = analytics;
  }

  void login(Token token) {
    log('$_LOG_TAG login attempt with token $token.\nOld token was $_token');
    if (token == null) return;
    _token = token;
    _saveToken(token);
    try {
      var jwt = _decodeToken(token.accessToken);
      var id = jwt['sub'];
      var userHash = "${id?.hashCode ?? 'anonymous'}";
      Sentry.configureScope((scope) {
        scope.user = SentryUser(
          id: userHash,
          email: userHash,
          username: jwt['player'],
        );
      });
      _analytics?.setUserId(id);
    } catch (e) {
      Sentry.captureException(e, hint: 'User initialize process');
      log('$_LOG_TAG Sentry or Analytics was failed.', error: e);
    }
    notifyListeners();
  }

  void logout() {
    _token = null;
    try {
      GoogleSignIn().signOut();
      Sentry.configureScope((scope) => scope.user = null);
      _analytics.setUserId(null);
    } catch (ignored) {}
    _removeToken();
    notifyListeners();
  }

  Future<Token> _getToken() {
    return SharedPreferences.getInstance().then((value) {
      var accessToken = value.getString(_ACCESS_TOKEN_KEY);
      var refreshToken = value.getString(_REFRESH_TOKEN_KEY);
      if (accessToken == null || refreshToken == null)
        throw TokenNotFoundError();

      return Token(accessToken: accessToken, refreshToken: refreshToken);
    });
  }

  Future<void> _saveToken(Token token) {
    return SharedPreferences.getInstance().then((value) {
      value.setString(_ACCESS_TOKEN_KEY, token.accessToken);
      value.setString(_REFRESH_TOKEN_KEY, token.refreshToken);
    });
  }

  Future<void> _removeToken() {
    return SharedPreferences.getInstance().then((value) {
      value.remove(_ACCESS_TOKEN_KEY);
      value.remove(_REFRESH_TOKEN_KEY);
    });
  }

  bool get isLoggedIn {
    return _token != null;
  }

  Token get token => _token;

  String playerName() =>
      isLoggedIn ? _decodeToken(this._token.accessToken)['player'] : null;

  static Map<String, dynamic> _decodeToken(String token) {
    try {
      List<String> splitToken = token.split('.'); // Split the token by '.'
      String payloadBase64 = splitToken[1]; // Payload is always the index 1
      // Base64 should be multiple of 4. Normalize the payload before decode it
      String normalizedPayload = base64.normalize(payloadBase64);
      // Decode payload, the result is a String
      String payloadString = utf8.decode(base64.decode(normalizedPayload));
      // Parse the String to a Map<String, dynamic>
      Map<String, dynamic> decodedPayload = jsonDecode(payloadString);

      // Return the decoded payload
      return decodedPayload;
    } catch (error) {
      // If there's an error return empty map
      return {};
    }
  }
}

class TokenNotFoundError extends Error {}
