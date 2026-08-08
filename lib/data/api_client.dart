import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

class ApiClient {
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
      handler.next(options);
    }));
  }

  final SharedPreferences preferences;
  late final Dio _dio;
  String get serverUrl => preferences.getString('server_url') ?? 'http://10.0.2.2:3000/api/v1';

  Future<void> setServerUrl(String value) async {
    final normalized = value.trim().replaceAll(RegExp(r'/+$'), '');
    await preferences.setString('server_url', normalized);
    _dio.options.baseUrl = normalized;
  }

  Future<AuthSession> login(String phone, String password) async {
    final response = await _dio.post<Map<String, dynamic>>('/auth/login', data: {'phone': phone, 'password': password});
    final session = AuthSession.fromJson(response.data!);
    await preferences.setString('access_token', session.accessToken);
    return session;
  }

  Future<List<Map<String, dynamic>>> list(String path, {Map<String, dynamic>? query}) async {
    final response = await _dio.get<List<dynamic>>(path, queryParameters: query);
    return response.data!.cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> get(String path, {Map<String, dynamic>? query}) async {
    final response = await _dio.get<Map<String, dynamic>>(path, queryParameters: query);
    return response.data!;
  }

  Future<Map<String, dynamic>> post(String path, Map<String, dynamic> data) async {
    final response = await _dio.post<Map<String, dynamic>>(path, data: data);
    return response.data!;
  }
}
