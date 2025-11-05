import 'package:flutter/material.dart';
import '../../widgets/system_layout.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SystemLayout(
      title: '设置',
      child: const Center(child: Text('settings 页面')),
    );
  }
}
