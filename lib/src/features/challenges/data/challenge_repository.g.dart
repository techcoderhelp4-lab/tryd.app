// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'challenge_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$challengeRepositoryHash() =>
    r'5b93a7a82d05d09f4a4bd7ba8fcfa0acd877c105';

/// See also [challengeRepository].
@ProviderFor(challengeRepository)
final challengeRepositoryProvider =
    AutoDisposeProvider<ChallengeRepository>.internal(
      challengeRepository,
      name: r'challengeRepositoryProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$challengeRepositoryHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ChallengeRepositoryRef = AutoDisposeProviderRef<ChallengeRepository>;
String _$challengesListHash() => r'2b17e47707e583c208554a69436ca69a8cdd380e';

/// See also [challengesList].
@ProviderFor(challengesList)
final challengesListProvider =
    AutoDisposeFutureProvider<List<Challenge>>.internal(
      challengesList,
      name: r'challengesListProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$challengesListHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ChallengesListRef = AutoDisposeFutureProviderRef<List<Challenge>>;
String _$challengeDetailsHash() => r'1eca32d21bb312ae56119324c0e2cde7cbd4b1e1';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// See also [challengeDetails].
@ProviderFor(challengeDetails)
const challengeDetailsProvider = ChallengeDetailsFamily();

/// See also [challengeDetails].
class ChallengeDetailsFamily extends Family<AsyncValue<Challenge>> {
  /// See also [challengeDetails].
  const ChallengeDetailsFamily();

  /// See also [challengeDetails].
  ChallengeDetailsProvider call(String id) {
    return ChallengeDetailsProvider(id);
  }

  @override
  ChallengeDetailsProvider getProviderOverride(
    covariant ChallengeDetailsProvider provider,
  ) {
    return call(provider.id);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'challengeDetailsProvider';
}

/// See also [challengeDetails].
class ChallengeDetailsProvider extends AutoDisposeFutureProvider<Challenge> {
  /// See also [challengeDetails].
  ChallengeDetailsProvider(String id)
    : this._internal(
        (ref) => challengeDetails(ref as ChallengeDetailsRef, id),
        from: challengeDetailsProvider,
        name: r'challengeDetailsProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$challengeDetailsHash,
        dependencies: ChallengeDetailsFamily._dependencies,
        allTransitiveDependencies:
            ChallengeDetailsFamily._allTransitiveDependencies,
        id: id,
      );

  ChallengeDetailsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.id,
  }) : super.internal();

  final String id;

  @override
  Override overrideWith(
    FutureOr<Challenge> Function(ChallengeDetailsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ChallengeDetailsProvider._internal(
        (ref) => create(ref as ChallengeDetailsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        id: id,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<Challenge> createElement() {
    return _ChallengeDetailsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ChallengeDetailsProvider && other.id == id;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, id.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin ChallengeDetailsRef on AutoDisposeFutureProviderRef<Challenge> {
  /// The parameter `id` of this provider.
  String get id;
}

class _ChallengeDetailsProviderElement
    extends AutoDisposeFutureProviderElement<Challenge>
    with ChallengeDetailsRef {
  _ChallengeDetailsProviderElement(super.provider);

  @override
  String get id => (origin as ChallengeDetailsProvider).id;
}

String _$challengeLeaderboardHash() =>
    r'0d396987a316d660579141d2d7910d2e0fce2a8d';

/// See also [challengeLeaderboard].
@ProviderFor(challengeLeaderboard)
const challengeLeaderboardProvider = ChallengeLeaderboardFamily();

/// See also [challengeLeaderboard].
class ChallengeLeaderboardFamily extends Family<AsyncValue<LeaderboardData>> {
  /// See also [challengeLeaderboard].
  const ChallengeLeaderboardFamily();

  /// See also [challengeLeaderboard].
  ChallengeLeaderboardProvider call(String id) {
    return ChallengeLeaderboardProvider(id);
  }

  @override
  ChallengeLeaderboardProvider getProviderOverride(
    covariant ChallengeLeaderboardProvider provider,
  ) {
    return call(provider.id);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'challengeLeaderboardProvider';
}

/// See also [challengeLeaderboard].
class ChallengeLeaderboardProvider
    extends AutoDisposeFutureProvider<LeaderboardData> {
  /// See also [challengeLeaderboard].
  ChallengeLeaderboardProvider(String id)
    : this._internal(
        (ref) => challengeLeaderboard(ref as ChallengeLeaderboardRef, id),
        from: challengeLeaderboardProvider,
        name: r'challengeLeaderboardProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$challengeLeaderboardHash,
        dependencies: ChallengeLeaderboardFamily._dependencies,
        allTransitiveDependencies:
            ChallengeLeaderboardFamily._allTransitiveDependencies,
        id: id,
      );

  ChallengeLeaderboardProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.id,
  }) : super.internal();

  final String id;

  @override
  Override overrideWith(
    FutureOr<LeaderboardData> Function(ChallengeLeaderboardRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ChallengeLeaderboardProvider._internal(
        (ref) => create(ref as ChallengeLeaderboardRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        id: id,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<LeaderboardData> createElement() {
    return _ChallengeLeaderboardProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ChallengeLeaderboardProvider && other.id == id;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, id.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin ChallengeLeaderboardRef on AutoDisposeFutureProviderRef<LeaderboardData> {
  /// The parameter `id` of this provider.
  String get id;
}

class _ChallengeLeaderboardProviderElement
    extends AutoDisposeFutureProviderElement<LeaderboardData>
    with ChallengeLeaderboardRef {
  _ChallengeLeaderboardProviderElement(super.provider);

  @override
  String get id => (origin as ChallengeLeaderboardProvider).id;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
