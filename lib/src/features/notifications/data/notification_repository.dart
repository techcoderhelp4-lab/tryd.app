import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_constants.dart';
import '../domain/app_notification.dart';

class NotificationRepository {
  final Dio _dio;
  NotificationRepository(this._dio);

  Future<List<AppNotification>> getNotifications({int page = 1, int limit = 20}) async {
    try {
      final response = await _dio.get(
        ApiConstants.notifications,
        queryParameters: {'page': page, 'limit': limit},
      );

      final dynamic rawData = response.data;
      final List<dynamic> data;
      if (rawData is List) {
        data = rawData;
      } else if (rawData is Map) {
        data = rawData['notifications'] ?? rawData['data'] ?? [];
      } else {
        data = [];
      }
      return data.map((json) => AppNotification.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<int> getUnreadCount() async {
    try {
      final response = await _dio.get(ApiConstants.notificationsUnreadCount);
      return response.data['count'] ?? 0;
    } catch (e) {
      return 0;
    }
  }

  Future<void> markAsRead(String id) async {
    try {
      await _dio.put(ApiConstants.notificationMarkRead(id));
    } catch (e) {
      // Log or handle error
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await _dio.put(ApiConstants.notificationsMarkAllRead);
    } catch (e) {
      // Log or handle error
    }
  }

  Future<void> deleteNotification(String id) async {
    try {
      await _dio.delete(ApiConstants.notificationDelete(id));
    } catch (e) {
      // Log or handle error
    }
  }
}

// ── Manual providers (keepAlive — no re-fetch on revisit) ──

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  final dio = ref.watch(apiClientProvider);
  return NotificationRepository(dio);
});

final notificationsListProvider = FutureProvider<List<AppNotification>>((ref) {
  final repository = ref.watch(notificationRepositoryProvider);
  return repository.getNotifications();
});

final unreadNotificationCountProvider = FutureProvider<int>((ref) {
  final repository = ref.watch(notificationRepositoryProvider);

  // Refresh every 30 seconds
  final timer = Stream.periodic(const Duration(seconds: 30)).listen((_) {
    ref.invalidateSelf();
  });

  ref.onDispose(() => timer.cancel());

  return repository.getUnreadCount();
});
