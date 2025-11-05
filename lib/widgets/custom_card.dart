import 'package:flutter/material.dart';

/// 自定义卡片组件
class CustomCard extends StatelessWidget {
  final Widget? title;
  final Widget? subtitle;
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final double? elevation;

  const CustomCard({
    super.key,
    this.title,
    this.subtitle,
    required this.child,
    this.padding,
    this.onTap,
    this.backgroundColor,
    this.elevation,
  });

  @override
  Widget build(BuildContext context) {
    // 匹配 Web 版本的卡片样式：白色背景、圆角、阴影
    // 使用 Container 而不是 Card，以便更好地控制阴影效果
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white, // 匹配 Web 版本的白色背景
        borderRadius: BorderRadius.circular(12), // 匹配 Web 版本的圆角
        boxShadow: elevation == null || elevation == 0
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08), // 匹配 Web 版本的 shadow-soft
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(24), // 匹配 Web 版本的 md padding (p-6)
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null || subtitle != null) ...[
                  if (title != null)
                    DefaultTextStyle(
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF111827), // 匹配 Web 版本的 text-gray-900
                          ) ??
                          const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF111827),
                          ),
                      child: title!,
                    ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    DefaultTextStyle(
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: const Color(0xFF6B7280), // 匹配 Web 版本的 text-gray-500
                          ) ??
                          const TextStyle(
                            color: Color(0xFF6B7280),
                          ),
                      child: subtitle!,
                    ),
                  ],
                  const SizedBox(height: 16),
                ],
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}




