// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'activity_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$activityRepositoryHash() =>
    r'ad14e753e2e4aab2450f5c2ea08a36de2cbb6ed2';

/// See also [activityRepository].
@ProviderFor(activityRepository)
final activityRepositoryProvider =
    AutoDisposeProvider<ActivityRepository>.internal(
      activityRepository,
      name: r'activityRepositoryProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$activityRepositoryHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ActivityRepositoryRef = AutoDisposeProviderRef<ActivityRepository>;
String _$activityListHash() => r'7752110a2e252dd3a11844eb9bc8f229c30a724e';

/// See also [activityList].
@ProviderFor(activityList)
final activityListProvider = AutoDisposeFutureProvider<List<Activity>>.internal(
  activityList,
  name: r'activityListProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$activityListHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ActivityListRef = AutoDisposeFutureProviderRef<List<Activity>>;
String _$workoutHistoryHash() => r'326fb04e1e9a79f73334f0f78d469c7493063329';

/// See also [WorkoutHistory].
@ProviderFor(WorkoutHistory)
final workoutHistoryProvider =
    AutoDisposeAsyncNotifierProvider<WorkoutHistory, List<Workout>>.internal(
      WorkoutHistory.new,
      name: r'workoutHistoryProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$workoutHistoryHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$WorkoutHistory = AutoDisposeAsyncNotifier<List<Workout>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
