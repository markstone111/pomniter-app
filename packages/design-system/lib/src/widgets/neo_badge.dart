import 'package:flutter/material.dart';
import '../tokens/neo_colors.dart';
import '../tokens/neo_borders.dart';
import '../tokens/neo_typography.dart';

/// A neo-brutal styled badge/chip.
///
/// Small, colorful labels used for tags, categories, and status indicators.
///
/// `dart
/// NeoBadge(
///   label: 'EARLY ACCESS',
///   color: NeoColors.green,
/// )
/// `
class NeoBadge extends StatelessWidget {
  final String label;
  final Color? color;
  final Color? textColor;
  final IconData? icon;

  const NeoBadge({
    super.key,
    required this.label,
    this.color,
    this.textColor,
    this.icon,
  });

  /// Green badge — success, active
  factory NeoBadge.green({required String label, IconData? icon}) =>
      NeoBadge(label: label, color: NeoColors.green, icon: icon);

  /// Pink badge — attention, new
  factory NeoBadge.pink({required String label, IconData? icon}) =>
      NeoBadge(label: label, color: NeoColors.pink, icon: icon);

  /// Purple badge — info, category
  factory NeoBadge.purple({required String label, IconData? icon}) =>
      NeoBadge(label: label, color: NeoColors.purple, icon: icon);

  /// Yellow badge — warning, highlight
  factory NeoBadge.yellow({required String label, IconData? icon}) =>
      NeoBadge(label: label, color: NeoColors.yellow, icon: icon);

  /// Blue badge — links, interactive
  factory NeoBadge.blue({required String label, IconData? icon}) =>
      NeoBadge(label: label, color: NeoColors.blue, icon: icon);

  @override
  Widget build(BuildContext context) {
    final bgColor = color ?? NeoColors.yellow;
    final fgColor = textColor ?? NeoColors.black;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border.all(color: NeoColors.black, width: 1.5),
        borderRadius: NeoBorders.radiusSoft,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: fgColor),
            const SizedBox(width: 4),
          ],
          Text(
            label.toUpperCase(),
            style: NeoTypography.labelSmall.copyWith(
              color: fgColor,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
