import '../api_client.dart';

/// Node版本信息
class NodeVersion {
  final String version;
  final bool installed;
  final bool active;
  final String? lts;

  NodeVersion({
    required this.version,
    required this.installed,
    required this.active,
    this.lts,
  });

  factory NodeVersion.fromJson(Map<String, dynamic> json) {
    return NodeVersion(
      version: json['version'] as String,
      installed: json['installed'] as bool,
      active: json['active'] as bool,
      lts: json['lts'] as String?,
    );
  }
}

/// 管理器信息
class ManagerInfo {
  final String type;
  final String name;
  final bool installed;
  final String? version;
  final String? path;

  ManagerInfo({
    required this.type,
    required this.name,
    required this.installed,
    this.version,
    this.path,
  });

  factory ManagerInfo.fromJson(Map<String, dynamic> json) {
    return ManagerInfo(
      type: json['type'] as String,
      name: json['name'] as String,
      installed: json['installed'] as bool,
      version: json['version'] as String?,
      path: json['path'] as String?,
    );
  }
}

/// 操作结果
class OperationResult {
  final bool success;
  final String message;
  final dynamic data;

  OperationResult({
    required this.success,
    required this.message,
    this.data,
  });

  factory OperationResult.fromJson(Map<String, dynamic> json) {
    return OperationResult(
      success: json['success'] as bool,
      message: json['message'] as String,
      data: json['data'],
    );
  }
}

/// Node版本管理服务
class NodeService {
  final ApiClient _client;

  NodeService(this._client);

  /// 获取当前版本
  Future<String?> getCurrentVersion() async {
    try {
      final response = await _client.get<Map<String, dynamic>>(
        '/node/current',
        fromJsonT: (data) {
          if (data is Map<String, dynamic>) {
            return data;
          }
          if (data is Map) {
            return Map<String, dynamic>.from(data);
          }
          return <String, dynamic>{};
        },
      );
      if (response.success && response.data != null) {
        final data = response.data!;
        if (data['data'] != null && data['data'] is Map) {
          return (data['data'] as Map)['version'] as String?;
        }
      }
      return null;
    } catch (e) {
      print('获取当前版本失败: $e');
      return null;
    }
  }

  /// 获取已安装版本列表
  Future<List<NodeVersion>> getVersions() async {
    try {
      final response = await _client.get<List<dynamic>>(
        '/node/versions',
        fromJsonT: (data) => data is List ? data : (data as Map)['data'] as List? ?? [],
      );
      if (response.success && response.data != null) {
        final List<dynamic> data = response.data!;
        return data.map((json) => NodeVersion.fromJson(json as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (e) {
      print('获取版本列表失败: $e');
      return [];
    }
  }

  /// 获取可用版本列表（远程）
  Future<List<String>> getAvailableVersions() async {
    try {
      final response = await _client.get<List<dynamic>>(
        '/node/versions/available',
        fromJsonT: (data) => data is List ? data : (data as Map)['data'] as List? ?? [],
      );
      if (response.success && response.data != null) {
        final List<dynamic> data = response.data!;
        return data.map((v) => v.toString()).toList();
      }
      return [];
    } catch (e) {
      print('获取可用版本失败: $e');
      return [];
    }
  }

  /// 获取LTS版本列表
  Future<List<String>> getLTSVersions() async {
    try {
      final response = await _client.get<List<dynamic>>(
        '/node/versions/lts',
        fromJsonT: (data) => data is List ? data : (data as Map)['data'] as List? ?? [],
      );
      if (response.success && response.data != null) {
        final List<dynamic> data = response.data!;
        return data.map((v) => v.toString()).toList();
      }
      return [];
    } catch (e) {
      print('获取LTS版本失败: $e');
      return [];
    }
  }

  /// 安装版本
  Future<OperationResult> installVersion(String version) async {
    try {
      final response = await _client.post<Map<String, dynamic>>(
        '/node/versions',
        data: {'version': version},
        fromJsonT: (data) {
          if (data is Map<String, dynamic>) {
            return data;
          }
          if (data is Map) {
            return Map<String, dynamic>.from(data);
          }
          return <String, dynamic>{};
        },
      );
      if (response.success && response.data != null) {
        return OperationResult.fromJson(response.data!);
      }
      return OperationResult(
        success: false,
        message: response.error ?? '安装失败',
      );
    } catch (e) {
      print('安装版本失败: $e');
      return OperationResult(success: false, message: '安装失败: $e');
    }
  }

  /// 切换版本
  Future<OperationResult> switchVersion(String version) async {
    try {
      final response = await _client.put<Map<String, dynamic>>(
        '/node/versions/$version',
        fromJsonT: (data) {
          if (data is Map<String, dynamic>) {
            return data;
          }
          if (data is Map) {
            return Map<String, dynamic>.from(data);
          }
          return <String, dynamic>{};
        },
      );
      if (response.success && response.data != null) {
        return OperationResult.fromJson(response.data!);
      }
      return OperationResult(
        success: false,
        message: response.error ?? '切换失败',
      );
    } catch (e) {
      print('切换版本失败: $e');
      return OperationResult(success: false, message: '切换失败: $e');
    }
  }

  /// 删除版本
  Future<OperationResult> removeVersion(String version) async {
    try {
      final response = await _client.delete<Map<String, dynamic>>(
        '/node/versions/$version',
        fromJsonT: (data) {
          if (data is Map<String, dynamic>) {
            return data;
          }
          if (data is Map) {
            return Map<String, dynamic>.from(data);
          }
          return <String, dynamic>{};
        },
      );
      if (response.success && response.data != null) {
        return OperationResult.fromJson(response.data!);
      }
      return OperationResult(
        success: false,
        message: response.error ?? '删除失败',
      );
    } catch (e) {
      print('删除版本失败: $e');
      return OperationResult(success: false, message: '删除失败: $e');
    }
  }

  /// 获取管理器列表
  Future<List<ManagerInfo>> getManagers() async {
    try {
      final response = await _client.get<List<dynamic>>(
        '/node/managers',
        fromJsonT: (data) => data is List ? data : (data as Map)['data'] as List? ?? [],
      );
      if (response.success && response.data != null) {
        final List<dynamic> data = response.data!;
        return data.map((json) => ManagerInfo.fromJson(json as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (e) {
      print('获取管理器列表失败: $e');
      return [];
    }
  }

  /// 获取当前管理器
  Future<ManagerInfo?> getCurrentManager() async {
    try {
      final response = await _client.get<Map<String, dynamic>>(
        '/node/managers/current',
        fromJsonT: (data) {
          if (data is Map<String, dynamic>) {
            return data;
          }
          if (data is Map) {
            // 如果是 Map<dynamic, dynamic>，转换为 Map<String, dynamic>
            return Map<String, dynamic>.from(data);
          }
          // 如果 data 本身不是 Map，尝试从 data['data'] 获取
          if (data is Map && data.containsKey('data')) {
            final nestedData = data['data'];
            if (nestedData is Map<String, dynamic>) {
              return nestedData;
            }
            if (nestedData is Map) {
              return Map<String, dynamic>.from(nestedData);
            }
          }
          return <String, dynamic>{};
        },
      );
      if (response.success && response.data != null) {
        final data = response.data!;
        if (data.containsKey('data') && data['data'] is Map) {
          return ManagerInfo.fromJson(data['data'] as Map<String, dynamic>);
        }
        // 如果数据直接是 ManagerInfo
        return ManagerInfo.fromJson(data);
      }
      return null;
    } catch (e) {
      print('获取当前管理器失败: $e');
      return null;
    }
  }

  /// 切换管理器
  Future<OperationResult> switchManager(String type) async {
    try {
      final response = await _client.put<Map<String, dynamic>>(
        '/node/managers/$type',
        fromJsonT: (data) {
          if (data is Map<String, dynamic>) {
            return data;
          }
          if (data is Map) {
            return Map<String, dynamic>.from(data);
          }
          return <String, dynamic>{};
        },
      );
      if (response.success && response.data != null) {
        return OperationResult.fromJson(response.data!);
      }
      return OperationResult(
        success: false,
        message: response.error ?? '切换失败',
      );
    } catch (e) {
      print('切换管理器失败: $e');
      return OperationResult(success: false, message: '切换失败: $e');
    }
  }

  /// 获取安装管理器指引
  Future<OperationResult> getInstallManagerGuide(String type) async {
    try {
      final response = await _client.post<Map<String, dynamic>>(
        '/node/managers/$type/install',
        fromJsonT: (data) {
          if (data is Map<String, dynamic>) {
            return data;
          }
          if (data is Map) {
            return Map<String, dynamic>.from(data);
          }
          return <String, dynamic>{};
        },
      );
      if (response.success && response.data != null) {
        return OperationResult.fromJson(response.data!);
      }
      return OperationResult(
        success: false,
        message: response.error ?? '获取失败',
      );
    } catch (e) {
      print('获取安装指引失败: $e');
      return OperationResult(success: false, message: '获取失败: $e');
    }
  }
}



