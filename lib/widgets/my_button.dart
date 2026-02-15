import 'package:flutter/material.dart';

class MyButton extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Color? textColor;
  final double borderRadius;
  final double verticalPadding;
  final double horizontalPadding;
  final Widget? prefixIcon;
  final Widget? suffixIcon;

  const MyButton({
    super.key,
    required this.text,
    required this.onTap,
    this.backgroundColor,
    this.textColor,
    this.borderRadius = 16.0,
    this.verticalPadding = 16.0,
    this.horizontalPadding = 24.0,
    this.prefixIcon,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    const Color primaryOrange = Color(0xFFFF6F00);
    final bg = backgroundColor ?? primaryOrange;
    final fg = textColor ?? Colors.white;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16),
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(borderRadius),
        elevation: 2,
        shadowColor: Colors.orange.withAlpha(30),
        child: InkWell(
          borderRadius: BorderRadius.circular(borderRadius),
          onTap: onTap,
          splashColor: Colors.white24,
          child: Container(
            padding: EdgeInsets.symmetric(
                vertical: verticalPadding, horizontal: horizontalPadding),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (prefixIcon != null) ...[
                  prefixIcon!,
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: Text(
                    text,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: fg,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
                if (suffixIcon != null) ...[
                  const SizedBox(width: 8),
                  suffixIcon!,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
