import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/api/services/project_service.dart';
import '../../core/api/services/system_service.dart';
import '../../widgets/system_layout.dart';

class ProjectsPage extends ConsumerStatefulWidget {
  const ProjectsPage({super.key});

  @override
  ConsumerState<ProjectsPage> createState() => _ProjectsPageState();
}

class _ProjectsPageState extends ConsumerState<ProjectsPage> {
  final ProjectService _projectService = ProjectService(
    ApiClient(baseUrl: 'http://localhost:3001/api'),
  );
  final SystemService _systemService = SystemService(
    ApiClient(baseUrl: 'http://localhost:3001/api'),
  );
  
  List<Map<String, dynamic>> projects = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    loadProjects();
  }

  Future<void> loadProjects() async {
    setState(() => isLoading = true);
    try {
      final projectList = await _projectService.getProjects();
      setState(() {
        projects = projectList;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载项目失败: $e')),
        );
      }
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> showImportDialog() async {
    String? selectedPath;
    String? projectName;
    String? projectType;
    bool isAnalyzing = false;

    final pathController = TextEditingController();
    final nameController = TextEditingController();
    final typeController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('导入项目'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 项目路径选择
                const Text(
                  '项目路径',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: pathController,
                        decoration: const InputDecoration(
                          hintText: '点击右侧按钮选择目录',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                        ),
                        readOnly: true,
                        enabled: !isAnalyzing,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: isAnalyzing
                          ? null
                          : () async {
                              // 打开目录选择器
                              final path = await _systemService.selectDirectory(
                                title: '选择项目目录',
                              );
                              if (path != null && mounted) {
                                pathController.text = path;
                                selectedPath = path;
                                
                                // 分析项目，自动填充名称和类型
                                setDialogState(() {
                                  isAnalyzing = true;
                                });
                                
                                try {
                                  final analysis = await _projectService.analyzeProject(path);
                                  if (analysis != null && mounted) {
                                    projectName = analysis['name'] as String?;
                                    projectType = analysis['typeLabel'] as String? ?? 
                                                 analysis['type'] as String? ?? 
                                                 '未知';
                                    
                                    nameController.text = projectName ?? '';
                                    typeController.text = projectType ?? '';
                                  }
                                } catch (e) {
                                  print('分析项目失败: $e');
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('分析项目失败: $e'),
                                        duration: const Duration(seconds: 2),
                                      ),
                                    );
                                  }
                                } finally {
                                  if (mounted) {
                                    setDialogState(() {
                                      isAnalyzing = false;
                                    });
                                  }
                                }
                              }
                            },
                      icon: const Icon(Icons.folder_open, size: 18),
                      label: const Text('选择'),
                    ),
                  ],
                ),
                if (isAnalyzing) ...[
                  const SizedBox(height: 8),
                  const Row(
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 8),
                      Text(
                        '正在分析项目...',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                // 项目名称
                const Text(
                  '项目名称',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    hintText: '项目名称（自动填充）',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                  enabled: !isAnalyzing,
                ),
                const SizedBox(height: 16),
                // 项目类型
                const Text(
                  '项目类型',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: typeController,
                  decoration: const InputDecoration(
                    hintText: '项目类型（自动填充）',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                  readOnly: true,
                  enabled: false,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isAnalyzing ? null : () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: isAnalyzing || selectedPath == null
                  ? null
                  : () async {
                      Navigator.pop(context);
                      await importProject(
                        selectedPath!,
                        nameController.text.isNotEmpty
                            ? nameController.text
                            : null,
                      );
                    },
              child: const Text('导入'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> importProject(String path, [String? name]) async {
    try {
      final success = await _projectService.importProject(
        path: path,
        name: name,
      );
      
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('导入成功'),
              backgroundColor: Colors.green,
            ),
          );
          await loadProjects();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('导入失败'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导入失败: $e')),
        );
      }
    }
  }

  Future<void> deleteProject(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除这个项目吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final success = await _projectService.deleteProject(id);
        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('删除成功'),
              backgroundColor: Colors.green,
            ),
          );
          await loadProjects();
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('删除失败'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('删除失败: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SystemLayout(
      title: '项目管理',
      child: Column(
        children: [
          // 操作栏
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Row(
              children: [
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: showImportDialog,
                  tooltip: '导入项目',
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: loadProjects,
                  tooltip: '刷新',
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // 内容区域
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : projects.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.folder_open,
                                size: 64, color: Colors.grey),
                            const SizedBox(height: 16),
                            const Text('暂无项目',
                                style: TextStyle(color: Colors.grey)),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: showImportDialog,
                              icon: const Icon(Icons.add),
                              label: const Text('导入项目'),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: projects.length,
                        itemBuilder: (context, index) {
                          final project = projects[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: const Icon(Icons.folder, size: 40),
                              title: Text(project['name'] ?? ''),
                              subtitle: Text(
                                project['path'] ?? '',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (project['type'] != null)
                                    Chip(
                                      label: Text(
                                        _getTypeLabel(project['type']),
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                      padding: EdgeInsets.zero,
                                    ),
                                  if (project['framework'] != null) ...[
                                    const SizedBox(width: 8),
                                    Chip(
                                      label: Text(
                                        project['framework'],
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                      padding: EdgeInsets.zero,
                                    ),
                                  ],
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(Icons.delete,
                                        color: Colors.red),
                                    onPressed: () => deleteProject(project['id']),
                                    tooltip: '删除',
                                  ),
                                ],
                              ),
                              onTap: () {
                                // 打开项目详情
                              },
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  String _getTypeLabel(dynamic type) {
    if (type == null) return '未知';
    final typeMap = {
      'web': 'Web',
      'api': 'API',
      'other': '其他',
    };
    return typeMap[type.toString()] ?? type.toString();
  }
}
