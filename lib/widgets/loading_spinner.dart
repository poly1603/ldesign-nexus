import 'package:flutter/material.dart';

/// 加载动画组件
class LoadingSpinner extends StatelessWidget {
  final String? text;
  final bool fullScreen;
  final Color? color;

  const LoadingSpinner({
    super.key,
    this.text,
    this.fullScreen = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final Widget spinner = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(
            color ?? Theme.of(context).primaryColor,
          ),
        ),
        if (text != null) ...[
          const SizedBox(height: 16),
          Text(
            text!,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ],
      ],
    );

    if (fullScreen) {
      return Container(
        color: Colors.white.withOpacity(0.8),
        child: Center(child: spinner),
      );
    }

    return Center(child: spinner);
  }
}



















