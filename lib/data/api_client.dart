import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api_failure.dart';
import '../models/models.dart';

class ApiClient {
  static const bundledServerUrl = String.fromEnvironment(
    'AHANCHI_API_URL',
    defaultValue: 'http://10.0.2.2:3000/api/v1',
  );

  ApiClient(this.preferences) {
    _dio = Dio(BaseOptions(
      baseUrl: serverUrl,
      connectTimeout: const Duration(seconds: 12),
      receiveTimeout: const Duration(seconds: 20),
      headers: {'Accept': 'application/json'},
    ));
    _dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
      final token = preferences.getString('access_token');
      if (token != null) options.headers['Authorization'] = 'Bearer $token';
      if (kDebugMode) debugPrint('[AhanChi API] ${options.method} ${options.path} -> sending');
      handler.next(options);
    }, onResponse: (response, handler) {
      if (kDebugMode) debugPrint('[AhanChi API] ${response.requestOptions.method} ${response.requestOptions.path} -> ${response.statusCode}');
      handler.next(response);
    }, onError: (error, handler) {
      if (kDebugMode) {
        final failure = ApiFailure.fromDio(error);
        debugPrint('[AhanChi API] ${error.requestOptions.method} ${error.requestOptions.path} -> ${error.response?.statusCode ?? error.type.name}: ${failure.message}');
      }
      handler.next(error);
    }));
  }

  final SharedPreferences preferences;
  late final Dio _dio;
  String get serverUrl => preferences.getString('server_url') ?? bundledServerUrl;

  Future<void> setServerUrl(String value) async {
    final normalized = value.trim().replaceAll(RegExp(r'/+$'), '');
    await preferences.setString('server_url', normalized);
    _dio.options.baseUrl = normalized;
  }

  Future<AuthSession> login(String phone, String password) async {
    return _guard(() async {
      final response = await _dio.post<Map<String, dynamic>>('/auth/login', data: {'phone': phone, 'password': password});
      final session = AuthSession.fromJson(response.data!);
      await preferences.setString('access_token', session.accessToken);
      return session;
    });
  }

  Future<List<Map<String, dynamic>>> list(String path, {Map<String, dynamic>? query}) async {
    return _guard(() async {
      final response = await _dio.get<List<dynamic>>(path, queryParameters: query);
      return response.data!.cast<Map<String, dynamic>>();
    });
  }

  Future<Map<String, dynamic>> get(String path, {Map<String, dynamic>? query}) async {
    return _guard(() async {
      final response = await _dio.get<Map<String, dynamic>>(path, queryParameters: query);
      return response.data!;
    });
  }

  Future<Map<String, dynamic>> post(String path, Map<String, dynamic> data) async {
    return _guard(() async {
      final response = await _dio.post<Map<String, dynamic>>(path, data: data);
      return response.data!;
    });
  }

  Future<T> _guard<T>(Future<T> Function() request) async {
    try {
      return await request();
    } on DioException catch (error) {
      throw ApiFailure.fromDio(error);
    }
  }
}
