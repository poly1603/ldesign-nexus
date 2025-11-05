import '../api_client.dart';

/// 系统信息
class SystemInfo {
  final OSInfo os;
  final CPUInfo cpu;
  final MemoryInfo memory;
  final DiskInfo? disk;
  final NetworkInfo network;

  SystemInfo({
    required this.os,
    required this.cpu,
    required this.memory,
    this.disk,
    required this.network,
  });

  factory SystemInfo.fromJson(Map<String, dynamic> json) {
    return SystemInfo(
      os: OSInfo.fromJson(json['os'] as Map<String, dynamic>),
      cpu: CPUInfo.fromJson(json['cpu'] as Map<String, dynamic>),
      memory: MemoryInfo.fromJson(json['memory'] as Map<String, dynamic>),
      disk: json['disk'] != null
          ? DiskInfo.fromJson(json['disk'] as Map<String, dynamic>)
          : null,
      network: NetworkInfo.fromJson(json['network'] as Map<String, dynamic>),
    );
  }
}

/// 操作系统信息
class OSInfo {
  final String platform;
  final String type;
  final String release;
  final String arch;
  final String hostname;
  final double uptime;

  OSInfo({
    required this.platform,
    required this.type,
    required this.release,
    required this.arch,
    required this.hostname,
    required this.uptime,
  });

  factory OSInfo.fromJson(Map<String, dynamic> json) {
    // 安全解析 uptime，确保不会是 Infinity 或 NaN
    final uptimeValue = CPUInfo._safeDouble(json['uptime'], 0.0);
    final safeUptime = uptimeValue.isNaN || uptimeValue.isInfinite || uptimeValue < 0
        ? 0.0
        : uptimeValue;
    
    return OSInfo(
      platform: json['platform'] as String? ?? 'Unknown',
      type: json['type'] as String? ?? 'Unknown',
      release: json['release'] as String? ?? 'Unknown',
      arch: json['arch'] as String? ?? 'Unknown',
      hostname: json['hostname'] as String? ?? 'Unknown',
      uptime: safeUptime,
    );
  }
}

/// CPU信息
class CPUInfo {
  final String model;
  final int cores;
  final double speed;
  final double usage;

  CPUInfo({
    required this.model,
    required this.cores,
    required this.speed,
    required this.usage,
  });

  factory CPUInfo.fromJson(Map<String, dynamic> json) {
    // 安全解析所有数值字段
    final speedValue = _safeDouble(json['speed'], 0.0);
    final usageValue = _safeDouble(json['usage'], 0.0);
    
    // 确保 speed 和 usage 都是有效值
    final safeSpeed = speedValue.isNaN || speedValue.isInfinite || speedValue < 0
        ? 0.0
        : speedValue;
    final safeUsage = usageValue.isNaN || usageValue.isInfinite || usageValue < 0
        ? 0.0
        : (usageValue > 100 ? 100.0 : usageValue); // 限制在 0-100 范围内
    
    return CPUInfo(
      model: json['model'] as String? ?? 'Unknown',
      cores: _safeInt(json['cores'], 0),
      speed: safeSpeed,
      usage: safeUsage,
    );
  }
  
  static int _safeInt(dynamic value, int defaultValue) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is double) {
      if (value.isNaN || value.isInfinite) return defaultValue;
      return value.toInt();
    }
    if (value is num) {
      final doubleVal = value.toDouble();
      if (doubleVal.isNaN || doubleVal.isInfinite) return defaultValue;
      return doubleVal.toInt();
    }
    return defaultValue;
  }
  
  static double _safeDouble(dynamic value, double defaultValue) {
    if (value == null) return defaultValue;
    if (value is double) {
      return value.isNaN || value.isInfinite ? defaultValue : value;
    }
    if (value is int) {
      return value.toDouble();
    }
    if (value is num) {
      final doubleVal = value.toDouble();
      return doubleVal.isNaN || doubleVal.isInfinite ? defaultValue : doubleVal;
    }
    return defaultValue;
  }
}

/// 内存信息
class MemoryInfo {
  final int total;
  final int free;
  final int used;
  final int usagePercent;

  MemoryInfo({
    required this.total,
    required this.free,
    required this.used,
    required this.usagePercent,
  });

  factory MemoryInfo.fromJson(Map<String, dynamic> json) {
    // 安全解析内存数据
    final total = CPUInfo._safeInt(json['total'], 0);
    final free = CPUInfo._safeInt(json['free'], 0);
    final used = CPUInfo._safeInt(json['used'], 0);
    var usagePercent = CPUInfo._safeInt(json['usagePercent'], 0);
    
    // 确保 usagePercent 在合理范围内
    if (usagePercent < 0) usagePercent = 0;
    if (usagePercent > 100) usagePercent = 100;
    
    return MemoryInfo(
      total: total < 0 ? 0 : total,
      free: free < 0 ? 0 : free,
      used: used < 0 ? 0 : used,
      usagePercent: usagePercent,
    );
  }
}

/// 磁盘信息
class DiskInfo {
  final int total;
  final int free;
  final int used;
  final int usagePercent;

  DiskInfo({
    required this.total,
    required this.free,
    required this.used,
    required this.usagePercent,
  });

  factory DiskInfo.fromJson(Map<String, dynamic> json) {
    // 安全解析磁盘数据
    final total = CPUInfo._safeInt(json['total'], 0);
    final free = CPUInfo._safeInt(json['free'], 0);
    final used = CPUInfo._safeInt(json['used'], 0);
    var usagePercent = CPUInfo._safeInt(json['usagePercent'], 0);
    
    // 确保 usagePercent 在合理范围内
    if (usagePercent < 0) usagePercent = 0;
    if (usagePercent > 100) usagePercent = 100;
    
    return DiskInfo(
      total: total < 0 ? 0 : total,
      free: free < 0 ? 0 : free,
      used: used < 0 ? 0 : used,
      usagePercent: usagePercent,
    );
  }
}

/// 网络信息
class NetworkInfo {
  final List<NetworkInterface> interfaces;

  NetworkInfo({required this.interfaces});

  factory NetworkInfo.fromJson(Map<String, dynamic> json) {
    final List<dynamic> interfacesList = json['interfaces'] as List<dynamic>;
    return NetworkInfo(
      interfaces: interfacesList
          .map((i) => NetworkInterface.fromJson(i as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// 网络接口
class NetworkInterface {
  final String name;
  final String address;
  final String family;
  final bool internal;

  NetworkInterface({
    required this.name,
    required this.address,
    required this.family,
    required this.internal,
  });

  factory NetworkInterface.fromJson(Map<String, dynamic> json) {
    return NetworkInterface(
      name: json['name'] as String,
      address: json['address'] as String,
      family: json['family'] as String,
      internal: json['internal'] as bool,
    );
  }
}

/// 系统信息服务
class SystemService {
  final ApiClient _client;

  SystemService(this._client);

  /// 获取系统信息
  Future<SystemInfo?> getSystemInfo() async {
    try {
      final response = await _client.get<Map<String, dynamic>>(
        '/system/info',
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
      
      print('系统信息 API 响应: success=${response.success}, data=${response.data}, error=${response.error}');
      
      if (response.success && response.data != null) {
        try {
          return SystemInfo.fromJson(response.data!);
        } catch (e) {
          print('解析系统信息失败: $e');
          print('数据内容: ${response.data}');
          return null;
        }
      } else {
        print('API 返回失败: ${response.error ?? "未知错误"}');
        return null;
      }
    } catch (e, stackTrace) {
      print('获取系统信息异常: $e');
      print('堆栈跟踪: $stackTrace');
      return null;
    }
  }

  /// 获取健康状态
  Future<Map<String, dynamic>?> getHealthStatus() async {
    try {
      final response = await _client.get<Map<String, dynamic>>(
        '/system/health',
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
        if (data.containsKey('data') && data['data'] is Map) {
          return data['data'] as Map<String, dynamic>;
        }
        return data;
      }
      return null;
    } catch (e) {
      print('获取健康状态失败: $e');
      return null;
    }
  }

  /// 选择目录
  Future<String?> selectDirectory({String? defaultPath, String? title}) async {
    try {
      final data = <String, dynamic>{};
      if (defaultPath != null) {
        data['defaultPath'] = defaultPath;
      }
      if (title != null) {
        data['title'] = title;
      }
      
      final response = await _client.post<String?>(
        '/system/select-directory',
        data: data,
        fromJsonT: (data) {
          if (data is String) {
            return data;
          }
          if (data is Map && data.containsKey('data')) {
            final result = data['data'];
            return result is String ? result : null;
          }
          return null;
        },
      );
      
      if (response.success && response.data != null && response.data!.isNotEmpty) {
        return response.data;
      }
      return null;
    } catch (e) {
      print('选择目录失败: $e');
      return null;
    }
  }
}

