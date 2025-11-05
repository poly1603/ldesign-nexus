import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api/services/node_service.dart';
import '../core/api/api_client.dart';

/// API Client Provider
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(baseUrl: 'http://localhost:3001/api');
});

/// Node Service Provider
final nodeServiceProvider = Provider<NodeService>((ref) {
  final client = ref.watch(apiClientProvider);
  return NodeService(client);
});

/// 当前版本 Provider
final currentVersionProvider = FutureProvider<String?>((ref) async {
  final service = ref.watch(nodeServiceProvider);
  return await service.getCurrentVersion();
});

/// 已安装版本列表 Provider
final installedVersionsProvider = FutureProvider<List<NodeVersion>>((ref) async {
  final service = ref.watch(nodeServiceProvider);
  return await service.getVersions();
});

/// 可用版本列表 Provider
final availableVersionsProvider = FutureProvider<List<String>>((ref) async {
  final service = ref.watch(nodeServiceProvider);
  return await service.getAvailableVersions();
});

/// LTS版本列表 Provider
final ltsVersionsProvider = FutureProvider<List<String>>((ref) async {
  final service = ref.watch(nodeServiceProvider);
  return await service.getLTSVersions();
});

/// 管理器列表 Provider
final managersProvider = FutureProvider<List<ManagerInfo>>((ref) async {
  final service = ref.watch(nodeServiceProvider);
  return await service.getManagers();
});

/// 当前管理器 Provider
final currentManagerProvider = FutureProvider<ManagerInfo?>((ref) async {
  final service = ref.watch(nodeServiceProvider);
  return await service.getCurrentManager();
});

/// Node页面状态管理
class NodePageState {
  final bool isLoading;
  final String? error;
  final bool isInstalling;
  final bool isSwitching;
  final bool isRemoving;

  NodePageState({
    this.isLoading = false,
    this.error,
    this.isInstalling = false,
    this.isSwitching = false,
    this.isRemoving = false,
  });

  NodePageState copyWith({
    bool? isLoading,
    String? error,
    bool? isInstalling,
    bool? isSwitching,
    bool? isRemoving,
  }) {
    return NodePageState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isInstalling: isInstalling ?? this.isInstalling,
      isSwitching: isSwitching ?? this.isSwitching,
      isRemoving: isRemoving ?? this.isRemoving,
    );
  }
}

/// Node页面状态 Provider
class NodePageNotifier extends StateNotifier<NodePageState> {
  final NodeService _service;
  final Ref _ref;

  NodePageNotifier(this._service, this._ref) : super(NodePageState());

  /// 安装版本
  Future<bool> installVersion(String version) async {
    state = state.copyWith(isInstalling: true, error: null);
    try {
      final result = await _service.installVersion(version);
      if (result.success) {
        // 刷新版本列表
        _ref.invalidate(installedVersionsProvider);
        _ref.invalidate(currentVersionProvider);
      }
      state = state.copyWith(isInstalling: false, error: result.success ? null : result.message);
      return result.success;
    } catch (e) {
      state = state.copyWith(isInstalling: false, error: e.toString());
      return false;
    }
  }

  /// 切换版本
  Future<bool> switchVersion(String version) async {
    state = state.copyWith(isSwitching: true, error: null);
    try {
      final result = await _service.switchVersion(version);
      if (result.success) {
        // 刷新状态
        _ref.invalidate(currentVersionProvider);
        _ref.invalidate(installedVersionsProvider);
      }
      state = state.copyWith(isSwitching: false, error: result.success ? null : result.message);
      return result.success;
    } catch (e) {
      state = state.copyWith(isSwitching: false, error: e.toString());
      return false;
    }
  }

  /// 删除版本
  Future<bool> removeVersion(String version) async {
    state = state.copyWith(isRemoving: true, error: null);
    try {
      final result = await _service.removeVersion(version);
      if (result.success) {
        // 刷新版本列表
        _ref.invalidate(installedVersionsProvider);
      }
      state = state.copyWith(isRemoving: false, error: result.success ? null : result.message);
      return result.success;
    } catch (e) {
      state = state.copyWith(isRemoving: false, error: e.toString());
      return false;
    }
  }

  /// 切换管理器
  Future<bool> switchManager(String type) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await _service.switchManager(type);
      if (result.success) {
        // 刷新管理器状态
        _ref.invalidate(currentManagerProvider);
        _ref.invalidate(managersProvider);
      }
      state = state.copyWith(isLoading: false, error: result.success ? null : result.message);
      return result.success;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  /// 刷新所有数据
  void refreshAll() {
    _ref.invalidate(currentVersionProvider);
    _ref.invalidate(installedVersionsProvider);
    _ref.invalidate(managersProvider);
    _ref.invalidate(currentManagerProvider);
  }
}

final nodePageProvider = StateNotifierProvider<NodePageNotifier, NodePageState>((ref) {
  final service = ref.watch(nodeServiceProvider);
  return NodePageNotifier(service, ref);
});



