import 'package:flutter/material.dart';
import 'package:pomniter_design_system/pomniter_design_system.dart';

/// Displays a high-contrast, neo-brutal floating toast.
///
/// Guaranteed 100% visible and razor-sharp in both Light and Dark modes.
void showNeoToast(
  BuildContext context,
  String message, {
  bool isError = false,
  bool isSuccess = false,
  IconData? icon,
  Duration duration = const Duration(seconds: 3),
}) {
  final messenger = ScaffoldMessenger.of(context);
  final neo = NeoTheme.maybeOf(context);
  final isDark = neo?.isDark ?? (Theme.of(context).brightness == Brightness.dark);

  // High-contrast inverted styling for unmistakable readability
  final Color bgColor;
  final Color textColor;
  final Color borderColor;

  if (isError) {
    bgColor = NeoColors.error;
    textColor = NeoColors.white;
    borderColor = NeoColors.black;
  } else if (isSuccess) {
    bgColor = isDark ? NeoColors.green : NeoColors.green;
    textColor = NeoColors.black;
    borderColor = NeoColors.black;
  } else {
    // In light mode: deep black surface with crisp white text
    // In dark mode: radiant white surface with deep black text
    bgColor = isDark ? NeoColors.white : NeoColors.black;
    textColor = isDark ? NeoColors.black : NeoColors.white;
    borderColor = isDark ? NeoColors.yellow : NeoColors.black;
  }

  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      duration: duration,
      backgroundColor: bgColor,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: borderColor, width: 2),
        borderRadius: NeoBorders.radius,
      ),
      content: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 20, color: textColor),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Text(
              message,
              style: NeoTypography.labelMedium.copyWith(
                color: textColor,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
