import 'package:flutter/material.dart';
import '../tokens/neo_colors.dart';
import '../tokens/neo_borders.dart';
import '../tokens/neo_shadows.dart';
import '../theme/neo_theme.dart';

/// A neo-brutal styled card container.
///
/// Features:
/// - Thick border, hard shadow, zero border-radius
/// - Optional colored left/top accent border
/// - Interactive variant with hover/tap animation
///
/// `dart
/// NeoCard(
///   accentColor: NeoColors.green,
///   child: Text('Hello'),
/// )
/// `
class NeoCard extends StatefulWidget {
  final Widget child;
  final Color? backgroundColor;
  final Color? accentColor;
  final EdgeInsets? padding;
  final bool isInteractive;
  final VoidCallback? onTap;
  final NeoCardAccentPosition accentPosition;

  const NeoCard({
    super.key,
    required this.child,
    this.backgroundColor,
    this.accentColor,
    this.padding,
    this.isInteractive = false,
    this.onTap,
    this.accentPosition = NeoCardAccentPosition.left,
  });

  @override
  State<NeoCard> createState() => _NeoCardState();
}

class _NeoCardState extends State<NeoCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final neo = NeoTheme.maybeOf(context);
    final bgColor = widget.backgroundColor ?? neo?.bgCard ?? NeoColors.white;
    final borderColor = neo?.borderColor ?? NeoColors.black;
    final shadowColor = neo?.borderColor ?? NeoColors.black;

    Border border;
    if (widget.accentColor != null) {
      border = Border(
        top: widget.accentPosition == NeoCardAccentPosition.top
            ? BorderSide(color: widget.accentColor!, width: 6)
            : BorderSide(color: borderColor, width: NeoBorders.width),
        left: widget.accentPosition == NeoCardAccentPosition.left
            ? BorderSide(color: widget.accentColor!, width: 6)
            : BorderSide(color: borderColor, width: NeoBorders.width),
        right: BorderSide(color: borderColor, width: NeoBorders.width),
        bottom: BorderSide(color: borderColor, width: NeoBorders.width),
      );
    } else {
      border = NeoBorders.standard(color: borderColor);
    }

    final card = AnimatedContainer(
      duration: const Duration(milliseconds: 80),
      transform: widget.isInteractive && _isPressed
          ? (Matrix4.translationValues(2, 2, 0))
          : Matrix4.identity(),
      padding: widget.padding ?? const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: bgColor,
        border: border,
        borderRadius: NeoBorders.radius,
        boxShadow: widget.isInteractive && _isPressed
            ? NeoShadows.pressed(color: shadowColor)
            : NeoShadows.md(color: shadowColor),
      ),
      child: widget.child,
    );

    if (!widget.isInteractive && widget.onTap == null) return card;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap?.call();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: card,
    );
  }
}

enum NeoCardAccentPosition { top, left }
