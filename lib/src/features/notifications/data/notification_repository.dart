import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_constants.dart';
import '../domain/app_notification.dart';

part 'notification_repository.g.dart';

class NotificationRepository {
  final Dio _dio;
  NotificationRepository(this._dio);

  Future<List<AppNotification>> getNotifications({int page = 1, int limit = 20}) async {
    try {
      final response = await _dio.get(
        ApiConstants.notifications,
        queryParameters: {'page': page, 'limit': limit},
      );
      
      final List<dynamic> data = response.data['notifications'] ?? response.data['data'] ?? response.data;
      return data.map((json) => AppNotification.fromJson(json)).toList();
    } catch (e) {
      // Return empty list on error for now, or rethrow if important
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
    await _dio.put(ApiConstants.notificationMarkRead(id));
  }

  Future<void> markAllAsRead() async {
    await _dio.put(ApiConstants.notificationsMarkAllRead);
  }

  Future<void> deleteNotification(String id) async {
    await _dio.delete(ApiConstants.notificationDelete(id));
  }
}

@riverpod
NotificationRepository notificationRepository(NotificationRepositoryRef ref) {
  final dio = ref.watch(apiClientProvider);
  return NotificationRepository(dio);
}

@riverpod
Future<List<AppNotification>> notificationsList(NotificationsListRef ref) {
  final repository = ref.watch(notificationRepositoryProvider);
  return repository.getNotifications();
}

@riverpod
Future<int> unreadNotificationCount(UnreadNotificationCountRef ref) {
  final repository = ref.watch(notificationRepositoryProvider);
  
  // Refresh every 30 seconds
  final timer = Stream.periodic(const Duration(seconds: 30)).listen((_) {
    ref.invalidateSelf();
  });
  
  ref.onDispose(() => timer.cancel());
  
  return repository.getUnreadCount();
}
