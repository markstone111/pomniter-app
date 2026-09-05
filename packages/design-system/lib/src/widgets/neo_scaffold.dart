import 'package:flutter/material.dart';
import '../tokens/neo_colors.dart';
import '../tokens/neo_borders.dart';
import '../tokens/neo_typography.dart';
import '../theme/neo_theme.dart';

/// A neo-brutal styled scaffold with bottom navigation.
///
/// Wraps [Scaffold] with neo-brutal bottom navigation styling:
/// thick top border, solid colors, uppercase labels.
///
/// `dart
/// NeoScaffold(
///   currentIndex: 0,
///   onTabChanged: (index) {},
///   tabs: [
///     NeoTab(icon: Icons.home, label: 'Home'),
///     NeoTab(icon: Icons.search, label: 'Search'),
///   ],
///   body: HomeScreen(),
/// )
/// `
class NeoScaffold extends StatelessWidget {
  static const List<NeoTab> defaultTabs = [
    NeoTab(icon: Icons.home_outlined, label: 'Home'),
    NeoTab(icon: Icons.search, label: 'Search'),
    NeoTab(icon: Icons.photo_library_outlined, label: 'Gallery'),
    NeoTab(icon: Icons.settings_outlined, label: 'Settings'),
  ];

  final Widget body;
  final PreferredSizeWidget? appBar;
  final int currentIndex;
  final ValueChanged<int>? onTabChanged;
  final List<NeoTab> tabs;
  final Widget? floatingActionButton;

  const NeoScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.currentIndex = 0,
    this.onTabChanged,
    this.tabs = defaultTabs,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    final neo = NeoTheme.maybeOf(context);
    final bgColor = neo?.bgMain ?? NeoColors.bgMain;
    final borderColor = neo?.borderColor ?? NeoColors.black;
    final textColor = neo?.textMain ?? NeoColors.black;
    final mutedColor = neo?.textDim ?? NeoColors.gray400;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: appBar,
      body: body,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: tabs.isEmpty
          ? null
          : Container(
              decoration: BoxDecoration(
                color: bgColor,
                border: Border(
                  top: BorderSide(
                    color: borderColor,
                    width: NeoBorders.width,
                  ),
                ),
              ),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  height: 64,
                  child: Row(
                    children: List.generate(tabs.length, (index) {
                      final tab = tabs[index];
                      final isSelected = index == currentIndex;

                      return Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => onTabChanged?.call(index),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 40,
                                height: 4,
                                margin: const EdgeInsets.only(bottom: 6),
                                color: isSelected
                                    ? NeoColors.yellow
                                    : Colors.transparent,
                              ),
                              Icon(
                                tab.icon,
                                size: 22,
                                color: isSelected ? textColor : mutedColor,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                tab.label.toUpperCase(),
                                style: NeoTypography.labelSmall.copyWith(
                                  color: isSelected ? textColor : mutedColor,
                                  fontWeight: isSelected
                                      ? FontWeight.w800
                                      : FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ),
    );
  }
}

/// A tab definition for [NeoScaffold] bottom navigation.
class NeoTab {
  final IconData icon;
  final String label;

  const NeoTab({required this.icon, required this.label});
}
