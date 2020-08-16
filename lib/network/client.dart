import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:resurgence/authentication/state.dart';
import 'package:resurgence/authentication/token.dart';
import 'package:resurgence/constants.dart';
import 'package:resurgence/network/error.dart';

class Client {
  final AuthenticationState _state;
  static final Set<String> securityPaths =
      Set.of(['login', 'security/refresh']);

  Dio _dio;

  Client(this._state) {
    var options = BaseOptions(
      // todo get base url from configuration
      baseUrl: S.baseUrl,
      headers: {'version': S.version},
      contentType: 'application/json',
    );
    _dio = Dio(options);
    loadInterceptors();
  }

  loadInterceptors() {
    _dio.interceptors.add(logInterceptor());
    _dio.interceptors.add(accessTokenFilter());
    _dio.interceptors.add(refreshTokenFilter());
    _dio.interceptors.add(apiErrorInterceptor());
  }

  Interceptor logInterceptor() {
    return LogInterceptor(
      request: false,
      requestHeader: false,
      requestBody: false,
      responseHeader: false,
      responseBody: false,
      error: false,
      logPrint: (_log) => log(_log),
    );
  }

  Interceptor apiErrorInterceptor() {
    return InterceptorsWrapper(
      onError: (e) {
        if (e.type == DioErrorType.RESPONSE &&
            e.response?.data != null &&
            e.response?.data != '' &&
            e.response?.data['message'] != null) {
          throw ApiError(e);
        } else {
          throw e;
        }
      },
    );
  }

  Interceptor accessTokenFilter() {
    return InterceptorsWrapper(
      onRequest: (RequestOptions options) {
        if (_state.isLoggedIn && !securityPaths.contains(options.path)) {
          options.headers['Authorization'] =
              'Bearer ${_state.token.accessToken}';
        }
      },
    );
  }

  Interceptor refreshTokenFilter() {
    return InterceptorsWrapper(onError: (e) {
      if (e.type == DioErrorType.RESPONSE &&
          !securityPaths.contains(e.request.path) &&
          e.response.statusCode == 401) {
        var failedRequest = e.request;
        var refreshTokenOptions = Options(
          headers: {'Refresh-Token': _state.token.refreshToken},
        );

        return _dio
            .post('security/refresh', options: refreshTokenOptions)
            .then((response) => Token.fromJson(response.data))
            .catchError((e) {
              _state.logout();
              throw RefreshTokenExpiredError(e);
            })
            // todo consider login may not need to notify listener
            .then((token) => _state.login(token))
            .then((_) => _dio.request(
                  failedRequest.path,
                  options: failedRequest,
                ));
      }

      return e;
    });
  }

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic> queryParameters,
    Options options,
    CancelToken cancelToken,
    ProgressCallback onReceiveProgress,
  }) {
    return _dio.get(
      path,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      onReceiveProgress: onReceiveProgress,
    );
  }

  Future<Response<T>> post<T>(
    String path, {
    data,
    Map<String, dynamic> queryParameters,
    Options options,
    CancelToken cancelToken,
    ProgressCallback onSendProgress,
    ProgressCallback onReceiveProgress,
  }) {
    return _dio.post(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
  }

  Future<Response<T>> delete<T>(
    String path, {
    data,
    Map<String, dynamic> queryParameters,
    Options options,
    CancelToken cancelToken,
    ProgressCallback onSendProgress,
    ProgressCallback onReceiveProgress,
  }) {
    return _dio.delete(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }
}

class RefreshTokenExpiredError extends DioError {
  RefreshTokenExpiredError(DioError e)
      : super(
          request: e.request,
          response: e.response,
          type: e.type,
          error: e.error,
        );

  @override
  String toString() {
    var msg = 'RefreshTokenExpiredError [$type]: $message';
    if (error is Error) {
      msg += '\n${error.stackTrace}';
    }
    return msg;
  }
}
