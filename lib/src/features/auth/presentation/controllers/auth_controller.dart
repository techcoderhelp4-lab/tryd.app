import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/auth_repository.dart';
import '../../domain/user.dart';

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
      return response.user;
    });
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String phoneNumber,
    required String gender,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final authRepo = ref.read(authRepositoryProvider);
      final response = await authRepo.register(
        name: name,
        email: email,
        password: password,
        phoneNumber: phoneNumber,
        gender: gender,
      );
      return response.user;
    });
  }

  Future<void> logout() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final authRepo = ref.read(authRepositoryProvider);
      await authRepo.logout();
      return null;
    });
  }
}
