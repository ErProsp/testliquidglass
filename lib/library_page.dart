// lib/library_page.dart
//
// Spotify-style "Library" page placeholder.
// This tab will contain playlists, saved albums, artists, liked songs, etc.

import 'package:flutter/cupertino.dart';

import 'shared/shared.dart';

class LibraryPage extends StatelessWidget {
  const LibraryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);

    return CupertinoPageScaffold(
      backgroundColor: p.background,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Library', style: AppTextStyles.pageTitle(p)),
                  const SizedBox(height: AppSpacing.xl),
                  GlassSurface(
                    radius: AppRadius.xl,
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Library Page',
                          style: AppTextStyles.sectionTitle(p),
                        ),
                        const SizedBox(height: AppSpacing.m),
                        Text(
                          'Playlists, saved albums, artists, liked songs, '
                          'and podcasts will appear here.',
                          style: AppTextStyles.rowSubtitle(p),
                        ),
                      ],
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