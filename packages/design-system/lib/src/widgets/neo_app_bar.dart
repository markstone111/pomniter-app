import 'package:flutter/material.dart';
import '../tokens/neo_colors.dart';
import '../tokens/neo_borders.dart';
import '../tokens/neo_typography.dart';
import '../theme/neo_theme.dart';

/// A neo-brutal styled app bar.
///
/// Features:
/// - Thick bottom border
/// - Bold uppercase title
/// - Clean, solid background
///
/// `dart
/// NeoAppBar(title: 'POMNITER')
/// `
class NeoAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool showBorder;

  const NeoAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.showBorder = true,
  });

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    final neo = NeoTheme.maybeOf(context);
    final bgColor = neo?.bgMain ?? NeoColors.bgMain;
    final textColor = neo?.textMain ?? NeoColors.black;
    final borderColor = neo?.borderColor ?? NeoColors.black;

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        border: showBorder ? NeoBorders.bottom(color: borderColor) : null,
      ),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 56,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                if (leading != null) ...[
                  leading!,
                  const SizedBox(width: 12),
                ],
                Text(
                  title.toUpperCase(),
                  style: NeoTypography.headlineMedium.copyWith(
                    color: textColor,
                    letterSpacing: 1.0,
                  ),
                ),
                const Spacer(),
                ...?actions,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

