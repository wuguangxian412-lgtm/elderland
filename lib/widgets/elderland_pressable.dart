import 'package:flutter/material.dart';

class ElderlandPressableButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool filled;
  final Color accentColor;
  final Color textColor;
  final Color borderColor;
  final double? width;
  final double height;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final TextStyle? textStyle;

  const ElderlandPressableButton({
    super.key,
    required this.label,
    required this.onTap,
    required this.filled,
    required this.accentColor,
    required this.textColor,
    required this.borderColor,
    this.width,
    this.height = 34,
    this.padding = const EdgeInsets.symmetric(horizontal: 14),
    this.borderRadius = 8,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);
    final backgroundColor = filled ? accentColor : Colors.white;
    final foregroundColor = filled ? Colors.white : textColor;
    final splashColor = filled
        ? Colors.white.withValues(alpha: 0.22)
        : accentColor.withValues(alpha: 0.14);
    final highlightColor = filled
        ? Colors.white.withValues(alpha: 0.10)
        : accentColor.withValues(alpha: 0.08);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        splashColor: splashColor,
        highlightColor: highlightColor,
        child: Ink(
          width: width,
          height: height,
          padding: padding,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: radius,
            border: filled ? null : Border.all(color: borderColor),
          ),
          child: Center(
            child: Text(
              label,
              style:
                  textStyle ??
                  TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: foregroundColor,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}

class ElderlandPressableCard extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;
  final Color backgroundColor;
  final Color borderColor;
  final Color overlayColor;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final double? width;
  final double? height;

  const ElderlandPressableCard({
    super.key,
    required this.child,
    required this.onTap,
    required this.backgroundColor,
    required this.borderColor,
    required this.overlayColor,
    this.padding = const EdgeInsets.all(12),
    this.margin,
    this.borderRadius = 8,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);
    return Padding(
      padding: margin ?? EdgeInsets.zero,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          splashColor: overlayColor.withValues(alpha: 0.14),
          highlightColor: overlayColor.withValues(alpha: 0.08),
          child: Ink(
            width: width,
            height: height,
            padding: padding,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: radius,
              border: Border.all(color: borderColor),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
