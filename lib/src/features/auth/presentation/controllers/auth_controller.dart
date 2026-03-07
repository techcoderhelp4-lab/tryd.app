import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/auth_repository.dart';
import '../../domain/user.dart';
import '../../../../../core/database/local_database.dart';
import '../../../../../core/network/api_client.dart';
import '../../../profile/data/user_repository.dart';
import '../../../challenges/data/challenge_repository.dart';
import '../../../rewards/data/reward_repository.dart';
import '../../../activity/data/activity_repository.dart';
import '../../../notifications/data/notification_repository.dart';
import '../../../notifications/data/real_time_notification_service.dart';
import '../../../../../core/network/sync_service.dart';

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
      await authRepo.logout(ref);
      await _onAccountChange();
      return null;
    });
  }

  /// Clears all local data and invalidates data providers to ensure
  /// a clean state when switching accounts.
  Future<void> _onAccountChange() async {
    try {
      debugPrint('AuthController: Account changed, performing global reset...');
      
      // 1. Disconnect real-time services
      ref.read(realTimeNotificationServiceProvider).disconnect();
      
      // 2. Clear Local Database (SQLite)
      final localDb = ref.read(localDatabaseProvider);
      await localDb.clearAllData();
      
      // 3. Clear SharedPreferences specific keys
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('workoutHistory');
      await prefs.remove('activityHistory');
      await prefs.remove('cached_user_profile');
      
      // 4. Invalidate all data providers to force re-fetch
      ref.invalidate(apiClientProvider);
      
      ref.invalidate(userProfileProvider);
      ref.invalidate(challengesListProvider);
      ref.invalidate(rewardsListProvider);
      ref.invalidate(myRedemptionsProvider);
      ref.invalidate(activityListProvider);
      ref.invalidate(notificationsListProvider);
      ref.invalidate(unreadNotificationCountProvider);
      
      // Force invalidate families and complex providers
      ref.invalidate(activitySummaryProvider);
      ref.invalidate(activityStatsProvider);
      ref.invalidate(challengeLeaderboardProvider);
      ref.invalidate(challengeDetailsProvider);
      ref.invalidate(filteredRewardsProvider);
      ref.invalidate(workoutHistoryProvider);
      
      // 5. Force restart sync service
      ref.invalidate(syncServiceProvider);
      
      debugPrint('AuthController: Global reset completed.');
    } catch (e) {
      debugPrint('AuthController: Error during account change reset: $e');
    }
  }
}
