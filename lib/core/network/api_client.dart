import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tryd/main.dart';
import 'package:tryd/src/features/onboarding/presentation/start_screen.dart';
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

  // Separate Dio instance for token refresh — avoids interceptor re-entry
  final refreshDio = Dio(
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

  // Track whether a refresh is already in progress to avoid parallel refreshes
  bool isRefreshing = false;
  final List<(DioException, ErrorInterceptorHandler)> pendingQueue = [];

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
      onError: (DioException e, handler) async {
        if (e.response?.statusCode == 401) {
          if (isRefreshing) {
            // Queue concurrent 401s while refresh is already in progress
            pendingQueue.add((e, handler));
            return;
          }

          cachedPrefs ??= await SharedPreferences.getInstance();
          final existingAccessToken = cachedPrefs!.getString('auth_token');

          // No auth token means the user is in the auth flow (login/OTP/register).
          // Just pass the error through — do not redirect.
          if (existingAccessToken == null || existingAccessToken.isEmpty) {
            return handler.next(e);
          }

          final storedRefreshToken = cachedPrefs!.getString('refresh_token');

          // No refresh token — stale access token with no way to renew.
          // Clear it silently and let the current flow handle auth naturally.
          if (storedRefreshToken == null || storedRefreshToken.isEmpty) {
            await cachedPrefs!.remove('auth_token');
            return handler.next(e);
          }

          isRefreshing = true;
          bool refreshSucceeded = false;

          try {
            // Attempt token refresh
            final refreshResponse = await refreshDio.post(
              ApiConstants.refreshToken,
              data: {'refreshToken': storedRefreshToken},
            );

            final newAccessToken = refreshResponse.data['accessToken'] as String?;
            final newRefreshToken = refreshResponse.data['refreshToken'] as String?;

            if (newAccessToken != null && newAccessToken.isNotEmpty) {
              // Persist new tokens
              await cachedPrefs!.setString('auth_token', newAccessToken);
              if (newRefreshToken != null) {
                await cachedPrefs!.setString('refresh_token', newRefreshToken);
              }

              // 1. Retry original request with new access token
              e.requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
              final retryResponse = await dio.fetch(e.requestOptions);
              refreshSucceeded = true;
              isRefreshing = false;

              // 2. Flush queued requests - they also get the new token
              for (final (pendingError, pendingHandler) in pendingQueue) {
                pendingError.requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
                try {
                  final retried = await dio.fetch(pendingError.requestOptions);
                  pendingHandler.resolve(retried);
                } catch (retryErr) {
                  pendingHandler.next(pendingError);
                }
              }
              pendingQueue.clear();

              return handler.resolve(retryResponse);
            }
          } catch (_) {
            // Refresh failed — fall through to force logout
          }

          isRefreshing = false;

          if (!refreshSucceeded) {
            // Flush queue with errors before logout
            for (final (pendingError, pendingHandler) in pendingQueue) {
              pendingHandler.next(pendingError);
            }
            pendingQueue.clear();

            // Had a refresh token but it failed — session is truly dead, send to login
            await cachedPrefs!.remove('auth_token');
            await cachedPrefs!.remove('refresh_token');

            navigatorKey.currentState?.pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const StartScreen()),
              (_) => false,
            );
          }
        }

        return handler.next(e);
      },
    ),
  );

  return dio;
}

