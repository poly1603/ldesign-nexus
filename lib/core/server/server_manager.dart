import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;

/// 服务器状态
class ServerState {
  final bool isRunning;
  final int port;
  final String? serverUrl;

  ServerState({
    required this.isRunning,
    required this.port,
    this.serverUrl,
  });

  ServerState copyWith({
    bool? isRunning,
    int? port,
    String? serverUrl,
  }) {
    return ServerState(
      isRunning: isRunning ?? this.isRunning,
      port: port ?? this.port,
      serverUrl: serverUrl ?? this.serverUrl,
    );
  }
}

/// 服务器管理器
class ServerManager extends StateNotifier<ServerState> {
  Process? _serverProcess;
  Timer? _healthCheckTimer;

  ServerManager()
      : super(ServerState(
          isRunning: false,
          port: 3001,
        )) {
    // 启动时立即检查服务器状态
    _checkServerStatus();
    // 定期检查服务器状态（每5秒）
    _healthCheckTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _checkServerStatus();
    });
  }

  @override
  void dispose() {
    _healthCheckTimer?.cancel();
    super.dispose();
  }

  /// 检查服务器状态
  Future<void> _checkServerStatus() async {
    final isHealthy = await checkServerHealth();
    if (isHealthy != state.isRunning) {
      state = state.copyWith(
        isRunning: isHealthy,
        serverUrl: isHealthy ? 'http://localhost:${state.port}' : null,
      );
    }
  }

  bool get isRunning => state.isRunning;
  int get port => state.port;
  String get serverUrl => state.serverUrl ?? 'http://localhost:${state.port}';

  /// 启动服务器
  Future<bool> startServer() async {
    if (state.isRunning) {
      print('Server is already running');
      return true;
    }

    try {
      // 先检查服务器是否已经在运行
      final isHealthy = await checkServerHealth();
      if (isHealthy) {
        print('Server is already running and healthy');
        state = state.copyWith(
          isRunning: true,
          serverUrl: 'http://localhost:${state.port}',
        );
        return true;
      }

      // 优先使用 pnpm start:prod 启动服务器
      final serverDir = await _getServerDirectory();
      if (serverDir != null) {
        print('Starting server from: $serverDir');
        
        // 使用 pnpm start:prod 启动服务器
        _serverProcess = await Process.start(
          'pnpm',
          ['start:prod'],
          workingDirectory: serverDir,
          environment: {
            'PORT': state.port.toString(),
            'NODE_ENV': 'production',
          },
          runInShell: true, // 确保在 shell 中运行，以便 pnpm 命令可用
        );

        // 监听服务器输出
        _serverProcess!.stdout.transform(utf8.decoder).listen((data) {
          print('Server stdout: $data');
        });

        _serverProcess!.stderr.transform(utf8.decoder).listen((data) {
          print('Server stderr: $data');
        });

        // 等待服务器启动并进行健康检查
        bool serverReady = false;
        for (int i = 0; i < 20; i++) { // 尝试20次，每次等待1秒
          await Future.delayed(const Duration(seconds: 1));
          if (await checkServerHealth()) {
            serverReady = true;
            break;
          }
          print('Waiting for server to be ready...');
        }

        if (!serverReady) {
          print('Server did not become ready in time.');
          await stopServer();
          return false;
        }

        state = state.copyWith(
          isRunning: true,
          serverUrl: 'http://localhost:${state.port}',
        );
        print('Server started successfully on port ${state.port}');
        return true;
      } else {
        print('Server directory not found. Trying alternative methods...');
        // 回退到其他启动方式
        return await _startViaCLI();
      }
    } catch (e) {
      print('Failed to start server: $e');
      // 尝试通过 CLI 启动
      return await _startViaCLI();
    }
  }

  /// 通过 CLI 启动服务器
  Future<bool> _startViaCLI() async {
    try {
      // 获取项目根目录
      final currentDir = Directory.current.path;
      final possibleRoots = [
        currentDir,
        path.join(currentDir, '..'),
        path.join(currentDir, '..', '..'),
      ];

      String? toolsDir;
      for (final root in possibleRoots) {
        final cliPath = path.join(root, 'tools', 'cli');
        if (await Directory(cliPath).exists()) {
          toolsDir = root;
          break;
        }
      }

      if (toolsDir == null) {
        print('Cannot find tools directory');
        return false;
      }

      print('Starting server via CLI...');
      
      // 使用 Node.js 直接运行 CLI 的 UI 命令（仅启动 server）
      final cliScript = path.join(toolsDir, 'tools', 'cli', 'dist', 'index.js');
      if (!await File(cliScript).exists()) {
        print('CLI script not found: $cliScript');
        return false;
      }

      // 启动 server-only 模式
      _serverProcess = await Process.start(
        'node',
        [cliScript, 'ui', '--server-only', '--no-open'],
        workingDirectory: path.join(toolsDir, 'tools', 'server'),
        environment: {
          'PORT': state.port.toString(),
          'NODE_ENV': 'development',
        },
        mode: ProcessStartMode.detached,
      );

      // 监听输出
      _serverProcess!.stdout.transform(utf8.decoder).listen((data) {
        print('CLI stdout: $data');
      });

      _serverProcess!.stderr.transform(utf8.decoder).listen((data) {
        print('CLI stderr: $data');
      });

      // 等待服务器启动
      for (int i = 0; i < 15; i++) {
        await Future.delayed(const Duration(seconds: 1));
        if (await checkServerHealth()) {
          state = state.copyWith(
            isRunning: true,
            serverUrl: 'http://localhost:${state.port}',
          );
          print('Server started successfully via CLI on port ${state.port}');
          return true;
        }
      }

      return false;
    } catch (e) {
      print('Failed to start server via CLI: $e');
      return false;
    }
  }

  /// 停止服务器
  Future<void> stopServer() async {
    if (_serverProcess != null) {
      try {
        _serverProcess!.kill();
        await _serverProcess!.exitCode.timeout(
          const Duration(seconds: 2),
          onTimeout: () {
            _serverProcess!.kill(ProcessSignal.sigkill);
            return 0;
          },
        );
      } catch (e) {
        print('Error stopping server: $e');
      } finally {
        _serverProcess = null;
        state = state.copyWith(
          isRunning: false,
          serverUrl: null,
        );
        print('Server stopped');
      }
    }
  }

  /// 获取服务器目录
  Future<String?> _getServerDirectory() async {
    // 获取当前应用程序目录
    final currentDir = Directory.current.path;
    
    // 尝试不同的可能路径（相对于当前目录）
    final possibleDirs = [
      // 开发模式：从 nexus 目录找到 server
      path.join(currentDir, '..', 'server'),
      // 打包后：从应用目录找到 server
      path.join(currentDir, 'server'),
      path.join(currentDir, 'resources', 'server'),
      // 项目根目录
      path.join(currentDir, '..', '..', 'tools', 'server'),
      // 从 tools/nexus 找到 tools/server
      path.normalize(path.join(currentDir, '..', 'server')),
    ];

    for (final serverDir in possibleDirs) {
      final dir = Directory(serverDir);
      if (await dir.exists()) {
        // 检查是否有 package.json
        final packageJson = File(path.join(serverDir, 'package.json'));
        if (await packageJson.exists()) {
          return serverDir;
        }
      }
    }

    return null;
  }

  /// 检查服务器是否可用
  Future<bool> checkServerHealth() async {
    try {
      final client = HttpClient();
      try {
        // 尝试 /api/system/health 端点
        final request = await client
            .getUrl(Uri.parse('http://localhost:${state.port}/api/system/health'))
            .timeout(const Duration(seconds: 2));
        final response = await request.close();
        final success = response.statusCode == 200;
        client.close();
        return success;
      } catch (e) {
        client.close();
        // 如果失败，尝试 /api/health 作为备用
        try {
          final client2 = HttpClient();
          final request2 = await client2
              .getUrl(Uri.parse('http://localhost:${state.port}/api/health'))
              .timeout(const Duration(seconds: 2));
          final response2 = await request2.close();
          final success2 = response2.statusCode == 200;
          client2.close();
          return success2;
        } catch (e2) {
          return false;
        }
      }
    } catch (e) {
      return false;
    }
  }

  /// 等待服务器就绪
  Future<bool> waitForServer({Duration timeout = const Duration(seconds: 30)}) async {
    final startTime = DateTime.now();
    
    // 首先快速检查一次，如果服务器已运行则立即返回
    if (await checkServerHealth()) {
      state = state.copyWith(
        isRunning: true,
        serverUrl: 'http://localhost:${state.port}',
      );
      return true;
    }
    
    // 如果未运行，等待服务器启动
    while (DateTime.now().difference(startTime) < timeout) {
      if (await checkServerHealth()) {
        state = state.copyWith(
          isRunning: true,
          serverUrl: 'http://localhost:${state.port}',
        );
        return true;
      }
      await Future.delayed(const Duration(milliseconds: 300)); // 缩短检查间隔
    }
    
    return false;
  }
}

/// 服务器管理器 Provider
final serverManagerProvider = Provider<ServerManager>((ref) {
  throw UnimplementedError('ServerManager must be overridden');
});
