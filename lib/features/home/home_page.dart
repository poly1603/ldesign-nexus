import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/system_layout.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SystemLayout(
      title: 'LDesign 管理平台',
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 欢迎信息
            Text(
              '欢迎使用 LDesign 管理平台',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              '选择下面的功能开始使用',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
            ),
            const SizedBox(height: 24),

            // 功能卡片网格
            Expanded(
              child: GridView.count(
                crossAxisCount: 3,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _buildFeatureCard(
                    context,
                    icon: Icons.folder,
                    title: '项目管理',
                    description: '管理和浏览您的项目',
                    onTap: () => context.go('/projects'),
                  ),
                  _buildFeatureCard(
                    context,
                    icon: Icons.circle,
                    title: 'Node 管理',
                    description: '管理 Node.js 版本',
                    color: Colors.green,
                    onTap: () => context.go('/node'),
                  ),
                  _buildFeatureCard(
                    context,
                    icon: Icons.code,
                    title: 'Git 管理',
                    description: '检测和配置 Git 环境',
                    onTap: () => context.go('/git'),
                  ),
                  _buildFeatureCard(
                    context,
                    icon: Icons.computer,
                    title: '系统工具',
                    description: '系统信息和工具',
                    onTap: () => context.go('/system'),
                  ),
                  _buildFeatureCard(
                    context,
                    icon: Icons.list_alt,
                    title: '日志查看',
                    description: '查看应用日志',
                    onTap: () => context.go('/logs'),
                  ),
                  _buildFeatureCard(
                    context,
                    icon: Icons.settings,
                    title: '设置',
                    description: '应用程序设置',
                    onTap: () => context.go('/settings'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
    Color? color,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 48,
                color: color ?? Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
