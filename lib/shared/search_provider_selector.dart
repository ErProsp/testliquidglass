// lib/shared/search_provider_selector.dart
//
// Reusable "Search Provider" selector: a glass-styled button that opens a
// Cupertino popup menu of options. The currently selected option shows a
// check mark. Single-selection radio behaviour.

import 'dart:ui' show ImageFilter;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'theme.dart';

/// Data model pairing a display title with an optional image asset path.
class SelectionItem {
  const SelectionItem({required this.title, this.imagePath});

  final String title;
  final String? imagePath; // e.g. 'assets/icons/google.png'
}

/// Reusable glass-styled selector button that opens a popup menu of options.
class SearchProviderSelector extends StatefulWidget {
  const SearchProviderSelector({
    super.key,
    required this.options,
    required this.onItemSelected,
    this.buttonIcon = CupertinoIcons.gear,
    this.selectedItem,
  });

  final List<SelectionItem> options;
  final ValueChanged<SelectionItem> onItemSelected;
  final IconData buttonIcon;
  final SelectionItem? selectedItem;

  @override
  State<SearchProviderSelector> createState() => _SearchProviderSelectorState();
}

class _SearchProviderSelectorState extends State<SearchProviderSelector> {
  OverlayEntry? _entry;

  void _showMenu(BuildContext context) {
    final p = AppPalette.of(context);
    _entry = OverlayEntry(
      builder: (context) => _PopupMenu(
        options: widget.options,
        selectedItem: widget.selectedItem,
        palette: p,
        onItemSelected: (item) {
          _dismiss();
          widget.onItemSelected(item);
        },
      ),
    );
    Overlay.of(context).insert(_entry!);
  }

  void _dismiss() {
    _entry?.remove();
    _entry = null;
  }

  @override
  void dispose() {
    _dismiss();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _showMenu(context),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSizes.iconButton / 2),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            width: AppSizes.iconButton,
            height: AppSizes.iconButton,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: p.glassFill,
              border: Border.all(color: p.glassBorder, width: 0.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(widget.buttonIcon, color: p.text, size: 18),
          ),
        ),
      ),
    );
  }
}

/// The popup menu rendered inside an overlay entry.
class _PopupMenu extends StatelessWidget {
  const _PopupMenu({
    required this.options,
    required this.selectedItem,
    required this.palette,
    required this.onItemSelected,
  });

  final List<SelectionItem> options;
  final SelectionItem? selectedItem;
  final AppPalette palette;
  final ValueChanged<SelectionItem> onItemSelected;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      bottom: 0,
      child: Stack(
        children: [
          // Dismiss on tap outside.
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => onItemSelected(options.first), // no-op; dismiss handled by entry removal
            child: Container(color: Colors.transparent),
          ),
          Positioned(
            top: AppSizes.iconButton + AppSpacing.s,
            right: AppSpacing.s,
            child: Material(
              color: Colors.transparent,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    constraints: const BoxConstraints(maxHeight: 250, maxWidth: 240),
                    decoration: BoxDecoration(
                      color: palette.glassFill,
                      borderRadius: BorderRadius.circular(AppRadius.l),
                      border: Border.all(color: palette.glassBorder, width: 0.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.4),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (final item in options)
                            _MenuRow(
                              item: item,
                              isSelected: selectedItem != null &&
                                  selectedItem!.title == item.title,
                              palette: palette,
                              onTap: () => onItemSelected(item),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.item,
    required this.isSelected,
    required this.palette,
    required this.onTap,
  });

  final SelectionItem item;
  final bool isSelected;
  final AppPalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isSelected,
      label: '${item.title} ${isSelected ? "selected" : ""}',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          color: Colors.transparent,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.s),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                decoration: BoxDecoration(
                  color: isSelected
                      ? palette.accent.withValues(alpha: 0.2)
                      : Colors.transparent,
                ),
                child: Row(
                  children: [
                    if (item.imagePath != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(
                          item.imagePath!,
                          width: 24,
                          height: 24,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Icon(
                              CupertinoIcons.photo,
                              color: palette.textSecondary,
                              size: 24,
                            ),
                          ),
                        ),
                      )
                    else
                      const Icon(
                        CupertinoIcons.circle,
                        color: Colors.transparent,
                        size: 24,
                      ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        item.title,
                        style: TextStyle(
                          color: palette.text,
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isSelected)
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Icon(
                          CupertinoIcons.check_mark,
                          color: palette.accent,
                          size: 20,
                        ),
                      ),
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