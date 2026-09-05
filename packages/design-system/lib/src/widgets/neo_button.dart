import 'package:flutter/material.dart';
import '../tokens/neo_colors.dart';
import '../tokens/neo_borders.dart';
import '../tokens/neo_shadows.dart';
import '../tokens/neo_typography.dart';
import '../theme/neo_theme.dart';

/// A neo-brutal styled button with hard shadow and press animation.
///
/// Features:
/// - Thick black border
/// - Hard drop shadow (no blur)
/// - Translates down+right on press (shadow shrinks)
/// - Uppercase bold text
///
/// `dart
/// NeoButton(
///   label: 'GET STARTED',
///   color: NeoColors.yellow,
///   onPressed: () {},
/// )
/// `
class NeoButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color? color;
  final Color? textColor;
  final IconData? icon;
  final bool isOutline;
  final bool isLoading;
  final double? width;

  const NeoButton({
    super.key,
    required this.label,
    this.onPressed,
    this.color,
    this.textColor,
    this.icon,
    this.isOutline = false,
    this.isLoading = false,
    this.width,
  });

  @override
  State<NeoButton> createState() => _NeoButtonState();
}

class _NeoButtonState extends State<NeoButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final neo = NeoTheme.maybeOf(context);
    final borderColor = neo?.borderColor ?? NeoColors.black;
    final shadowColor = neo?.borderColor ?? NeoColors.black;

    final bgColor = widget.isOutline
        ? Colors.transparent
        : (widget.color ?? NeoColors.yellow);
    final fgColor = widget.textColor ?? NeoColors.black;

    return GestureDetector(
      onTapDown: widget.onPressed != null ? (_) => setState(() => _isPressed = true) : null,
      onTapUp: widget.onPressed != null
          ? (_) {
              setState(() => _isPressed = false);
              widget.onPressed?.call();
            }
          : null,
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        transform: Matrix4.translationValues(
          _isPressed ? 3 : 0,
          _isPressed ? 3 : 0,
          0,
        ),
        width: widget.width,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: bgColor,
          border: NeoBorders.standard(color: borderColor),
          borderRadius: NeoBorders.radius,
          boxShadow: _isPressed
              ? NeoShadows.pressed(color: shadowColor)
              : NeoShadows.sm(color: shadowColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (widget.isLoading)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: fgColor,
                  ),
                ),
              )
            else if (widget.icon != null)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Icon(widget.icon, size: 18, color: fgColor),
              ),
            Text(
              widget.label.toUpperCase(),
              style: NeoTypography.labelLarge.copyWith(color: fgColor),
            ),
          ],
        ),
      ),
    );
  }
}
