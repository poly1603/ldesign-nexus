import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/home/home_page.dart';
import '../../features/projects/projects_page.dart';
import '../../features/node/node_page.dart';
import '../../features/git/git_page.dart';
import '../../features/system/system_page.dart';
import '../../features/logs/logs_page.dart';
import '../../features/settings/settings_page.dart';

/// 路由配置
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: '/projects',
        name: 'projects',
        builder: (context, state) => const ProjectsPage(),
      ),
      GoRoute(
        path: '/node',
        name: 'node',
        builder: (context, state) => const NodePage(),
      ),
      GoRoute(
        path: '/git',
        name: 'git',
        builder: (context, state) => const GitPage(),
      ),
      GoRoute(
        path: '/system',
        name: 'system',
        builder: (context, state) => const SystemPage(),
      ),
      GoRoute(
        path: '/logs',
        name: 'logs',
        builder: (context, state) => const LogsPage(),
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsPage(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('页面未找到: ${state.uri.path}'),
      ),
    ),
  );
});
