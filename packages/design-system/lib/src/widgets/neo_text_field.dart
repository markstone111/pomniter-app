import 'package:flutter/material.dart';
import '../tokens/neo_colors.dart';
import '../tokens/neo_borders.dart';
import '../tokens/neo_shadows.dart';
import '../tokens/neo_typography.dart';
import '../theme/neo_theme.dart';

/// A neo-brutal styled text field.
///
/// Features:
/// - Thick border, hard shadow
/// - Monospace placeholder text
/// - Clear button
/// - Optional search icon
///
/// `dart
/// NeoTextField(
///   hintText: 'Search your screenshots...',
///   isSearch: true,
///   onChanged: (value) {},
/// )
/// `
class NeoTextField extends StatelessWidget {
  final String? hintText;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool isSearch;
  final bool autofocus;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;

  const NeoTextField({
    super.key,
    this.hintText,
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.isSearch = false,
    this.autofocus = false,
    this.focusNode,
    this.textInputAction,
  });

  @override
  Widget build(BuildContext context) {
    final neo = NeoTheme.maybeOf(context);
    final borderColor = neo?.borderColor ?? NeoColors.black;
    final bgColor = neo?.bgCard ?? NeoColors.white;
    final textColor = neo?.textMain ?? NeoColors.black;
    final hintColor = neo?.textDim ?? NeoColors.gray400;

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        border: NeoBorders.standard(color: borderColor),
        borderRadius: NeoBorders.radius,
        boxShadow: NeoShadows.sm(color: borderColor),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        autofocus: autofocus,
        focusNode: focusNode,
        textInputAction: textInputAction ?? (isSearch ? TextInputAction.search : null),
        style: NeoTypography.bodyLarge.copyWith(color: textColor),
        cursorColor: NeoColors.yellow,
        cursorWidth: 2.5,
        decoration: InputDecoration(
          hintText: hintText ?? (isSearch ? 'Search your memories...' : ''),
          hintStyle: NeoTypography.bodyLarge.copyWith(
            color: hintColor,
            fontFamily: NeoTypography.fontMono,
            fontSize: 14,
          ),
          prefixIcon: isSearch
              ? Icon(Icons.search, color: textColor, size: 22)
              : null,
          suffixIcon: controller != null
              ? ValueListenableBuilder<TextEditingValue>(
                  valueListenable: controller!,
                  builder: (context, value, _) {
                    if (value.text.isEmpty) return const SizedBox.shrink();
                    return IconButton(
                      icon: Icon(Icons.close, color: textColor, size: 18),
                      onPressed: () {
                        controller!.clear();
                        onChanged?.call('');
                      },
                    );
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }
}

