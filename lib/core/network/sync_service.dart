import 'dart:convert';
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/local_database.dart';
import '../../src/features/activity/data/activity_repository.dart';
import '../../src/features/challenges/data/challenge_repository.dart';
import '../network/api_client.dart';
import 'package:flutter/foundation.dart';

class SyncService {
  final Ref _ref;
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  SyncService(this._ref);

  void init() {
    _subscription = Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      final hasInternet = results.any((result) => result != ConnectivityResult.none);
      if (hasInternet) {
        _syncAll();
      }
    });
    
    // Initial sync attempt
    _syncAll();
  }

  Future<void> _syncAll() async {
    // Sync heavy activities first
    await _ref.read(activityRepositoryProvider).syncPendingActivities();
    
    // Process generic action queue
    await _syncPendingActions();
  }

  Future<void> _syncPendingActions() async {
    final localDb = _ref.read(localDatabaseProvider);
    final dio = _ref.read(apiClientProvider);
    
    final queue = await localDb.getSyncQueue();
    if (queue.isEmpty) return;

    debugPrint("SyncService: Processing ${queue.length} pending actions...");

    for (var action in queue) {
      final int id = action['id'];
      final String endpoint = action['endpoint'];
      final String method = action['method'];
      final Map<String, dynamic> payload = jsonDecode(action['payload']);

      try {
        Response response;
        if (method == 'POST') {
          response = await dio.post(endpoint, data: payload);
        } else if (method == 'PUT') {
          response = await dio.put(endpoint, data: payload);
        } else if (method == 'DELETE') {
          response = await dio.delete(endpoint, data: payload);
        } else {
          continue;
        }

        if (response.statusCode != null && response.statusCode! < 300) {
          await localDb.removeFromQueue(id);
          debugPrint("SyncService: Action $id synced successfully.");
        }
      } on DioException catch (e) {
        final statusCode = e.response?.statusCode;
        final responseData = e.response?.data;
        
        // If it's a 400 error, check if it's an "Already joined" or similar logical error
        // that shouldn't be retried.
        if (statusCode == 400) {
          final message = responseData is Map ? responseData['message']?.toString() : "";
          if (message != null && (
              message.contains("Already joined") || 
              message.contains("Not participating") || 
              message.contains("Challenge has ended"))) {
            await localDb.removeFromQueue(id);
            debugPrint("SyncService: Action $id removed from queue due to logical error: $message");
            continue;
          }
        }
        
        debugPrint("SyncService: Action $id sync failed: ${e.message}");
      } catch (e) {
        debugPrint("SyncService: Action $id sync unexpected error: $e");
      }
    }
  }

  void dispose() {
    _subscription?.cancel();
  }
}

final syncServiceProvider = Provider<SyncService>((ref) {
  final service = SyncService(ref);
  ref.onDispose(() => service.dispose());
  return service;
});
