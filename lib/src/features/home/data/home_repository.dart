import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_constants.dart';

class HomeRepository {
  final Dio _apiClient;

  HomeRepository(this._apiClient);

  Future<String?> getHomeBanner() async {
    try {
      final response = await _apiClient.get(ApiConstants.homeBanner);
      if (response.data != null && response.data['success'] == true) {
        return response.data['bannerUrl'] as String?;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<String?> updateHomeBanner(String filePath) async {
    try {
      final formData = FormData.fromMap({
        'banner': await MultipartFile.fromFile(filePath),
      });
      final response = await _apiClient.post(ApiConstants.updateHomeBanner, data: formData);
      if (response.data != null && response.data['success'] == true) {
        return response.data['bannerUrl'] as String?;
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}

final homeRepositoryProvider = Provider<HomeRepository>((ref) {
  return HomeRepository(ref.watch(apiClientProvider));
});

final homeBannerProvider = FutureProvider<String?>((ref) async {
  return ref.watch(homeRepositoryProvider).getHomeBanner();
});
