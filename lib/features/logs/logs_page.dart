import 'package:flutter/material.dart';
import '../../widgets/system_layout.dart';

class LogsPage extends StatelessWidget {
  const LogsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SystemLayout(
      title: '日志查看',
      child: const Center(child: Text('logs 页面')),
    );
  }
}
