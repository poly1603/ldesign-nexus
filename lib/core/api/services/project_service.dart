import '../api_client.dart';

/// 项目服务
class ProjectService {
  final ApiClient _client;

  ProjectService(this._client);

  /// 获取项目列表
  Future<List<Map<String, dynamic>>> getProjects() async {
    final response = await _client.get<List<dynamic>>(
      '/projects',
      fromJsonT: (data) {
        if (data is List) {
          return data.map((item) => item as Map<String, dynamic>).toList();
        }
        return <dynamic>[];
      },
    );
    
    if (response.success && response.data != null) {
      return response.data!.cast<Map<String, dynamic>>();
    }
    return [];
  }

  /// 分析项目（获取项目信息）
  Future<Map<String, dynamic>?> analyzeProject(String path) async {
    try {
      final response = await _client.post<Map<String, dynamic>>(
        '/projects/analyze',
        data: {'path': path},
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
        return response.data!;
      }
      return null;
    } catch (e) {
      print('分析项目失败: $e');
      return null;
    }
  }

  /// 导入项目
  Future<bool> importProject({
    required String path,
    String? name,
  }) async {
    try {
      final data = <String, dynamic>{
        'path': path,
      };
      if (name != null && name.isNotEmpty) {
        data['name'] = name;
      }
      
      final response = await _client.post<Map<String, dynamic>>(
        '/projects/import',
        data: data,
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
      
      return response.success;
    } catch (e) {
      print('导入项目失败: $e');
      return false;
    }
  }

  /// 删除项目
  Future<bool> deleteProject(String id) async {
    try {
      final response = await _client.delete<Map<String, dynamic>>(
        '/projects/$id',
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
      
      return response.success;
    } catch (e) {
      print('删除项目失败: $e');
      return false;
    }
  }
}

