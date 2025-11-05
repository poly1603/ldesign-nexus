import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/node_provider.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/loading_spinner.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/system_layout.dart';

/// Node版本管理页面
class NodePage extends ConsumerStatefulWidget {
  const NodePage({super.key});

  @override
  ConsumerState<NodePage> createState() => _NodePageState();
}

class _NodePageState extends ConsumerState<NodePage> {
  String? selectedVersion;
  final TextEditingController _customVersionController = TextEditingController();

  @override
  void dispose() {
    _customVersionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentVersion = ref.watch(currentVersionProvider);
    final installedVersions = ref.watch(installedVersionsProvider);
    final managers = ref.watch(managersProvider);
    final currentManager = ref.watch(currentManagerProvider);
    final pageState = ref.watch(nodePageProvider);

    return SystemLayout(
      title: 'Node 版本管理',
      child: Column(
        children: [
          // 操作栏
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Row(
              children: [
                if (currentManager.hasValue && currentManager.value != null)
                  StatusBadge(
                    label: currentManager.value!.name,
                    type: BadgeType.success,
                    small: true,
                  ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () {
                    ref.read(nodePageProvider.notifier).refreshAll();
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // 内容区域
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 当前版本卡片
                  _buildCurrentVersionCard(currentVersion),
                  const SizedBox(height: 16),

                  // 版本管理工具
                  _buildManagersCard(managers, currentManager),
                  const SizedBox(height: 16),

                  // 已安装版本列表
                  _buildInstalledVersionsCard(installedVersions, pageState),
                ],
              ),
            ),
          ),
          // 底部操作按钮
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FloatingActionButton.extended(
                  onPressed: () => _showInstallDialog(context),
                  icon: const Icon(Icons.add),
                  label: const Text('安装新版本'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建当前版本卡片
  Widget _buildCurrentVersionCard(AsyncValue<String?> currentVersion) {
    return CustomCard(
      title: const Text('当前版本'),
      child: currentVersion.when(
        data: (version) {
          if (version != null) {
            return Center(
              child: Column(
                children: [
                  Text(
                    'v$version',
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '当前使用版本',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          } else {
            return Center(
              child: Column(
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 8),
                  const Text('未检测到 Node.js'),
                  const SizedBox(height: 4),
                  Text(
                    '请安装一个版本',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }
        },
        loading: () => const LoadingSpinner(text: '加载中...'),
        error: (error, stack) => Center(
          child: Text('加载失败: $error'),
        ),
      ),
    );
  }

  /// 构建管理器卡片
  Widget _buildManagersCard(
    AsyncValue<List<dynamic>> managers,
    AsyncValue<dynamic> currentManager,
  ) {
    return CustomCard(
      title: const Text('版本管理工具'),
      child: managers.when(
        data: (managersList) {
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: managersList.map((manager) {
              final isCurrent = currentManager.hasValue &&
                  currentManager.value?.type == manager.type;
              return _buildManagerChip(manager, isCurrent);
            }).toList(),
          );
        },
        loading: () => const LoadingSpinner(),
        error: (error, stack) => Text('加载失败: $error'),
      ),
    );
  }

  /// 构建管理器芯片
  Widget _buildManagerChip(dynamic manager, bool isCurrent) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(
          color: manager.installed ? Colors.green : Colors.grey[300]!,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(8),
        color: manager.installed ? Colors.green[50] : Colors.grey[50],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                manager.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 8),
              if (manager.installed)
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            manager.installed ? '✓ 已安装' : '✗ 未安装',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          if (!manager.installed)
            CustomButton(
              label: '安装',
              small: true,
              type: ButtonType.outlined,
              onPressed: () => _showManagerInstallGuide(manager.type),
            )
          else if (isCurrent)
            const StatusBadge(label: '当前使用', type: BadgeType.primary, small: true)
          else
            CustomButton(
              label: '切换',
              small: true,
              type: ButtonType.primary,
              onPressed: () => _switchManager(manager.type),
            ),
        ],
      ),
    );
  }

  /// 构建已安装版本卡片
  Widget _buildInstalledVersionsCard(
    AsyncValue<List<dynamic>> versions,
    dynamic pageState,
  ) {
    return CustomCard(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('已安装版本'),
          CustomButton(
            label: '安装新版本',
            small: true,
            type: ButtonType.primary,
            icon: Icons.add,
            onPressed: () => _showInstallDialog(context),
          ),
        ],
      ),
      child: versions.when(
        data: (versionsList) {
          if (versionsList.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(Icons.inbox, size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    const Text('暂无已安装的版本'),
                    const SizedBox(height: 8),
                    Text(
                      '点击右上角按钮安装新版本',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            );
          }

          return Column(
            children: versionsList.map((version) {
              return _buildVersionItem(version, pageState);
            }).toList(),
          );
        },
        loading: () => const LoadingSpinner(text: '加载版本列表...'),
        error: (error, stack) => Text('加载失败: $error'),
      ),
    );
  }

  /// 构建版本项
  Widget _buildVersionItem(dynamic version, dynamic pageState) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(
          color: version.active ? Colors.blue : Colors.grey[300]!,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(8),
        color: version.active ? Colors.blue[50] : Colors.white,
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                if (version.active)
                  const StatusBadge(label: '当前', type: BadgeType.success, small: true),
                if (version.lts != null) ...[
                  const SizedBox(width: 8),
                  const StatusBadge(label: 'LTS', type: BadgeType.warning, small: true),
                ],
                const SizedBox(width: 12),
                Text(
                  'v${version.version}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
          if (!version.active) ...[
            CustomButton(
              label: '切换',
              small: true,
              type: ButtonType.primary,
              isLoading: pageState.isSwitching,
              onPressed: () => _switchVersion(version.version),
            ),
            const SizedBox(width: 8),
            CustomButton(
              label: '删除',
              small: true,
              type: ButtonType.danger,
              isLoading: pageState.isRemoving,
              onPressed: () => _removeVersion(version.version),
            ),
          ],
        ],
      ),
    );
  }

  /// 显示安装对话框
  void _showInstallDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _InstallDialog(
        onInstall: (version) {
          _installVersion(version);
          Navigator.of(context).pop();
        },
      ),
    );
  }

  /// 安装版本
  Future<void> _installVersion(String version) async {
    final success = await ref.read(nodePageProvider.notifier).installVersion(version);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? '安装成功' : '安装失败'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  /// 切换版本
  Future<void> _switchVersion(String version) async {
    final success = await ref.read(nodePageProvider.notifier).switchVersion(version);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? '切换成功' : '切换失败'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  /// 删除版本
  Future<void> _removeVersion(String version) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除版本 v$version 吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await ref.read(nodePageProvider.notifier).removeVersion(version);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? '删除成功' : '删除失败'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }

  /// 切换管理器
  Future<void> _switchManager(String type) async {
    final success = await ref.read(nodePageProvider.notifier).switchManager(type);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? '切换成功' : '切换失败'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  /// 显示管理器安装指引
  Future<void> _showManagerInstallGuide(String type) async {
    final service = ref.read(nodeServiceProvider);
    final result = await service.getInstallManagerGuide(type);

    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('安装管理器'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(result.message),
                if (result.data?['installCommand'] != null) ...[
                  const SizedBox(height: 16),
                  const Text('安装命令:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SelectableText(
                      result.data!['installCommand'] as String,
                      style: const TextStyle(
                        color: Colors.white,
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '复制上面的命令在终端中执行',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('知道了'),
            ),
          ],
        ),
      );
    }
  }
}

/// 安装对话框
class _InstallDialog extends ConsumerStatefulWidget {
  final Function(String) onInstall;

  const _InstallDialog({required this.onInstall});

  @override
  ConsumerState<_InstallDialog> createState() => _InstallDialogState();
}

class _InstallDialogState extends ConsumerState<_InstallDialog> {
  String? selectedVersion;
  final TextEditingController _customVersionController = TextEditingController();

  @override
  void dispose() {
    _customVersionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final availableVersions = ref.watch(availableVersionsProvider);
    final ltsVersions = ref.watch(ltsVersionsProvider);

    return AlertDialog(
      title: const Text('安装 Node.js 版本'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('选择版本:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            availableVersions.when(
              data: (versions) {
                return DropdownButtonFormField<String>(
                  value: selectedVersion,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  hint: const Text('-- 请选择版本 --'),
                  items: [
                    if (ltsVersions.hasValue && ltsVersions.value!.isNotEmpty)
                      ...ltsVersions.value!.take(10).map(
                            (v) => DropdownMenuItem(
                              value: v,
                              child: Text('v$v (LTS)'),
                            ),
                          ),
                    ...versions.take(50).map(
                          (v) => DropdownMenuItem(
                            value: v,
                            child: Text('v$v'),
                          ),
                        ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      selectedVersion = value;
                      _customVersionController.clear();
                    });
                  },
                );
              },
              loading: () => const LoadingSpinner(),
              error: (error, stack) => Text('加载失败: $error'),
            ),
            const SizedBox(height: 16),
            const Text('或输入版本号:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _customVersionController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: '例如: 20.10.0',
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              onChanged: (value) {
                if (value.isNotEmpty) {
                  setState(() {
                    selectedVersion = null;
                  });
                }
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: () {
            final version = _customVersionController.text.isNotEmpty
                ? _customVersionController.text
                : selectedVersion;
            if (version != null && version.isNotEmpty) {
              widget.onInstall(version);
            }
          },
          child: const Text('安装'),
        ),
      ],
    );
  }
}
