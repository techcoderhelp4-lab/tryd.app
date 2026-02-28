import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/auth_repository.dart';
import '../../domain/user.dart';
import 'package:tryd/core/database/local_database.dart';
import 'package:tryd/core/network/api_client.dart';
import 'package:tryd/src/features/profile/data/user_repository.dart';
import 'package:tryd/src/features/challenges/data/challenge_repository.dart';
import 'package:tryd/src/features/rewards/data/reward_repository.dart';
import 'package:tryd/src/features/activity/data/activity_repository.dart';
import 'package:tryd/src/features/notifications/data/notification_repository.dart';
import 'package:tryd/core/network/sync_service.dart';
import 'package:flutter/foundation.dart';

part 'auth_controller.g.dart';

@Riverpod(keepAlive: true)
class AuthController extends _$AuthController {
  @override
  FutureOr<User?> build() {
    return null;
  }

  Future<void> login({required String email, required String password}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final authRepo = ref.read(authRepositoryProvider);
      final response = await authRepo.login(email: email, password: password);
      await _onAccountChange();
      return response.user;
    });
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String phoneNumber,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final authRepo = ref.read(authRepositoryProvider);
      final response = await authRepo.register(
        name: name,
        email: email,
        password: password,
        phoneNumber: phoneNumber,
      );
      await _onAccountChange();
      return response.user;
    });
  }

  Future<void> verifyOtpLogin(String email, String otp) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final authRepo = ref.read(authRepositoryProvider);
      final response = await authRepo.verifyOtpLogin(email, otp);
      await _onAccountChange();
      return response.user;
    });
  }

  Future<void> verifyOtp(String email, String otp) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final authRepo = ref.read(authRepositoryProvider);
      final response = await authRepo.verifyOtp(email, otp);
      await _onAccountChange();
      return response.user;
    });
  }

  Future<void> logout() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final authRepo = ref.read(authRepositoryProvider);
      await authRepo.logout();
      await _onAccountChange();
      return null;
    });
  }

  /// Clears all local data and invalidates data providers to ensure
  /// a clean state when switching accounts.
  Future<void> _onAccountChange() async {
    try {
      debugPrint('AuthController: Account changed, performing global reset...');
      
      // 1. Clear Local Database (Cache, activities, etc.)
      final localDb = ref.read(localDatabaseProvider);
      await localDb.clearAllData();
      
      // 2. Invalidate API Client
      // This will cause all providers that depend on it (repositories, etc.) to rebuild
      ref.invalidate(apiClientProvider);

      // 3. Force Invalidate key domain providers to ensure UI reactive update
      ref.invalidate(userProfileProvider);
      ref.invalidate(challengesListProvider);
      ref.invalidate(rewardsListProvider);
      ref.invalidate(myRedemptionsProvider);
      ref.invalidate(activityListProvider);
      ref.invalidate(notificationsListProvider);
      ref.invalidate(unreadNotificationCountProvider);
      
      // 4. Force restart sync service if it's active
      ref.invalidate(syncServiceProvider);
      
      debugPrint('AuthController: Global reset completed.');
    } catch (e) {
      debugPrint('AuthController: Error during account change reset: $e');
    }
  }
}
