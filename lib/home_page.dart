// lib/home_page.dart
//
// Spotify-style "Home" page placeholder.
// This tab will contain personalized content, recommendations, recently played, etc.

import 'package:flutter/cupertino.dart';

import 'shared/shared.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

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
                  Text('Home', style: AppTextStyles.pageTitle(p)),
                  const SizedBox(height: AppSpacing.xl),
                  GlassSurface(
                    radius: AppRadius.xl,
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Home Page',
                          style: AppTextStyles.sectionTitle(p),
                        ),
                        const SizedBox(height: AppSpacing.m),
                        Text(
                          'Personalized recommendations, recently played, '
                          'and curated content will appear here.',
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