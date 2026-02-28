import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_constants.dart';

part 'api_client.g.dart';

@Riverpod(keepAlive: true)
Dio apiClient(ApiClientRef ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  // Cache SharedPreferences to avoid disk I/O on every request
  SharedPreferences? cachedPrefs;

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        cachedPrefs ??= await SharedPreferences.getInstance();
        final token = cachedPrefs!.getString('auth_token');

        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }

        return handler.next(options);
      },
      onError: (DioException e, handler) {
          if (e.response?.statusCode == 401) {
             // Handle 401: Maybe clear token.
          }
          return handler.next(e);
      },
    ),
  );

  return dio;
}
