import 'package:flutter/material.dart';
import '../../core/config/app_config.dart';

enum AppButtonType { primary, secondary, outline, text }
enum AppButtonSize { small, medium, large }

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final AppButtonType type;
  final AppButtonSize size;
  final bool isLoading;
  final IconData? icon;
  final bool fullWidth;
  final EdgeInsets? margin;

  const AppButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.type = AppButtonType.primary,
    this.size = AppButtonSize.medium,
    this.isLoading = false,
    this.icon,
    this.fullWidth = false,
    this.margin,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Button is disabled if onPressed is null or isLoading is true
    final bool isDisabled = onPressed == null || isLoading;

    // Button styling based on type
    Color backgroundColor;
    Color textColor;
    Color borderColor;

    switch (type) {
      case AppButtonType.primary:
        backgroundColor = const Color(AppConfig.primaryColorHex);
        textColor = Colors.white;
        borderColor = const Color(AppConfig.primaryColorHex);
        break;
      case AppButtonType.secondary:
        backgroundColor = const Color(AppConfig.secondaryColorHex);
        textColor = Colors.white;
        borderColor = const Color(AppConfig.secondaryColorHex);
        break;
      case AppButtonType.outline:
        backgroundColor = Colors.transparent;
        textColor = const Color(AppConfig.primaryColorHex);
        borderColor = const Color(AppConfig.primaryColorHex);
        break;
      case AppButtonType.text:
        backgroundColor = Colors.transparent;
        textColor = const Color(AppConfig.primaryColorHex);
        borderColor = Colors.transparent;
        break;
    }

    // Button size configuration
    double horizontalPadding;
    double verticalPadding;
    double fontSize;
    double iconSize;
    double borderRadius;

    switch (size) {
      case AppButtonSize.small:
        horizontalPadding = 12;
        verticalPadding = 8;
        fontSize = 14;
        iconSize = 16;
        borderRadius = 6;
        break;
      case AppButtonSize.medium:
        horizontalPadding = 16;
        verticalPadding = 12;
        fontSize = 16;
        iconSize = 18;
        borderRadius = 8;
        break;
      case AppButtonSize.large:
        horizontalPadding = 24;
        verticalPadding = 14;
        fontSize = 18;
        iconSize = 20;
        borderRadius = 10;
        break;
    }

    // Create the button content
    Widget buttonContent = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: SizedBox(
              width: iconSize,
              height: iconSize,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(textColor),
              ),
            ),
          )
        else if (icon != null)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Icon(
              icon,
              size: iconSize,
              color: textColor,
            ),
          ),
        Text(
          text,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w600,
            fontSize: fontSize,
          ),
        ),
      ],
    );

    Widget buttonWidget = Container(
      margin: margin,
      width: fullWidth ? double.infinity : null,
      child: ElevatedButton(
        onPressed: isDisabled ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isDisabled
              ? const Color(0xFFE0E0E0)
              : backgroundColor,
          foregroundColor: isDisabled
              ? const Color(0xFF9E9E9E)
              : textColor,
          elevation: type == AppButtonType.text ? 0 : 2,
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: verticalPadding,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            side: BorderSide(
              color: isDisabled
                  ? Colors.transparent
                  : borderColor,
              width: 1.5,
            ),
          ),
          textStyle: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
          ),
        ),
        child: buttonContent,
      ),
    );

    return buttonWidget;
  }
} 