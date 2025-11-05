import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/server/server_manager.dart';

/// 无动画的页面过渡构建器
class NoAnimationPageTransitionsBuilder extends PageTransitionsBuilder {
  const NoAnimationPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // 直接返回子组件，无任何动画
    return child;
  }
}

class LDesignApp extends ConsumerStatefulWidget {
  const LDesignApp({super.key});

  @override
  ConsumerState<LDesignApp> createState() => _LDesignAppState();
}

class _LDesignAppState extends ConsumerState<LDesignApp> {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    // 使用 Future.microtask 确保 ref 已经准备好
    Future.microtask(() => _initializeApp());
  }

  /// 初始化应用，快速启动，后台等待服务器
  Future<void> _initializeApp() async {
    // 等待一帧，确保 ref 已经准备好
    await Future.delayed(const Duration(milliseconds: 100));
    
    if (!mounted) return;
    
    final serverManager = ref.read(serverManagerProvider);
    
    // 快速检查服务器（最多等待3秒），如果没就绪就继续运行
    // 服务器会在后台继续尝试连接
    final isReady = await serverManager.waitForServer(
      timeout: const Duration(seconds: 3), // 缩短到3秒
    );
    
    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
      
      if (isReady) {
        print('✅ 服务器连接成功');
      } else {
        print('⚠️  服务器未就绪，应用将继续运行，后台重试连接中...');
        // 后台继续尝试连接
        _retryServerConnection(serverManager);
      }
    }
  }
  
  /// 后台重试服务器连接
  void _retryServerConnection(ServerManager serverManager) {
    Future.delayed(const Duration(seconds: 2), () async {
      if (!mounted) return;
      final isReady = await serverManager.waitForServer(
        timeout: const Duration(seconds: 10),
      );
      if (isReady) {
        print('✅ 服务器连接成功（后台重试）');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    // 如果还在初始化，显示加载界面
    if (!_isInitialized) {
      return MaterialApp(
        title: 'LDesign',
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.system,
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: const Color(0xFFFAFAFA),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  '正在连接服务器...',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return MaterialApp.router(
      title: 'LDesign',
      theme: AppTheme.light.copyWith(
        // 禁用页面过渡动画
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.windows: NoAnimationPageTransitionsBuilder(),
            TargetPlatform.macOS: NoAnimationPageTransitionsBuilder(),
            TargetPlatform.linux: NoAnimationPageTransitionsBuilder(),
          },
        ),
      ),
      darkTheme: AppTheme.dark.copyWith(
        // 禁用页面过渡动画
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.windows: NoAnimationPageTransitionsBuilder(),
            TargetPlatform.macOS: NoAnimationPageTransitionsBuilder(),
            TargetPlatform.linux: NoAnimationPageTransitionsBuilder(),
          },
        ),
      ),
      themeMode: ThemeMode.system,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
