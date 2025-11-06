import 'package:flutter/material.dart';

enum BadgeType { primary, success, warning, danger, info }

/// 状态徽章组件
class StatusBadge extends StatelessWidget {
  final String label;
  final BadgeType type;
  final bool small;

  const StatusBadge({
    super.key,
    required this.label,
    this.type = BadgeType.info,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color bgColor;
    final Color textColor;

    switch (type) {
      case BadgeType.primary:
        bgColor = Colors.blue[100]!;
        textColor = Colors.blue[800]!;
        break;
      case BadgeType.success:
        bgColor = Colors.green[100]!;
        textColor = Colors.green[800]!;
        break;
      case BadgeType.warning:
        bgColor = Colors.orange[100]!;
        textColor = Colors.orange[800]!;
        break;
      case BadgeType.danger:
        bgColor = Colors.red[100]!;
        textColor = Colors.red[800]!;
        break;
      case BadgeType.info:
        bgColor = Colors.grey[200]!;
        textColor = Colors.grey[800]!;
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 8 : 12,
        vertical: small ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: small ? 12 : 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}




















