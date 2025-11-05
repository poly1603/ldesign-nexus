import 'package:flutter/material.dart';

enum ButtonType { primary, success, warning, danger, outlined }

/// 自定义按钮组件
class CustomButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final ButtonType type;
  final bool isLoading;
  final bool small;
  final IconData? icon;

  const CustomButton({
    super.key,
    required this.label,
    this.onPressed,
    this.type = ButtonType.primary,
    this.isLoading = false,
    this.small = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final Color primaryColor;
    final Color textColor;
    final bool outlined = type == ButtonType.outlined;

    // 匹配 Web 版本的颜色系统
    switch (type) {
      case ButtonType.primary:
        primaryColor = const Color(0xFF667EEA); // 匹配 Web 版本的 primary 色
        textColor = Colors.white;
        break;
      case ButtonType.success:
        primaryColor = const Color(0xFF4CAF50); // #4caf50 - 匹配 Web 版本的主题色
        textColor = Colors.white;
        break;
      case ButtonType.warning:
        primaryColor = const Color(0xFFED8936); // 匹配 Web 版本的 warning 色
        textColor = Colors.white;
        break;
      case ButtonType.danger:
        primaryColor = const Color(0xFFF56565); // 匹配 Web 版本的 danger 色
        textColor = Colors.white;
        break;
      case ButtonType.outlined:
        primaryColor = const Color(0xFFD1D5DB); // 匹配 Web 版本的灰色边框
        textColor = const Color(0xFF374151); // 匹配 Web 版本的灰色文本
        break;
    }

    final buttonStyle = outlined
        ? OutlinedButton.styleFrom(
            foregroundColor: textColor,
            side: BorderSide(color: primaryColor, width: 2),
            padding: EdgeInsets.symmetric(
              horizontal: small ? 12 : 24,
              vertical: small ? 8 : 12,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          )
        : ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: textColor,
            padding: EdgeInsets.symmetric(
              horizontal: small ? 12 : 24,
              vertical: small ? 8 : 12,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          );

    final Widget child = isLoading
        ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(textColor),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: small ? 16 : 20),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: small ? 14 : 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          );

    return outlined
        ? OutlinedButton(
            onPressed: isLoading ? null : onPressed,
            style: buttonStyle,
            child: child,
          )
        : ElevatedButton(
            onPressed: isLoading ? null : onPressed,
            style: buttonStyle,
            child: child,
          );
  }
}




