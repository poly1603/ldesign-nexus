import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';
import '../../core/api/services/system_service.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/loading_spinner.dart';
import '../../widgets/system_layout.dart';

/// 系统信息页面
class SystemPage extends StatefulWidget {
  const SystemPage({super.key});

  @override
  State<SystemPage> createState() => _SystemPageState();
}

class _SystemPageState extends State<SystemPage> {
  final SystemService _service = SystemService(ApiClient(baseUrl: 'http://localhost:3001/api'));
  SystemInfo? _systemInfo;
  bool _loading = true;
  bool _isInitialLoad = true; // 标记是否是首次加载
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    // 延迟加载，避免热重载时立即执行
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadSystemInfo(isInitialLoad: true);
        // 每5秒自动刷新（静默更新，不显示加载状态）
        _refreshTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
          if (mounted) {
            _loadSystemInfo(isInitialLoad: false);
          } else {
            timer.cancel();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _loading = false; // 确保状态清理
    super.dispose();
  }
  
  @override
  void reassemble() {
    // 热重载时重新加载数据
    super.reassemble();
    if (mounted) {
      _loadSystemInfo(isInitialLoad: true);
    }
  }

  Future<void> _loadSystemInfo({bool isInitialLoad = false}) async {
    // 如果组件已销毁，不执行加载
    if (!mounted) return;
    
    try {
      // 只在首次加载时显示 loading 状态
      if (isInitialLoad && mounted) {
        setState(() {
          _loading = true;
          _isInitialLoad = true;
        });
      }
      
      final info = await _service.getSystemInfo();
      
      // 再次检查 mounted，因为异步操作期间组件可能被销毁
      if (!mounted) return;
      
      // 静默更新数据，不显示加载状态
      setState(() {
        _systemInfo = info;
        _loading = false;
        _isInitialLoad = false;
      });
      
      if (info == null) {
        print('⚠️  系统信息为空，可能服务器未正确响应');
      }
    } catch (e, stackTrace) {
      print('加载系统信息异常: $e');
      print('堆栈跟踪: $stackTrace');
      
      // 确保 mounted 检查
      if (!mounted) return;
      
      // 只在首次加载时显示错误状态
      setState(() {
        if (isInitialLoad) {
          _systemInfo = null;
          _loading = false;
          _isInitialLoad = false;
        }
        // 如果不是首次加载，静默失败，保持当前数据显示
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SystemLayout(
      title: '系统信息',
      child: Column(
        children: [
          // 操作栏
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Row(
              children: [
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () {
                    _loadSystemInfo(isInitialLoad: false);
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // 内容区域 - 匹配 Web 版本的间距
          Expanded(
            child: _loading
          ? const LoadingSpinner(text: '加载系统信息...')
          : _systemInfo == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Color(0xFFF56565),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        '加载系统信息失败，请刷新重试',
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () {
                          _loadSystemInfo(isInitialLoad: true);
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('刷新'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24), // 匹配 Web 版本的 p-6
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 概览卡片
                      _buildOverviewCards(),
                      const SizedBox(height: 24), // 匹配 Web 版本的 space-y-6

                      // 操作系统信息
                      _buildOSCard(),
                      const SizedBox(height: 24),

                      // CPU信息
                      _buildCPUCard(),
                      const SizedBox(height: 24),

                      // 内存信息
                      _buildMemoryCard(),
                      const SizedBox(height: 24),

                      // 磁盘信息
                      if (_systemInfo!.disk != null) ...[
                        _buildDiskCard(),
                        const SizedBox(height: 24),
                      ],

                      // 网络接口
                      _buildNetworkCard(),
                    ],
                  ),
                ),
          ),
        ],
      ),
    );
  }

  /// 构建概览卡片 - 匹配 Web 版本的 4 列布局
  Widget _buildOverviewCards() {
    return Column(
      children: [
        // 第一行：CPU 使用率和内存使用率
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                '${_safeFormatPercentage(_systemInfo!.cpu.usage)}%',
                'CPU 使用率',
                Icons.memory,
                const Color(0xFF3B82F6), // blue-600
                const Color(0xFFDBEAFE), // blue-100
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildMetricCard(
                '${_systemInfo!.memory.usagePercent}%',
                '内存使用率',
                Icons.storage,
                const Color(0xFF10B981), // green-600
                const Color(0xFFD1FAE5), // green-100
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // 第二行：CPU 核心和运行时间
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                '${_systemInfo!.cpu.cores}',
                'CPU 核心',
                Icons.speed,
                const Color(0xFF9333EA), // purple-600
                const Color(0xFFE9D5FF), // purple-100
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildMetricCard(
                _formatUptime(_systemInfo!.os.uptime),
                '运行时间',
                Icons.access_time,
                const Color(0xFFF97316), // orange-600
                const Color(0xFFFFEDD5), // orange-100
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 构建指标卡片 - 匹配 Web 版本的样式
  Widget _buildMetricCard(
    String value,
    String label,
    IconData icon,
    Color iconColor,
    Color iconBgColor,
  ) {
    return CustomCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // 图标背景
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 32,
              color: iconColor,
            ),
          ),
          const SizedBox(width: 16),
          // 文本内容
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280), // gray-500
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827), // gray-900
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建操作系统卡片 - 匹配 Web 版本的网格布局
  Widget _buildOSCard() {
    return CustomCard(
      title: const Text('操作系统'),
      child: Column(
        children: [
          // 使用网格布局，匹配 Web 版本的 grid-cols-2
          Row(
            children: [
              Expanded(
                child: _buildInfoColumn('系统类型', _systemInfo!.os.type),
              ),
              Expanded(
                child: _buildInfoColumn('平台', _systemInfo!.os.platform),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildInfoColumn('版本', _systemInfo!.os.release),
              ),
              Expanded(
                child: _buildInfoColumn('架构', _systemInfo!.os.arch),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildInfoColumn('主机名', _systemInfo!.os.hostname),
              ),
              const Expanded(child: SizedBox()), // 占位
            ],
          ),
        ],
      ),
    );
  }

  /// 构建信息列 - 匹配 Web 版本的布局
  Widget _buildInfoColumn(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF6B7280), // gray-500
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF111827), // gray-900
          ),
        ),
      ],
    );
  }

  /// 构建CPU卡片 - 匹配 Web 版本的布局
  Widget _buildCPUCard() {
    return CustomCard(
      title: const Text('处理器 (CPU)'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // CPU 型号
          _buildInfoColumn('型号', _systemInfo!.cpu.model),
          const SizedBox(height: 16),
          // 使用网格布局显示核心数和频率
          Row(
            children: [
              Expanded(
                child: _buildInfoColumn('核心数', '${_systemInfo!.cpu.cores} 核'),
              ),
              Expanded(
                child: _buildInfoColumn('频率', '${_safeToInt(_systemInfo!.cpu.speed)} MHz'),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '当前使用率',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6B7280), // gray-500
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: _buildProgressBar(
                            _safeToDouble(_systemInfo!.cpu.usage),
                            _getCPUColor(_systemInfo!.cpu.usage),
                            height: 8,
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 50,
                          child: Text(
                            '${_safeFormatPercentage(_systemInfo!.cpu.usage)}%',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF111827), // gray-900
                            ),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建内存卡片 - 匹配 Web 版本的布局
  Widget _buildMemoryCard() {
    return CustomCard(
      title: const Text('内存'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 使用网格布局显示内存信息
          Row(
            children: [
              Expanded(
                child: _buildInfoColumn('总内存', _formatBytes(_systemInfo!.memory.total)),
              ),
              Expanded(
                child: _buildInfoColumn('已使用', _formatBytes(_systemInfo!.memory.used)),
              ),
              Expanded(
                child: _buildInfoColumn('可用', _formatBytes(_systemInfo!.memory.free)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 使用率标签
          const Text(
            '使用率',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF6B7280), // gray-500
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildProgressBar(
                  _safeToDouble(_systemInfo!.memory.usagePercent),
                  _getMemoryColor(_systemInfo!.memory.usagePercent),
                  height: 16,
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 50,
                child: Text(
                  '${_safeToInt(_systemInfo!.memory.usagePercent.toDouble())}%',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827), // gray-900
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建磁盘卡片 - 匹配 Web 版本的布局
  Widget _buildDiskCard() {
    final disk = _systemInfo!.disk!;
    return CustomCard(
      title: const Text('磁盘'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 使用网格布局显示磁盘信息
          Row(
            children: [
              Expanded(
                child: _buildInfoColumn('总容量', _formatBytes(disk.total)),
              ),
              Expanded(
                child: _buildInfoColumn('已使用', _formatBytes(disk.used)),
              ),
              Expanded(
                child: _buildInfoColumn('可用', _formatBytes(disk.free)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 使用率标签
          const Text(
            '使用率',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF6B7280), // gray-500
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildProgressBar(
                  _safeToDouble(disk.usagePercent),
                  _getDiskColor(disk.usagePercent),
                  height: 16,
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 50,
                child: Text(
                  '${_safeToInt(disk.usagePercent.toDouble())}%',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827), // gray-900
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建网络卡片 - 匹配 Web 版本的样式
  Widget _buildNetworkCard() {
    final interfaces = _systemInfo!.network.interfaces.where((i) => !i.internal).toList();
    return CustomCard(
      title: const Text('网络接口'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: interfaces.map((iface) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFE5E7EB)), // gray-200
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      iface.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF111827), // gray-900
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: iface.family == 'IPv4'
                            ? const Color(0xFFDBEAFE) // blue-100
                            : const Color(0xFFF3F4F6), // gray-100
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        iface.family,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: iface.family == 'IPv4'
                              ? const Color(0xFF1E40AF) // blue-800
                              : const Color(0xFF374151), // gray-700
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  iface.address,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280), // gray-500
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  /// 构建信息行
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  /// 构建进度条 - 匹配 Web 版本的样式
  Widget _buildProgressBar(double value, Color color, {double height = 12}) {
    // 安全处理 Infinity 和 NaN
    double safeValue = value;
    if (value.isNaN || value.isInfinite) {
      safeValue = 0.0;
    } else {
      // 限制在 0-100 范围内
      safeValue = value.clamp(0.0, 100.0);
    }
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(999), // 完全圆角，匹配 Web 版本的 rounded-full
      child: LinearProgressIndicator(
        value: safeValue / 100,
        minHeight: height,
        backgroundColor: const Color(0xFFE5E7EB), // gray-200
        valueColor: AlwaysStoppedAnimation<Color>(color),
      ),
    );
  }

  /// 格式化字节
  String _formatBytes(int bytes) {
    // 安全检查：处理无效值
    if (bytes < 0) {
      return '0 B';
    }
    if (bytes == 0) return '0 B';
    
    const k = 1024;
    const sizes = ['B', 'KB', 'MB', 'GB', 'TB'];
    
    // 安全转换和计算
    final bytesDouble = bytes.toDouble();
    if (bytesDouble.isNaN || bytesDouble.isInfinite) {
      return '0 B';
    }
    
    try {
      final logValue = math.log(bytesDouble);
      final kLog = math.log(k.toDouble());
      if (logValue.isNaN || logValue.isInfinite || kLog.isNaN || kLog.isInfinite) {
        return '0 B';
      }
      
      final i = (logValue / kLog).floor();
      if (i < 0 || i >= sizes.length) {
        return '0 B';
      }
      
      final divisor = math.pow(k.toDouble(), i);
      if (divisor.isNaN || divisor.isInfinite || divisor == 0) {
        return '0 B';
      }
      
      final result = bytes / divisor;
      if (result.isNaN || result.isInfinite) {
        return '0 B';
      }
      
      return '${result.toStringAsFixed(2)} ${sizes[i]}';
    } catch (e) {
      return '0 B';
    }
  }

  /// 格式化运行时间
  String _formatUptime(double seconds) {
    // 安全处理 Infinity 和 NaN
    if (seconds.isNaN || seconds.isInfinite || seconds < 0) {
      return '0分钟';
    }
    
    final days = (seconds / 86400).floor();
    final hours = ((seconds % 86400) / 3600).floor();
    final minutes = ((seconds % 3600) / 60).floor();

    if (days > 0) {
      return '$days天 $hours时';
    } else if (hours > 0) {
      return '$hours时 $minutes分';
    } else {
      return '$minutes分钟';
    }
  }

  /// 获取CPU颜色
  Color _getCPUColor(double usage) {
    // 安全处理 Infinity 和 NaN
    if (usage.isNaN || usage.isInfinite) {
      return Colors.grey;
    }
    final safeUsage = usage.clamp(0.0, 100.0);
    if (safeUsage < 50) return Colors.green;
    if (safeUsage < 80) return Colors.yellow[700]!;
    return Colors.red;
  }

  /// 获取内存颜色
  Color _getMemoryColor(int usage) {
    if (usage < 60) return Colors.green;
    if (usage < 85) return Colors.yellow[700]!;
    return Colors.red;
  }

  /// 获取磁盘颜色
  Color _getDiskColor(int usage) {
    if (usage < 70) return Colors.green;
    if (usage < 90) return Colors.yellow[700]!;
    return Colors.red;
  }

  /// 安全地将数值转换为整数，处理 Infinity 和 NaN
  int _safeToInt(double value) {
    if (value.isNaN || value.isInfinite) {
      return 0;
    }
    // 限制在合理范围内
    if (value < 0) return 0;
    if (value > 2147483647) return 2147483647; // int 最大值
    return value.toInt();
  }

  /// 安全地将数值转换为 double，处理 Infinity 和 NaN
  double _safeToDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) {
      return value.isNaN || value.isInfinite ? 0.0 : value;
    }
    if (value is int) {
      return value.toDouble();
    }
    if (value is num) {
      final doubleVal = value.toDouble();
      return doubleVal.isNaN || doubleVal.isInfinite ? 0.0 : doubleVal;
    }
    return 0.0;
  }

  /// 安全地格式化百分比，处理 Infinity 和 NaN
  String _safeFormatPercentage(double value) {
    if (value.isNaN || value.isInfinite) {
      return '0.0';
    }
    // 限制在合理范围内
    final clampedValue = value.clamp(0.0, 100.0);
    return clampedValue.toStringAsFixed(1);
  }
}
