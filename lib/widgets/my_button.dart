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
    const Color accentOrange = Color(0xFFFF9100);
    
    final bool isDisabled = onTap == null;
    final bg = backgroundColor ?? primaryOrange;
    final fg = textColor ?? Colors.white;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: isDisabled ? 0.6 : 1.0,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            gradient: backgroundColor == null ? const LinearGradient(
              colors: [accentOrange, primaryOrange],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ) : null,
            color: backgroundColor != null ? bg : null,
            boxShadow: [
              BoxShadow(
                color: bg.withAlpha(77),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(borderRadius),
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
                      const SizedBox(width: 10),
                    ],
                    Flexible(
                      child: Text(
                        text,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: fg,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    if (suffixIcon != null) ...[
                      const SizedBox(width: 10),
                      suffixIcon!,
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}