import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/server/server_manager.dart';

/// 系统布局组件
/// 包含左侧菜单、顶部头部和内容区域
class SystemLayout extends ConsumerWidget {
  final Widget child;
  final String? title;

  const SystemLayout({
    super.key,
    required this.child,
    this.title,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final serverManager = ref.watch(serverManagerProvider);
    final currentPath = GoRouterState.of(context).uri.path;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA), // #fafafa - 匹配 Web 版本的内容背景色
      body: Row(
        children: [
          // 左侧菜单
          _buildSidebar(context, currentPath),
          // 主内容区域
          Expanded(
            child: Column(
              children: [
                // 顶部头部
                _buildHeader(context, ref, serverManager),
                // 内容区域 - 添加淡入动画
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    switchInCurve: Curves.easeInOut,
                    switchOutCurve: Curves.easeInOut,
                    transitionBuilder: (Widget child, Animation<double> animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: child,
                      );
                    },
                    child: Container(
                      key: ValueKey(currentPath), // 使用路径作为 key，确保路由切换时触发动画
                      color: const Color(0xFFFAFAFA), // #fafafa
                      child: child,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建左侧菜单
  Widget _buildSidebar(BuildContext context, String currentPath) {
    // 匹配 Web 版本的菜单项，使用 Material Icons
    final menuItems = [
      _MenuItem(
        icon: Icons.home, // 首页
        title: '首页',
        path: '/',
      ),
      _MenuItem(
        icon: Icons.folder, // 项目管理
        title: '项目管理',
        path: '/projects',
      ),
      _MenuItem(
        icon: Icons.circle, // Node 管理
        title: 'Node 管理',
        path: '/node',
        iconColor: Colors.green,
      ),
      _MenuItem(
        icon: Icons.code, // Git 管理
        title: 'Git 管理',
        path: '/git',
      ),
      _MenuItem(
        icon: Icons.computer, // 系统工具
        title: '系统工具',
        path: '/system',
      ),
      _MenuItem(
        icon: Icons.list_alt, // 日志查看
        title: '日志查看',
        path: '/logs',
      ),
      _MenuItem(
        icon: Icons.settings, // 设置
        title: '设置',
        path: '/settings',
      ),
    ];

    return Container(
      width: 240,
      decoration: BoxDecoration(
        color: Colors.white, // 匹配 Web 版本的白色背景
        border: Border(
          right: BorderSide(
            color: const Color(0xFFE0E0E0), // #e0e0e0 - 匹配 Web 版本的边框色
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Logo 区域
          Container(
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Color(0xFFE0E0E0), // #e0e0e0
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.build, // 使用 Material Icons 替换 emoji
                  size: 24,
                  color: const Color(0xFF4CAF50), // #4caf50 - 匹配 Web 版本的主题色
                ),
                const SizedBox(width: 12),
                Text(
                  'LDesign',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: const Color(0xFF4CAF50), // #4caf50 - 匹配 Web 版本的主题色
                      ),
                ),
              ],
            ),
          ),
          // 菜单项
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: menuItems.map((item) {
                final isActive = currentPath == item.path;
                return _buildMenuItem(context, item, isActive);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建菜单项
  Widget _buildMenuItem(BuildContext context, _MenuItem item, bool isActive) {
    // 固定高度，避免点击时布局跳动
    return Container(
      height: 48, // 固定高度：12px padding * 2 + 24px 内容
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isActive
            ? const Color(0xFFE8F5E9) // #e8f5e9 - 匹配 Web 版本的 active 背景色
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.go(item.path),
          borderRadius: BorderRadius.circular(8),
          // 匹配 Web 版本的 hover 效果：#f5f5f5
          hoverColor: isActive ? null : const Color(0xFFF5F5F5),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
              children: [
                // 图标 - 使用 Material Icons
                SizedBox(
                  width: 24,
                  child: Icon(
                    item.icon,
                    size: 20,
                    color: isActive
                        ? const Color(0xFF4CAF50) // #4caf50 - 匹配 Web 版本的主题色
                        : (item.iconColor ?? const Color(0xFF333333)), // #333 - 匹配 Web 版本的文本色
                  ),
                ),
                const SizedBox(width: 12),
                // 文本
                Expanded(
                  child: Text(
                    item.title,
                    style: TextStyle(
                      color: isActive
                          ? const Color(0xFF4CAF50) // #4caf50
                          : const Color(0xFF333333), // #333
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 构建顶部头部
  Widget _buildHeader(
    BuildContext context,
    WidgetRef ref,
    ServerManager serverManager,
  ) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white, // 匹配 Web 版本的白色背景
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFFE0E0E0), // #e0e0e0 - 匹配 Web 版本的边框色
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // 标题
          if (title != null)
            Text(
              title!,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 20,
                    color: const Color(0xFF333333), // #333 - 匹配 Web 版本的文本色
                  ),
            ),
          const Spacer(),
          // 服务器状态
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: serverManager.isRunning
                  ? const Color(0xFFE8F5E9) // #e8f5e9 - 匹配 Web 版本的 success 背景色
                  : const Color(0xFFFFEBEE), // #ffebee - 匹配 Web 版本的 error 背景色
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: serverManager.isRunning
                    ? const Color(0xFF4CAF50) // #4caf50
                    : const Color(0xFFF44336), // #f44336
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  serverManager.isRunning ? Icons.check_circle : Icons.error,
                  size: 14,
                  color: serverManager.isRunning
                      ? const Color(0xFF4CAF50) // #4caf50
                      : const Color(0xFFF44336), // #f44336
                ),
                const SizedBox(width: 8),
                Text(
                  serverManager.isRunning ? '服务器运行中' : '服务器未运行',
                  style: TextStyle(
                    fontSize: 12,
                    color: serverManager.isRunning
                        ? const Color(0xFF4CAF50) // #4caf50
                        : const Color(0xFFF44336), // #f44336
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '端口: ${serverManager.port}',
                  style: TextStyle(
                    fontSize: 11,
                    color: serverManager.isRunning
                        ? const Color(0xFF4CAF50).withOpacity(0.7)
                        : const Color(0xFFF44336).withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 菜单项数据类
class _MenuItem {
  final IconData icon; // 使用 IconData 存储 Material Icons
  final String title;
  final String path;
  final Color? iconColor; // 可选的图标颜色

  _MenuItem({
    required this.icon,
    required this.title,
    required this.path,
    this.iconColor,
  });
}


