import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';
import 'app.dart';
import 'core/server/server_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 配置窗口管理器
  await windowManager.ensureInitialized();
  
  WindowOptions windowOptions = const WindowOptions(
    size: Size(1200, 800),
    minimumSize: Size(800, 600),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.normal,
    title: 'LDesign',
  );
  
  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  // 启动后端服务器
  final serverManager = ServerManager();
  
  // 异步启动服务器，不阻塞 UI
  // 应用会在 app.dart 中等待服务器就绪
  serverManager.startServer().then((success) {
    if (success) {
      print('✅ Server started successfully');
    } else {
      print('⚠️  Server startup failed, but continuing...');
      print('💡 Please ensure server is running on port 3001');
    }
  }).catchError((error) {
    print('❌ Server startup error: $error');
    print('💡 Please start server manually: cd tools/server && pnpm start:dev');
  });

  runApp(
    ProviderScope(
      overrides: [
        serverManagerProvider.overrideWith((ref) => ServerManager()),
      ],
      child: const LDesignApp(),
    ),
  );
}
