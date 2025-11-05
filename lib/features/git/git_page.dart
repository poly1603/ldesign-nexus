import 'package:flutter/material.dart';
import '../../widgets/system_layout.dart';

class GitPage extends StatelessWidget {
  const GitPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SystemLayout(
      title: 'Git 管理',
      child: const Center(child: Text('git 页面')),
    );
  }
}
