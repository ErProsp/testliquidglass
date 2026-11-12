// lib/search_page.dart
//
// Spotify-style "Search" page.
// Uses shared theme, models, widgets, repository, and controller.

import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:cupertino_native_better/cupertino_native_better.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import 'shared/shared.dart';
import 'player_page.dart';

// ===== SEARCH SECTIONS =====

/// Large title row + pinned search bar. The title row collapses on scroll (iOS
/// large-title behaviour) and the bar blurs the content underneath.
class _HeaderDelegate extends SliverPersistentHeaderDelegate {
  _HeaderDelegate({
    required this.topInset,
    required this.palette,
    required this.titleRow,
    required this.searchBar,
  });

  final double topInset;
  final AppPalette palette;
  final Widget titleRow;
  final Widget searchBar;

  static const double _barBlock = AppSizes.searchBar + AppSpacing.s * 2;
  static const double _titleBlock = AppSpacing.s + AppSizes.iconButton;

  @override
  double get minExtent => topInset + _barBlock;

  @override
  double get maxExtent => topInset + _titleBlock + _barBlock;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final t = (shrinkOffset / _titleBlock).clamp(0.0, 1.0);

    Widget content = ColoredBox(
      color: palette.background.withValues(alpha: 0.78 * t),
      child: Stack(
        children: [
          if (t < 0.6)
            Positioned(
              top: topInset + AppSpacing.s,
              left: AppSpacing.l,
              right: AppSpacing.l,
              height: AppSizes.iconButton,
              child: Opacity(opacity: 1 - t / 0.6, child: titleRow),
            ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: _barBlock,
            child: searchBar,
          ),
        ],
      ),
    );

    if (t > 0.01 || overlapsContent) {
      content = ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24 * t, sigmaY: 24 * t),
          child: content,
        ),
      );
    }
    return content;
  }

  @override
  bool shouldRebuild(covariant _HeaderDelegate old) => true;
}

class _TitleRow extends StatelessWidget {
  const _TitleRow({required this.settingsButton});
  final Widget settingsButton;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Row(
      children: [
        const CoverImage(
          url: 'https://picsum.photos/seed/avatar/200/200',
          size: AppSizes.avatar,
          circular: true,
        ),
        const SizedBox(width: AppSpacing.m),
        Semantics(
          header: true,
          child: Text('Search', style: AppTextStyles.pageTitle(p)),
        ),
        const Spacer(),
        settingsButton,
      ],
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onSubmitted,
    required this.onCancel,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return ListenableBuilder(
      listenable: focusNode,
      builder: (context, _) {
        final focused = focusNode.hasFocus;
        return Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.l,
            vertical: AppSpacing.s,
          ),
          child: Row(
            children: [
              Expanded(
                // FALLBACK: CupertinoSearchTextField on a glass-tinted fill.
                // It already uses the "search" keyboard action.
                child: CupertinoSearchTextField(
                  controller: controller,
                  focusNode: focusNode,
                  placeholder: 'What do you want to listen to?',
                  placeholderStyle: AppTextStyles.field(p)
                      .copyWith(color: p.textSecondary),
                  style: AppTextStyles.field(p),
                  itemColor: p.textSecondary,
                  backgroundColor: p.glassFill,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  padding: const EdgeInsetsDirectional.fromSTEB(10, 13, 10, 13),
                  autocorrect: false,
                  onChanged: onChanged,
                  onSubmitted: onSubmitted,
                ),
              ),
              AnimatedSize(
                duration: AppDurations.normal,
                curve: Curves.easeOut,
                alignment: Alignment.centerLeft,
                child: focused
                    ? CupertinoButton(
                        padding: const EdgeInsets.only(left: AppSpacing.m),
                        minimumSize: const Size(44, 44),
                        onPressed: onCancel,
                        child: Text(
                          'Cancel',
                          style: TextStyle(fontSize: 17, color: p.accent),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.selected, required this.onSelected});

  final SearchFilter selected;
  final ValueChanged<SearchFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppSizes.filterBar,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
        itemCount: SearchFilter.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.s),
        itemBuilder: (context, i) {
          final f = SearchFilter.values[i];
          return _FilterChip(
            filter: f,
            selected: f == selected,
            onTap: () => onSelected(f),
          );
        },
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.filter,
    required this.selected,
    required this.onTap,
  });

  final SearchFilter filter;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    // FALLBACK: Flutter chip (exact accent control, no platform view per chip).
    return Semantics(
      button: true,
      selected: selected,
      label: '${filter.label} filter',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Center(
          child: AnimatedContainer(
            duration: AppDurations.fast,
            height: AppSizes.chipHeight,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? p.accent : p.glassFill,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(
                color: selected ? p.accent : p.glassBorder,
                width: 0.5,
              ),
            ),
            child: Text(
              filter.label,
              style: AppTextStyles.chip(p, selected: selected),
            ),
          ),
        ),
      ),
    );
  }
}

class _RecentTile extends StatelessWidget {
  const _RecentTile({
    required this.recent,
    required this.onTap,
    required this.onRemove,
  });

  final RecentSearch recent;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Dismissible(
      key: ValueKey('recent-${recent.text}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onRemove(),
      background: Container(
        color: p.danger,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.l),
        child: const Icon(CupertinoIcons.trash, color: CupertinoColors.white),
      ),
      child: Semantics(
        button: true,
        label: 'Recent search ${recent.text}, ${recent.kind}',
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: Padding(
              padding: const EdgeInsets.only(left: AppSpacing.l),
              child: Row(
                children: [
                  Icon(CupertinoIcons.clock, size: 20, color: p.textSecondary),
                  const SizedBox(width: AppSpacing.m),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          recent.text,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.rowTitle(p),
                        ),
                        Text(recent.kind, style: AppTextStyles.rowSubtitle(p)),
                      ],
                    ),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(48, 48),
                    onPressed: onRemove,
                    child: Icon(
                      CupertinoIcons.xmark,
                      size: 16,
                      color: p.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.category, required this.onTap});

  final GenreCategory category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Browse ${category.name}',
      child: GestureDetector(
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.l),
          child: Stack(
            fit: StackFit.expand,
            children: [
              ColoredBox(color: category.color),
              Positioned(
                right: -12,
                bottom: -6,
                child: Transform.rotate(
                  angle: 25 * math.pi / 180,
                  child: CoverImage(
                    url: category.imageUrl,
                    size: AppSizes.categoryCover,
                    radius: AppRadius.s,
                  ),
                ),
              ),
              // Light glass sheen.
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0x2EFFFFFF), Color(0x00FFFFFF)],
                  ),
                ),
              ),
              Positioned(
                left: AppSpacing.m,
                top: AppSpacing.m,
                right: AppSizes.categoryCover * 0.6,
                child: Text(category.name, style: AppTextStyles.categoryTitle),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid({required this.categories, required this.onTap});

  final List<GenreCategory> categories;
  final ValueChanged<GenreCategory> onTap;

  @override
  Widget build(BuildContext context) {
    // 12 items max, so shrink-wrapping inside the page's scroll view is fine.
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
      child: GridView.builder(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: AppSizes.categoryMaxExtent,
          mainAxisSpacing: AppSpacing.m,
          crossAxisSpacing: AppSpacing.m,
          childAspectRatio: 1.7,
        ),
        itemCount: categories.length,
        itemBuilder: (context, i) => _CategoryCard(
          category: categories[i],
          onTap: () => onTap(categories[i]),
        ),
      ),
    );
  }
}

class _IdleView extends StatelessWidget {
  const _IdleView({
    required this.recents,
    required this.categories,
    required this.onRecentTap,
    required this.onRecentRemove,
    required this.onClearAll,
    required this.onCategoryTap,
  });

  final List<RecentSearch> recents;
  final List<GenreCategory> categories;
  final ValueChanged<RecentSearch> onRecentTap;
  final ValueChanged<RecentSearch> onRecentRemove;
  final VoidCallback onClearAll;
  final ValueChanged<GenreCategory> onCategoryTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (recents.isNotEmpty) ...[
          SectionHeader(
            title: 'Recent searches',
            actionLabel: 'Clear all',
            onAction: onClearAll,
          ),
          for (final r in recents)
            _RecentTile(
              recent: r,
              onTap: () => onRecentTap(r),
              onRemove: () => onRecentRemove(r),
            ),
        ],
        const SectionHeader(title: 'Browse all'),
        _CategoryGrid(categories: categories, onTap: onCategoryTap),
      ],
    );
  }
}

class _SuggestionTile extends StatelessWidget {
  const _SuggestionTile({
    required this.text,
    required this.query,
    required this.onTap,
    required this.onFill,
  });

  final String text;
  final String query;
  final VoidCallback onTap;
  final VoidCallback onFill;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final base = TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      color: p.textSecondary,
    );
    final bold = TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w700,
      color: p.text,
    );
    final i = text.toLowerCase().indexOf(query.toLowerCase());
    final end = i + query.length;
    final spans = (i < 0 || query.isEmpty || end > text.length)
        ? [TextSpan(text: text, style: bold)]
        : [
            TextSpan(text: text.substring(0, i), style: base),
            TextSpan(text: text.substring(i, end), style: bold),
            TextSpan(text: text.substring(end), style: base),
          ];

    return Semantics(
      button: true,
      label: 'Search for $text',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 52),
          child: Padding(
            padding: const EdgeInsets.only(left: AppSpacing.l),
            child: Row(
              children: [
                Icon(CupertinoIcons.search, size: 20, color: p.textSecondary),
                const SizedBox(width: AppSpacing.m),
                Expanded(
                  child: Text.rich(
                    TextSpan(children: spans),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(48, 48),
                  onPressed: onFill,
                  child: Icon(
                    CupertinoIcons.arrow_up_left,
                    size: 18,
                    color: p.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SuggestionsView extends StatelessWidget {
  const _SuggestionsView({
    required this.query,
    required this.suggestions,
    required this.onSelect,
    required this.onFill,
  });

  final String query;
  final List<String> suggestions;
  final ValueChanged<String> onSelect;
  final ValueChanged<String> onFill;

  @override
  Widget build(BuildContext context) {
    final items = suggestions.isEmpty ? [query] : suggestions;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.s),
      child: Column(
        children: [
          for (final s in items)
            _SuggestionTile(
              text: s,
              query: query,
              onTap: () => onSelect(s),
              onFill: () => onFill(s),
            ),
        ],
      ),
    );
  }
}

class _SkeletonTrackTile extends StatelessWidget {
  const _SkeletonTrackTile();

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    Widget box(double w, double h, [double r = AppRadius.s]) => Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: p.shimmerBase,
        borderRadius: BorderRadius.circular(r),
      ),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.l,
        vertical: AppSpacing.xs + 2,
      ),
      child: Row(
        children: [
          box(AppSizes.skeletonCover, AppSizes.skeletonCover),
          const SizedBox(width: AppSpacing.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                box(180, 14),
                const SizedBox(height: AppSpacing.s),
                box(110, 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Loading results',
      child: Shimmer(
        child: Column(
          children: [
            const SizedBox(height: AppSpacing.s),
            for (var i = 0; i < 8; i++) const _SkeletonTrackTile(),
          ],
        ),
      ),
    );
  }
}

const List<String> _kTrackMenuLabels = [
  'Add to playlist',
  'Add to queue',
  'Go to artist',
  'Go to album',
  'Share',
];

// Keep in sync with _kTrackMenuLabels (same order).
const List<CNPopupMenuEntry> _kTrackMenuItems = [
  CNPopupMenuItem(label: 'Add to playlist', icon: CNSymbol('text.badge.plus')),
  CNPopupMenuItem(
    label: 'Add to queue',
    icon: CNSymbol('text.line.last.and.arrowtriangle.forward'),
  ),
  CNPopupMenuItem(label: 'Go to artist', icon: CNSymbol('person.crop.circle')),
  CNPopupMenuItem(label: 'Go to album', icon: CNSymbol('square.stack')),
  CNPopupMenuItem(label: 'Share', icon: CNSymbol('square.and.arrow.up')),
];

class _TrackTile extends StatelessWidget {
  const _TrackTile({
    required this.track,
    required this.onTap,
    required this.onMenu,
  });

  final Track track;
  final VoidCallback onTap;
  final ValueChanged<int> onMenu;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Semantics(
      button: true,
      label: '${track.title}, ${track.artist}',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSizes.trackRow),
          child: Padding(
            padding: const EdgeInsets.only(left: AppSpacing.l),
            child: Row(
              children: [
                CoverImage(url: track.imageUrl, size: AppSizes.trackCover),
                const SizedBox(width: AppSpacing.m),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        track.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.rowTitle(p),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          if (track.explicit) const ExplicitBadge(),
                          if (track.isEpisode)
                            Padding(
                              padding: const EdgeInsets.only(
                                right: AppSpacing.xs,
                              ),
                              child: Text(
                                'Episode •',
                                style: AppTextStyles.rowSubtitle(p),
                              ),
                            ),
                          Flexible(
                            child: Text(
                              track.artist,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.rowSubtitle(p),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (!track.isEpisode)
                  SizedBox(
                    width: AppSizes.iconButton,
                    height: AppSizes.iconButton,
                    child: CNPopupMenuButton.icon(
                      buttonIcon: const CNSymbol('ellipsis', size: 18),
                      buttonStyle: CNButtonStyle.plain,
                      items: _kTrackMenuItems,
                      onSelected: onMenu,
                    ),
                  )
                else
                  const SizedBox(width: AppSpacing.l),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ArtistCard extends StatelessWidget {
  const _ArtistCard({required this.artist, required this.onTap});
  final Artist artist;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Semantics(
      button: true,
      label: 'Artist ${artist.name}',
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox(
          width: AppSizes.artistAvatar,
          child: Column(
            children: [
              CoverImage(
                url: artist.imageUrl,
                size: AppSizes.artistAvatar,
                circular: true,
              ),
              const SizedBox(height: AppSpacing.s),
              Text(
                artist.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: AppTextStyles.cardTitle(p),
              ),
              Text('Artist', style: AppTextStyles.caption(p)),
            ],
          ),
        ),
      ),
    );
  }
}

class _AlbumCard extends StatelessWidget {
  const _AlbumCard({required this.album, required this.onTap});
  final Album album;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Semantics(
      button: true,
      label: 'Album ${album.title} by ${album.artist}',
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox(
          width: AppSizes.albumCover,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CoverImage(
                url: album.imageUrl,
                size: AppSizes.albumCover,
                radius: AppRadius.m,
              ),
              const SizedBox(height: AppSpacing.s),
              Text(
                album.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.cardTitle(p),
              ),
              Text(
                '${album.year} • ${album.artist}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.caption(p),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlaylistCard extends StatelessWidget {
  const _PlaylistCard({required this.playlist, required this.onTap});
  final Playlist playlist;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Semantics(
      button: true,
      label: 'Playlist ${playlist.title} by ${playlist.owner}',
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox(
          width: AppSizes.playlistCover,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CoverImage(
                url: playlist.imageUrl,
                size: AppSizes.playlistCover,
                radius: AppRadius.m,
              ),
              const SizedBox(height: AppSpacing.s),
              Text(
                playlist.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.cardTitle(p),
              ),
              Text(
                playlist.owner,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.caption(p),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopResultCard extends StatelessWidget {
  const _TopResultCard({required this.top, required this.onTap});

  final TopResult top;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.l,
        AppSpacing.l,
        AppSpacing.l,
        0,
      ),
      child: Semantics(
        button: true,
        label: 'Top result: ${top.title}, ${top.badge}',
        child: GestureDetector(
          onTap: onTap,
          child: GlassSurface(
            radius: AppRadius.xl,
            native: true,
            padding: const EdgeInsets.all(AppSpacing.l),
            child: Stack(
              children: [
                Row(
                  children: [
                    CoverImage(
                      url: top.imageUrl,
                      size: AppSizes.topCover,
                      radius: AppRadius.m,
                      circular: top.circular,
                    ),
                    const SizedBox(width: AppSpacing.l),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            top.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.topTitle(p),
                          ),
                          const SizedBox(height: AppSpacing.s),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.s,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: p.glassFill,
                              borderRadius: BorderRadius.circular(
                                AppRadius.pill,
                              ),
                            ),
                            child: Text(
                              top.badge,
                              style: AppTextStyles.caption(p)
                                  .copyWith(color: p.text),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            top.subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.rowSubtitle(p),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: CircleButton(
                    icon: CupertinoIcons.play_fill,
                    label: 'Play ${top.title}',
                    onTap: onTap,
                    fill: p.accent,
                    iconColor: p.onAccent,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ResultsView extends StatelessWidget {
  const _ResultsView({
    required this.query,
    required this.results,
    required this.filter,
    required this.onFilter,
    required this.onPlay,
    required this.onMenu,
    required this.onOpen,
    required this.onCategoryTap,
  });

  final String query;
  final SearchResults results;
  final SearchFilter filter;
  final ValueChanged<SearchFilter> onFilter;
  final ValueChanged<Track> onPlay;
  final void Function(Track track, int menuIndex) onMenu;
  final ValueChanged<String> onOpen;
  final ValueChanged<GenreCategory> onCategoryTap;

  List<Widget> _tracks(List<Track> items) => [
    for (final t in items)
      _TrackTile(track: t, onTap: () => onPlay(t), onMenu: (i) => onMenu(t, i)),
  ];

  Widget _artists(BuildContext context) => Carousel(
    height: AppSizes.artistAvatar + AppSpacing.s + 36 * textScale(context),
    itemCount: results.artists.length,
    itemBuilder: (_, i) => _ArtistCard(
      artist: results.artists[i],
      onTap: () => onOpen(results.artists[i].name),
    ),
  );

  Widget _albums(BuildContext context) => Carousel(
    height: AppSizes.albumCover + AppSpacing.s + 36 * textScale(context),
    itemCount: results.albums.length,
    itemBuilder: (_, i) => _AlbumCard(
      album: results.albums[i],
      onTap: () => onOpen(results.albums[i].title),
    ),
  );

  Widget _playlists(BuildContext context) => Carousel(
    height: AppSizes.playlistCover + AppSpacing.s + 52 * textScale(context),
    itemCount: results.playlists.length,
    itemBuilder: (_, i) => _PlaylistCard(
      playlist: results.playlists[i],
      onTap: () => onOpen(results.playlists[i].title),
    ),
  );

  @override
  Widget build(BuildContext context) {
    if (!results.hasFor(filter)) {
      return EmptyState(
        icon: CupertinoIcons.search,
        title: 'No ${filter.label.toLowerCase()} for "$query"',
        subtitle: 'Try another filter or a different keyword.',
      );
    }

    switch (filter) {
      case SearchFilter.all:
        final top = results.topFor(query);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (top != null)
              _TopResultCard(
                top: top,
                onTap: () =>
                    top.track != null ? onPlay(top.track!) : onOpen(top.title),
              ),
            if (results.tracks.isNotEmpty) ...[
              SectionHeader(
                title: 'Songs',
                actionLabel: 'Show all',
                onAction: () => onFilter(SearchFilter.songs),
              ),
              ..._tracks(results.tracks.take(5).toList()),
            ],
            if (results.artists.isNotEmpty) ...[
              SectionHeader(
                title: 'Artists',
                actionLabel: 'Show all',
                onAction: () => onFilter(SearchFilter.artists),
              ),
              _artists(context),
            ],
            if (results.albums.isNotEmpty) ...[
              SectionHeader(
                title: 'Albums',
                actionLabel: 'Show all',
                onAction: () => onFilter(SearchFilter.albums),
              ),
              _albums(context),
            ],
            if (results.playlists.isNotEmpty) ...[
              SectionHeader(
                title: 'Playlists',
                actionLabel: 'Show all',
                onAction: () => onFilter(SearchFilter.playlists),
              ),
              _playlists(context),
            ],
            if (results.episodes.isNotEmpty) ...[
              SectionHeader(
                title: 'Podcasts',
                actionLabel: 'Show all',
                onAction: () => onFilter(SearchFilter.podcasts),
              ),
              ..._tracks(results.episodes.take(3).toList()),
            ],
          ],
        );
      case SearchFilter.songs:
        return Padding(
          padding: const EdgeInsets.only(top: AppSpacing.s),
          child: Column(children: _tracks(results.tracks)),
        );
      case SearchFilter.podcasts:
        return Padding(
          padding: const EdgeInsets.only(top: AppSpacing.s),
          child: Column(children: _tracks(results.episodes)),
        );
      case SearchFilter.artists:
        return WrapGrid(
          children: [
            for (final a in results.artists)
              _ArtistCard(artist: a, onTap: () => onOpen(a.name)),
          ],
        );
      case SearchFilter.albums:
        return WrapGrid(
          children: [
            for (final a in results.albums)
              _AlbumCard(album: a, onTap: () => onOpen(a.title)),
          ],
        );
      case SearchFilter.playlists:
        return WrapGrid(
          children: [
            for (final pl in results.playlists)
              _PlaylistCard(playlist: pl, onTap: () => onOpen(pl.title)),
          ],
        );
      case SearchFilter.genres:
        return Padding(
          padding: const EdgeInsets.only(top: AppSpacing.l),
          child: _CategoryGrid(
            categories: results.genres,
            onTap: onCategoryTap,
          ),
        );
    }
  }
}

// ===== SEARCH PAGE =====

class SearchPage extends StatefulWidget {
  const SearchPage({super.key, this.repository});

  /// Swap in a real API implementation here.
  final SearchRepository? repository;

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  late final SearchPageController _controller;
  final TextEditingController _text = TextEditingController();
  final FocusNode _focus = FocusNode();

  int _tab = 1; // Search
  late Track _nowPlaying;
  bool _playing = false;
  int _elapsed = 0;
  Timer? _ticker;

  OverlayEntry? _toast;
  Timer? _toastTimer;

  @override
  void initState() {
    super.initState();
    _controller = SearchPageController(
      widget.repository ?? FakeSearchRepository(),
    );
    _nowPlaying = _controller.featuredTrack;
    _controller.init();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _toastTimer?.cancel();
    _toast?.remove();
    _text.dispose();
    _focus.dispose();
    _controller.dispose();
    super.dispose();
  }

  // ---- search actions ----

  void _unfocus() => _focus.unfocus();

  void _clearAndCancel() {
    _text.clear();
    _controller.onQueryChanged('');
    _focus.unfocus();
  }

  void _setText(String value) {
    _text.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
  }

  void _fill(String value) {
    _setText(value);
    _controller.onQueryChanged(value);
    _focus.requestFocus();
  }

  void _runQuery(String value, {String? genreKey}) {
    _setText(value);
    _focus.unfocus();
    _controller.submit(value, genreKey: genreKey);
  }

  void _openGenre(GenreCategory c) {
    HapticFeedback.selectionClick();
    _controller.setFilter(SearchFilter.all);
    _runQuery(c.name, genreKey: c.key);
  }

  // ---- playback ----

  void _play(Track t) {
    setState(() {
      _nowPlaying = t;
      _playing = true;
      _elapsed = 0;
    });
    _startTicker();
  }

  void _togglePlay() {
    setState(() => _playing = !_playing);
    if (_playing) {
      _startTicker();
    } else {
      _ticker?.cancel();
    }
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        if (_elapsed + 1 >= _nowPlaying.durationSec) {
          _elapsed = 0;
          _playing = false;
          _ticker?.cancel();
        } else {
          _elapsed++;
        }
      });
    });
  }

  void _openPlayer() {
    Navigator.of(context).push(
      CupertinoPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => PlayerPage(track: _nowPlaying),
      ),
    );
  }

  // ---- toast ----

  void _showToast(String message) {
    _toastTimer?.cancel();
    _toast?.remove();
    final pad = MediaQuery.paddingOf(context);
    final entry = OverlayEntry(
      builder: (_) => Positioned(
        left: AppSpacing.xl,
        right: AppSpacing.xl,
        bottom:
            pad.bottom + AppSizes.tabBar + AppSizes.miniPlayer + AppSpacing.xl,
        child: IgnorePointer(child: Center(child: ToastPill(message))),
      ),
    );
    _toast = entry;
    Overlay.of(context).insert(entry);
    _toastTimer = Timer(AppDurations.toast, () {
      entry.remove();
      if (_toast == entry) _toast = null;
    });
  }

  void _onMenu(Track t, int index) {
    if (index < 0 || index >= _kTrackMenuLabels.length) return;
    _showToast('${_kTrackMenuLabels[index]} • ${t.title}');
  }

  // ---- provider menu ----

  // ---- settings button ----

  Widget get _settingsButton => SearchProviderSelector(
    options: SearchFilter.values
        .map((f) => SelectionItem(title: f.label))
        .toList(),
    onItemSelected: (item) {
      final f = SearchFilter.values.firstWhere((x) => x.label == item.title);
      HapticFeedback.selectionClick();
      _controller.setFilter(f);
    },
    selectedItem: SelectionItem(title: _controller.filter.label),
  );

  // ---- build ----

  Widget _body(SearchState s, AppPalette p) {
    return switch (s) {
      SearchIdle() => _IdleView(
        recents: _controller.recents,
        categories: _controller.categories,
        onRecentTap: (r) => _runQuery(r.text),
        onRecentRemove: _controller.removeRecent,
        onClearAll: _controller.clearRecents,
        onCategoryTap: _openGenre,
      ),
      SearchTyping(:final query, :final suggestions) => _SuggestionsView(
        query: query,
        suggestions: suggestions,
        onSelect: _runQuery,
        onFill: _fill,
      ),
      SearchLoading() => const _LoadingView(),
      SearchSuccess(:final query, :final results) => _ResultsView(
        query: query,
        results: results,
        filter: _controller.filter,
        onFilter: _controller.setFilter,
        onPlay: _play,
        onMenu: _onMenu,
        onOpen: (label) => _showToast('Opening $label'),
        onCategoryTap: _openGenre,
      ),
      SearchEmpty(:final query) => EmptyState(
        icon: CupertinoIcons.search,
        title: 'No results for "$query"',
        subtitle: 'Check the spelling or try a different keyword.',
      ),
      SearchError(:final message) => ErrorState(
        message: message,
        onRetry: _controller.retry,
      ),
    };
  }

  Widget _searchTab(AppPalette p, EdgeInsets pad) {
    final tail =
        AppSizes.miniPlayer +
        AppSizes.tabBar +
        pad.bottom +
        AppSpacing.xxl +
        MediaQuery.viewInsetsOf(context).bottom;

    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final s = _controller.state;
        final showFilters = s is SearchLoading || s is SearchSuccess;

        return CustomScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          slivers: [
            SliverPersistentHeader(
              pinned: true,
              delegate: _HeaderDelegate(
                topInset: pad.top,
                palette: p,
                titleRow: _TitleRow(
                  settingsButton: _settingsButton,
                ),
                searchBar: _SearchBar(
                  controller: _text,
                  focusNode: _focus,
                  onChanged: _controller.onQueryChanged,
                  onSubmitted: (q) => _controller.submit(q),
                  onCancel: _clearAndCancel,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: AnimatedSize(
                duration: AppDurations.fast,
                alignment: Alignment.topCenter,
                child: showFilters
                    ? _FilterBar(
                        selected: _controller.filter,
                        onSelected: (f) {
                          HapticFeedback.selectionClick();
                          _controller.setFilter(f);
                        },
                      )
                    : const SizedBox(width: double.infinity),
              ),
            ),
            SliverToBoxAdapter(
              child: AnimatedSwitcher(
                duration: AppDurations.normal,
                switchInCurve: Curves.easeOut,
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.02),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                ),
                child: KeyedSubtree(
                  key: ValueKey('${s.runtimeType}-${_controller.filter.name}'),
                  child: _body(s, p),
                ),
              ),
            ),
            SliverToBoxAdapter(child: SizedBox(height: tail)),
          ],
        );
      },
    );
  }

  Widget _placeholderTab(AppPalette p, String name) => Center(
    child: Text('$name (placeholder)', style: AppTextStyles.rowSubtitle(p)),
  );

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final pad = MediaQuery.paddingOf(context);
    const tabNames = ['Home', 'Search', 'Library', 'Premium'];

    return CupertinoPageScaffold(
      backgroundColor: p.background,
      resizeToAvoidBottomInset: false, // keep tab bar + mini player in place
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _unfocus,
        child: Stack(
          children: [
            // Gradient gives the glass something to refract.
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [p.gradientTop, p.background],
                    stops: const [0.0, 0.45],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: _tab == 1
                  ? _searchTab(p, pad)
                  : _placeholderTab(p, tabNames[_tab]),
            ),
            Positioned(
              left: AppSpacing.s,
              right: AppSpacing.s,
              bottom: pad.bottom + AppSizes.tabBar + AppSpacing.s,
              child: GlassMiniPlayer(
                track: _nowPlaying,
                playing: _playing,
                progress: _nowPlaying.durationSec == 0
                    ? 0
                    : _elapsed / _nowPlaying.durationSec,
                onToggle: _togglePlay,
                onOpen: _openPlayer,
                onDevices: () => _showToast('No other devices found'),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: BottomTabBar(
                currentIndex: _tab,
                onTap: (i) {
                  HapticFeedback.selectionClick();
                  _unfocus();
                  setState(() => _tab = i);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}