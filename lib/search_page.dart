// lib/search_page.dart
//
// Spotify-style "Search" page, single file.
// Native / Liquid Glass components come from `cupertino_native_better` ^1.9.1:
//   * CNTabBar               -> bottom tab bar
//   * CNButton.icon          -> header camera button
//   * CNPopupMenuButton.icon -> per-track "..." menu
//   * LiquidGlassContainer   -> mini player + top result card (iOS 26+)
// Everything marked `// FALLBACK` is plain Flutter (BackdropFilter etc.), either
// because the package has no equivalent or because a platform view per row/chip
// would hurt scrolling performance and accent-color control.

import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cupertino_native_better/cupertino_native_better.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ===== 1. THEME =====

abstract final class AppSpacing {
  static const double xs = 4;
  static const double s = 8;
  static const double m = 12;
  static const double l = 16;
  static const double xl = 24;
  static const double xxl = 32;
}

abstract final class AppRadius {
  static const double s = 6;
  static const double m = 8;
  static const double l = 12;
  static const double xl = 20;
  static const double pill = 32;
}

abstract final class AppSizes {
  static const double avatar = 32;
  static const double iconButton = 44;
  static const double searchBar = 46;
  static const double filterBar = 44;
  static const double chipHeight = 36;
  static const double trackRow = 64;
  static const double trackCover = 52;
  static const double skeletonCover = 56;
  static const double miniPlayer = 64;
  static const double miniCover = 44;
  static const double tabBar = 56; // tune if your CNTabBar renders taller
  static const double artistAvatar = 120;
  static const double albumCover = 140;
  static const double playlistCover = 150;
  static const double topCover = 96;
  static const double categoryCover = 72;
  static const double categoryMaxExtent = 220;
}

abstract final class AppDurations {
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration normal = Duration(milliseconds: 250);
  static const Duration debounce = Duration(milliseconds: 350);
  static const Duration shimmer = Duration(milliseconds: 1400);
  static const Duration toast = Duration(milliseconds: 1800);
}

@immutable
class AppPalette {
  const AppPalette({
    required this.isDark,
    required this.background,
    required this.gradientTop,
    required this.text,
    required this.textSecondary,
    required this.surface,
    required this.glassFill,
    required this.glassBorder,
    required this.divider,
    required this.accent,
    required this.onAccent,
    required this.shimmerBase,
    required this.shimmerHighlight,
    required this.danger,
  });

  final bool isDark;
  final Color background;
  final Color gradientTop;
  final Color text;
  final Color textSecondary;
  final Color surface;
  final Color glassFill;
  final Color glassBorder;
  final Color divider;
  final Color accent;
  final Color onAccent;
  final Color shimmerBase;
  final Color shimmerHighlight;
  final Color danger;

  static const AppPalette dark = AppPalette(
    isDark: true,
    background: Color(0xFF121212),
    gradientTop: Color(0xFF1E3A2B),
    text: Color(0xFFFFFFFF),
    textSecondary: Color(0xFFB3B3B3),
    surface: Color(0xFF242424),
    glassFill: Color(0x24FFFFFF),
    glassBorder: Color(0x33FFFFFF),
    divider: Color(0x1FFFFFFF),
    accent: Color(0xFF1DB954),
    onAccent: Color(0xFF000000),
    shimmerBase: Color(0xFF2A2A2A),
    shimmerHighlight: Color(0xFF3D3D3D),
    danger: Color(0xFFFF453A),
  );

  static const AppPalette light = AppPalette(
    isDark: false,
    background: Color(0xFFF2F2F7),
    gradientTop: Color(0xFFCDEED9),
    text: Color(0xFF000000),
    textSecondary: Color(0xFF6B6B6B),
    surface: Color(0xFFFFFFFF),
    glassFill: Color(0x14000000),
    glassBorder: Color(0x1F000000),
    divider: Color(0x1F000000),
    accent: Color(0xFF1DB954),
    onAccent: Color(0xFF000000),
    shimmerBase: Color(0xFFE0E0E0),
    shimmerHighlight: Color(0xFFF5F5F5),
    danger: Color(0xFFFF3B30),
  );

  static AppPalette of(BuildContext context) =>
      CupertinoTheme.brightnessOf(context) == Brightness.dark ? dark : light;
}

abstract final class AppTextStyles {
  static TextStyle pageTitle(AppPalette p) => TextStyle(
    fontSize: 30,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.5,
    color: p.text,
  );
  static TextStyle sectionTitle(AppPalette p) =>
      TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: p.text);
  static TextStyle rowTitle(AppPalette p) =>
      TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: p.text);
  static TextStyle rowSubtitle(AppPalette p) => TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: p.textSecondary,
  );
  static TextStyle cardTitle(AppPalette p) =>
      TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: p.text);
  static TextStyle caption(AppPalette p) => TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: p.textSecondary,
  );
  static TextStyle chip(AppPalette p, {required bool selected}) => TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: selected ? p.onAccent : p.text,
  );
  static TextStyle field(AppPalette p) =>
      TextStyle(fontSize: 17, color: p.text);
  static TextStyle link(AppPalette p) =>
      TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: p.accent);
  static const TextStyle categoryTitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: CupertinoColors.white,
  );
  static TextStyle topTitle(AppPalette p) =>
      TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: p.text);
}

// ===== 2. MODELS =====

String _imageUrl(String seed) => 'https://picsum.photos/seed/$seed/400/400';

enum SearchFilter {
  all('All'),
  songs('Songs'),
  artists('Artists'),
  albums('Albums'),
  playlists('Playlists'),
  podcasts('Podcasts'),
  genres('Genres');

  const SearchFilter(this.label);
  final String label;
}

@immutable
class Track {
  const Track({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.seed,
    required this.durationSec,
    this.genres = const [],
    this.explicit = false,
    this.isEpisode = false,
  });

  final String id;
  final String title;
  final String artist; // for episodes: the show name
  final String album;
  final String seed;
  final int durationSec;
  final List<String> genres;
  final bool explicit;
  final bool isEpisode;

  String get imageUrl => _imageUrl(seed);
}

@immutable
class Artist {
  const Artist({
    required this.id,
    required this.name,
    required this.seed,
    this.genres = const [],
  });

  final String id;
  final String name;
  final String seed;
  final List<String> genres;

  String get imageUrl => _imageUrl(seed);
}

@immutable
class Album {
  const Album({
    required this.id,
    required this.title,
    required this.artist,
    required this.year,
    required this.seed,
    this.genres = const [],
  });

  final String id;
  final String title;
  final String artist;
  final int year;
  final String seed;
  final List<String> genres;

  String get imageUrl => _imageUrl(seed);
}

@immutable
class Playlist {
  const Playlist({
    required this.id,
    required this.title,
    required this.owner,
    required this.seed,
    this.genres = const [],
  });

  final String id;
  final String title;
  final String owner;
  final String seed;
  final List<String> genres;

  String get imageUrl => _imageUrl(seed);
}

@immutable
class GenreCategory {
  const GenreCategory({
    required this.key,
    required this.name,
    required this.color,
    required this.seed,
  });

  final String key;
  final String name;
  final Color color;
  final String seed;

  String get imageUrl => _imageUrl(seed);
}

@immutable
class TopResult {
  const TopResult({
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.imageUrl,
    required this.circular,
    this.track,
  });

  final String title;
  final String subtitle;
  final String badge;
  final String imageUrl;
  final bool circular;
  final Track? track;
}

@immutable
class SearchResults {
  const SearchResults({
    this.tracks = const [],
    this.artists = const [],
    this.albums = const [],
    this.playlists = const [],
    this.episodes = const [],
    this.genres = const [],
  });

  final List<Track> tracks;
  final List<Artist> artists;
  final List<Album> albums;
  final List<Playlist> playlists;
  final List<Track> episodes;
  final List<GenreCategory> genres;

  bool get isEmpty =>
      tracks.isEmpty &&
      artists.isEmpty &&
      albums.isEmpty &&
      playlists.isEmpty &&
      episodes.isEmpty &&
      genres.isEmpty;

  bool hasFor(SearchFilter f) => switch (f) {
    SearchFilter.all => !isEmpty,
    SearchFilter.songs => tracks.isNotEmpty,
    SearchFilter.artists => artists.isNotEmpty,
    SearchFilter.albums => albums.isNotEmpty,
    SearchFilter.playlists => playlists.isNotEmpty,
    SearchFilter.podcasts => episodes.isNotEmpty,
    SearchFilter.genres => genres.isNotEmpty,
  };

  TopResult? topFor(String query) {
    final q = query.trim().toLowerCase();
    for (final a in artists) {
      if (a.name.toLowerCase().contains(q)) return _artistTop(a);
    }
    if (tracks.isNotEmpty) {
      final t = tracks.first;
      return TopResult(
        title: t.title,
        subtitle: t.artist,
        badge: 'Song',
        imageUrl: t.imageUrl,
        circular: false,
        track: t,
      );
    }
    if (albums.isNotEmpty) {
      final a = albums.first;
      return TopResult(
        title: a.title,
        subtitle: '${a.year} • ${a.artist}',
        badge: 'Album',
        imageUrl: a.imageUrl,
        circular: false,
      );
    }
    if (artists.isNotEmpty) return _artistTop(artists.first);
    if (playlists.isNotEmpty) {
      final p = playlists.first;
      return TopResult(
        title: p.title,
        subtitle: 'By ${p.owner}',
        badge: 'Playlist',
        imageUrl: p.imageUrl,
        circular: false,
      );
    }
    if (episodes.isNotEmpty) {
      final e = episodes.first;
      return TopResult(
        title: e.title,
        subtitle: e.artist,
        badge: 'Episode',
        imageUrl: e.imageUrl,
        circular: false,
        track: e,
      );
    }
    return null;
  }

  TopResult _artistTop(Artist a) => TopResult(
    title: a.name,
    subtitle: 'Artist',
    badge: 'Artist',
    imageUrl: a.imageUrl,
    circular: true,
  );
}

@immutable
class RecentSearch {
  const RecentSearch({required this.text, required this.kind});

  final String text;
  final String kind;

  Map<String, String> toJson() => {'text': text, 'kind': kind};

  static RecentSearch? tryParse(String raw) {
    try {
      final map = jsonDecode(raw);
      if (map is Map && map['text'] is String) {
        return RecentSearch(
          text: map['text'] as String,
          kind: (map['kind'] as String?) ?? 'Search',
        );
      }
    } catch (_) {}
    return null;
  }
}

// ===== 3. MOCK DATA & REPOSITORY =====

abstract class SearchRepository {
  List<GenreCategory> get categories;
  Track get featuredTrack;
  Future<List<String>> suggestions(String query);

  /// Searching for the word "error" throws, to let you test the error state.
  Future<SearchResults> search(String query, {String? genreKey});
}

class FakeSearchRepository implements SearchRepository {
  FakeSearchRepository();

  final math.Random _rng = math.Random();

  static const List<GenreCategory> _categories = [
    GenreCategory(
      key: 'pop',
      name: 'Pop',
      color: Color(0xFFE13300),
      seed: 'cat-pop',
    ),
    GenreCategory(
      key: 'hiphop',
      name: 'Hip-Hop',
      color: Color(0xFFBC5900),
      seed: 'cat-hiphop',
    ),
    GenreCategory(
      key: 'rock',
      name: 'Rock',
      color: Color(0xFFE91429),
      seed: 'cat-rock',
    ),
    GenreCategory(
      key: 'electronic',
      name: 'Dance/Electronic',
      color: Color(0xFF0D73EC),
      seed: 'cat-dance',
    ),
    GenreCategory(
      key: 'jazz',
      name: 'Jazz',
      color: Color(0xFF477D95),
      seed: 'cat-jazz',
    ),
    GenreCategory(
      key: 'podcast',
      name: 'Podcasts',
      color: Color(0xFF8D67AB),
      seed: 'cat-podcast',
    ),
    GenreCategory(
      key: 'charts',
      name: 'Charts',
      color: Color(0xFF8C1932),
      seed: 'cat-charts',
    ),
    GenreCategory(
      key: 'new',
      name: 'New Releases',
      color: Color(0xFF608108),
      seed: 'cat-new',
    ),
    GenreCategory(
      key: 'mood',
      name: 'Mood',
      color: Color(0xFFAF2896),
      seed: 'cat-mood',
    ),
    GenreCategory(
      key: 'workout',
      name: 'Workout',
      color: Color(0xFF503750),
      seed: 'cat-workout',
    ),
    GenreCategory(
      key: 'chill',
      name: 'Chill',
      color: Color(0xFF1E3264),
      seed: 'cat-chill',
    ),
    GenreCategory(
      key: 'indie',
      name: 'Indie',
      color: Color(0xFF148A08),
      seed: 'cat-indie',
    ),
  ];

  static const List<Artist> _artists = [
    Artist(
      id: 'ar1',
      name: 'Luna Vega',
      seed: 'luna',
      genres: ['pop', 'charts'],
    ),
    Artist(
      id: 'ar2',
      name: 'The Paper Lanterns',
      seed: 'lanterns',
      genres: ['indie', 'chill'],
    ),
    Artist(
      id: 'ar3',
      name: 'Kairo Beats',
      seed: 'kairo',
      genres: ['electronic', 'workout'],
    ),
    Artist(
      id: 'ar4',
      name: 'Marlow & Finch',
      seed: 'marlow',
      genres: ['jazz', 'mood'],
    ),
    Artist(id: 'ar5', name: 'Dusty Rivers', seed: 'dusty', genres: ['rock']),
    Artist(
      id: 'ar6',
      name: 'Nova Kane',
      seed: 'nova',
      genres: ['hiphop', 'new'],
    ),
  ];

  static const List<Album> _albums = [
    Album(
      id: 'al1',
      title: 'Midnight Static',
      artist: 'Luna Vega',
      year: 2024,
      seed: 'midnight',
      genres: ['pop', 'charts'],
    ),
    Album(
      id: 'al2',
      title: 'Lantern Season',
      artist: 'The Paper Lanterns',
      year: 2023,
      seed: 'season',
      genres: ['indie', 'mood'],
    ),
    Album(
      id: 'al3',
      title: 'Pulse Engine',
      artist: 'Kairo Beats',
      year: 2025,
      seed: 'pulse',
      genres: ['electronic', 'workout', 'new'],
    ),
    Album(
      id: 'al4',
      title: 'Blue Hour Sessions',
      artist: 'Marlow & Finch',
      year: 2022,
      seed: 'bluehour',
      genres: ['jazz', 'chill'],
    ),
    Album(
      id: 'al5',
      title: 'Gravel Roads',
      artist: 'Dusty Rivers',
      year: 2021,
      seed: 'gravel',
      genres: ['rock'],
    ),
    Album(
      id: 'al6',
      title: 'Crown Season',
      artist: 'Nova Kane',
      year: 2025,
      seed: 'crown',
      genres: ['hiphop', 'new'],
    ),
  ];

  static const List<Playlist> _playlists = [
    Playlist(
      id: 'pl1',
      title: 'Morning Glow',
      owner: 'Mixtape Studio',
      seed: 'glow',
      genres: ['pop', 'chill'],
    ),
    Playlist(
      id: 'pl2',
      title: 'Deep Focus',
      owner: 'Mixtape Studio',
      seed: 'focus',
      genres: ['chill', 'mood'],
    ),
    Playlist(
      id: 'pl3',
      title: 'Gym Fuel',
      owner: 'Kairo Beats',
      seed: 'gym',
      genres: ['workout', 'electronic'],
    ),
    Playlist(
      id: 'pl4',
      title: 'Indie Sunday',
      owner: 'Lantern Radio',
      seed: 'sunday',
      genres: ['indie'],
    ),
    Playlist(
      id: 'pl5',
      title: 'Rock Remix Classics',
      owner: 'Dusty Rivers',
      seed: 'remix',
      genres: ['rock'],
    ),
    Playlist(
      id: 'pl6',
      title: "Today's Top Hits",
      owner: 'Mixtape Studio',
      seed: 'tophits',
      genres: ['charts', 'pop', 'hiphop', 'new'],
    ),
  ];

  static const List<Track> _tracks = [
    Track(
      id: 't1',
      title: 'Neon Skyline',
      artist: 'Luna Vega',
      album: 'Midnight Static',
      seed: 'midnight',
      durationSec: 214,
      genres: ['pop', 'charts'],
    ),
    Track(
      id: 't2',
      title: 'Glass Hearts',
      artist: 'Luna Vega',
      album: 'Midnight Static',
      seed: 'midnight',
      durationSec: 198,
      genres: ['pop'],
    ),
    Track(
      id: 't3',
      title: 'Paper Moon',
      artist: 'The Paper Lanterns',
      album: 'Lantern Season',
      seed: 'season',
      durationSec: 187,
      genres: ['indie', 'mood'],
    ),
    Track(
      id: 't4',
      title: 'Slow Burn Summer',
      artist: 'The Paper Lanterns',
      album: 'Lantern Season',
      seed: 'season',
      durationSec: 232,
      genres: ['indie', 'chill'],
    ),
    Track(
      id: 't5',
      title: 'Overdrive',
      artist: 'Kairo Beats',
      album: 'Pulse Engine',
      seed: 'pulse',
      durationSec: 205,
      genres: ['electronic', 'workout'],
    ),
    Track(
      id: 't6',
      title: 'Gravity Loop',
      artist: 'Kairo Beats',
      album: 'Pulse Engine',
      seed: 'pulse',
      durationSec: 241,
      genres: ['electronic', 'new'],
    ),
    Track(
      id: 't7',
      title: 'Blue Hour',
      artist: 'Marlow & Finch',
      album: 'Blue Hour Sessions',
      seed: 'bluehour',
      durationSec: 276,
      genres: ['jazz', 'chill'],
    ),
    Track(
      id: 't8',
      title: 'Velvet Rain',
      artist: 'Marlow & Finch',
      album: 'Blue Hour Sessions',
      seed: 'bluehour',
      durationSec: 259,
      genres: ['jazz', 'mood'],
    ),
    Track(
      id: 't9',
      title: 'Dust & Thunder',
      artist: 'Dusty Rivers',
      album: 'Gravel Roads',
      seed: 'gravel',
      durationSec: 223,
      genres: ['rock'],
    ),
    Track(
      id: 't10',
      title: 'Highway Ghost',
      artist: 'Dusty Rivers',
      album: 'Gravel Roads',
      seed: 'gravel',
      durationSec: 249,
      genres: ['rock', 'charts'],
    ),
    Track(
      id: 't11',
      title: 'Crown Heavy',
      artist: 'Nova Kane',
      album: 'Crown Season',
      seed: 'crown',
      durationSec: 190,
      explicit: true,
      genres: ['hiphop', 'new'],
    ),
    Track(
      id: 't12',
      title: 'Late Night Receipts',
      artist: 'Nova Kane',
      album: 'Crown Season',
      seed: 'crown',
      durationSec: 201,
      explicit: true,
      genres: ['hiphop', 'charts'],
    ),
    Track(
      id: 'e1',
      title: 'The Sound of Tomorrow - Ep. 42',
      artist: 'Studio Frequencies',
      album: 'Podcast',
      seed: 'ep-studio',
      durationSec: 2410,
      isEpisode: true,
      genres: ['podcast'],
    ),
    Track(
      id: 'e2',
      title: 'Why We Love Sad Songs',
      artist: 'Liner Notes',
      album: 'Podcast',
      seed: 'ep-liner',
      durationSec: 1820,
      isEpisode: true,
      genres: ['podcast'],
    ),
    Track(
      id: 'e3',
      title: 'Building a Beat from Scratch',
      artist: 'Studio Frequencies',
      album: 'Podcast',
      seed: 'ep-beat',
      durationSec: 2105,
      isEpisode: true,
      genres: ['podcast'],
    ),
  ];

  @override
  List<GenreCategory> get categories => _categories;

  @override
  Track get featuredTrack => _tracks.first;

  @override
  Future<List<String>> suggestions(String query) async {
    await Future<void>.delayed(const Duration(milliseconds: 80));
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return const [];
    final pool = <String>{
      for (final t in _tracks) t.title,
      for (final a in _artists) a.name,
      for (final a in _albums) a.title,
      for (final p in _playlists) p.title,
      for (final c in _categories) c.name,
    };
    final hits = pool.where((s) => s.toLowerCase().contains(q)).toList()
      ..sort((a, b) {
        final sa = a.toLowerCase().startsWith(q) ? 0 : 1;
        final sb = b.toLowerCase().startsWith(q) ? 0 : 1;
        return sa != sb ? sa - sb : a.compareTo(b);
      });
    return hits.take(6).toList();
  }

  @override
  Future<SearchResults> search(String query, {String? genreKey}) async {
    await Future<void>.delayed(Duration(milliseconds: 400 + _rng.nextInt(401)));
    final q = query.trim().toLowerCase();
    if (q == 'error') throw Exception('Simulated network error');

    bool hit(List<String> genres, List<String> fields) {
      if (genreKey != null) return genres.contains(genreKey);
      return [...fields, ...genres].any((s) => s.toLowerCase().contains(q));
    }

    return SearchResults(
      tracks: [
        for (final t in _tracks)
          if (!t.isEpisode && hit(t.genres, [t.title, t.artist, t.album])) t,
      ],
      episodes: [
        for (final t in _tracks)
          if (t.isEpisode && hit(t.genres, [t.title, t.artist])) t,
      ],
      artists: [
        for (final a in _artists)
          if (hit(a.genres, [a.name])) a,
      ],
      albums: [
        for (final a in _albums)
          if (hit(a.genres, [a.title, a.artist])) a,
      ],
      playlists: [
        for (final p in _playlists)
          if (hit(p.genres, [p.title, p.owner])) p,
      ],
      genres: genreKey != null
          ? const []
          : [
              for (final c in _categories)
                if (c.name.toLowerCase().contains(q) || c.key.contains(q)) c,
            ],
    );
  }
}

// ===== 4. CONTROLLER & STATE =====

sealed class SearchState {
  const SearchState();
}

final class SearchIdle extends SearchState {
  const SearchIdle();
}

final class SearchTyping extends SearchState {
  const SearchTyping(this.query, this.suggestions);
  final String query;
  final List<String> suggestions;
}

final class SearchLoading extends SearchState {
  const SearchLoading(this.query);
  final String query;
}

final class SearchSuccess extends SearchState {
  const SearchSuccess(this.query, this.results);
  final String query;
  final SearchResults results;
}

final class SearchEmpty extends SearchState {
  const SearchEmpty(this.query);
  final String query;
}

final class SearchError extends SearchState {
  const SearchError(this.query, this.message);
  final String query;
  final String message;
}

class SearchPageController extends ChangeNotifier {
  SearchPageController(this._repo);

  final SearchRepository _repo;

  static const String _prefsKey = 'recent_searches_v1';
  static const int _maxRecents = 10;

  SearchState _state = const SearchIdle();
  SearchFilter _filter = SearchFilter.all;
  List<RecentSearch> _recents = const [];

  Timer? _debounce;
  int _requestId = 0;
  int _suggestionId = 0;
  String _activeQuery = '';
  String? _activeGenreKey;
  bool _disposed = false;

  SearchState get state => _state;
  SearchFilter get filter => _filter;
  List<RecentSearch> get recents => _recents;
  List<GenreCategory> get categories => _repo.categories;
  Track get featuredTrack => _repo.featuredTrack;

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList(_prefsKey) ?? const <String>[];
      _recents = [
        for (final r in raw)
          if (RecentSearch.tryParse(r) case final parsed?) parsed,
      ];
      _notify();
    } catch (_) {
      // Storage unavailable: recents simply stay empty.
    }
  }

  void onQueryChanged(String raw) {
    _debounce?.cancel();
    final q = raw.trim();
    if (q.isEmpty) {
      _requestId++;
      _suggestionId++;
      _filter = SearchFilter.all;
      _setState(const SearchIdle());
      return;
    }
    final current = _state;
    _setState(
      SearchTyping(q, current is SearchTyping ? current.suggestions : const []),
    );
    _loadSuggestions(q);
    _debounce = Timer(AppDurations.debounce, () => _runSearch(q));
  }

  void submit(String raw, {String? genreKey}) {
    _debounce?.cancel();
    final q = raw.trim();
    if (q.isEmpty) return;
    _suggestionId++;
    _runSearch(q, saveRecent: true, genreKey: genreKey);
  }

  void retry() {
    if (_activeQuery.isEmpty) return;
    _runSearch(_activeQuery, genreKey: _activeGenreKey);
  }

  void setFilter(SearchFilter f) {
    if (f == _filter) return;
    _filter = f;
    _notify();
  }

  Future<void> removeRecent(RecentSearch r) async {
    _recents = _recents.where((e) => e.text != r.text).toList();
    _notify();
    await _persist();
  }

  Future<void> clearRecents() async {
    _recents = const [];
    _notify();
    await _persist();
  }

  Future<void> _loadSuggestions(String q) async {
    final id = ++_suggestionId;
    final list = await _repo.suggestions(q);
    if (_disposed || id != _suggestionId || _state is! SearchTyping) return;
    _setState(SearchTyping(q, list));
  }

  Future<void> _runSearch(
    String q, {
    bool saveRecent = false,
    String? genreKey,
  }) async {
    final id = ++_requestId;
    _activeQuery = q;
    _activeGenreKey = genreKey;
    _setState(SearchLoading(q));
    try {
      final results = await _repo.search(q, genreKey: genreKey);
      if (_disposed || id != _requestId) return; // stale response
      if (results.isEmpty) {
        _setState(SearchEmpty(q));
        return;
      }
      _setState(SearchSuccess(q, results));
      if (saveRecent) {
        await _addRecent(q, results.topFor(q)?.badge ?? 'Search');
      }
    } catch (_) {
      if (_disposed || id != _requestId) return;
      _setState(
        const SearchError(
          '',
          'Something went wrong. Check your connection and try again.',
        ),
      );
    }
  }

  Future<void> _addRecent(String text, String kind) async {
    final next = <RecentSearch>[
      RecentSearch(text: text, kind: kind),
      ..._recents.where((r) => r.text.toLowerCase() != text.toLowerCase()),
    ];
    _recents = next.take(_maxRecents).toList();
    _notify();
    await _persist();
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_prefsKey, [
        for (final r in _recents) jsonEncode(r.toJson()),
      ]);
    } catch (_) {}
  }

  void _setState(SearchState s) {
    _state = s;
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _debounce?.cancel();
    super.dispose();
  }
}

// ===== 5. SHARED WIDGETS =====

bool get _isIOS => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

double _textScale(BuildContext context) =>
    (MediaQuery.textScalerOf(context).scale(16) / 16).clamp(1.0, 1.6);

/// Liquid Glass surface. Native on iOS 26+, blur fallback everywhere else.
class _GlassSurface extends StatelessWidget {
  const _GlassSurface({
    required this.radius,
    required this.child,
    this.padding = EdgeInsets.zero,
    this.native = false,
  });

  final double radius;
  final Widget child;
  final EdgeInsetsGeometry padding;

  /// Use the platform-view glass. Keep it for a few static surfaces only:
  /// platform views are expensive inside long scrolling lists.
  final bool native;

  @override
  Widget build(BuildContext context) {
    if (native && _isIOS && PlatformVersion.shouldUseNativeGlass) {
      return LiquidGlassContainer(
        config: LiquidGlassConfig(
          effect: CNGlassEffect.regular,
          shape: CNGlassEffectShape.rect,
          cornerRadius: radius,
          interactive: false,
        ),
        child: Padding(padding: padding, child: child),
      );
    }
    final p = AppPalette.of(context);
    final shape = BorderRadius.circular(radius);
    // FALLBACK: blur + translucent fill.
    return ClipRRect(
      borderRadius: shape,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: p.glassFill,
            borderRadius: shape,
            border: Border.all(color: p.glassBorder, width: 0.5),
          ),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

class _CoverImage extends StatelessWidget {
  const _CoverImage({
    required this.url,
    required this.size,
    this.radius = AppRadius.s,
    this.circular = false,
  });

  final String url;
  final double size;
  final double radius;
  final bool circular;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(circular ? size / 2 : radius),
      child: CachedNetworkImage(
        imageUrl: url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        placeholder: (_, _) => SizedBox(
          width: size,
          height: size,
          child: ColoredBox(color: p.surface),
        ),
        errorWidget: (_, _, _) => SizedBox(
          width: size,
          height: size,
          child: ColoredBox(
            color: p.surface,
            child: Icon(
              CupertinoIcons.music_note,
              size: size * 0.4,
              color: p.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.actionLabel, this.onAction});

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.l,
        AppSpacing.xl,
        AppSpacing.l,
        AppSpacing.s,
      ),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(title, style: AppTextStyles.sectionTitle(p)),
            ),
          ),
          if (actionLabel != null)
            CupertinoButton(
              padding: EdgeInsets.zero,
              minimumSize: const Size(44, 44),
              onPressed: onAction,
              child: Text(actionLabel!, style: AppTextStyles.link(p)),
            ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.xxl * 2,
        AppSpacing.xl,
        AppSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 56, color: p.textSecondary),
          const SizedBox(height: AppSpacing.l),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTextStyles.sectionTitle(p),
          ),
          const SizedBox(height: AppSpacing.s),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: AppTextStyles.rowSubtitle(p),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _EmptyState(
          icon: CupertinoIcons.wifi_exclamationmark,
          title: 'Connection problem',
          subtitle: message,
        ),
        CNButton(
          label: 'Try again',
          config: const CNButtonConfig(style: CNButtonStyle.prominentGlass),
          onPressed: onRetry,
        ),
      ],
    );
  }
}

class _Shimmer extends StatefulWidget {
  const _Shimmer({required this.child});
  final Widget child;

  @override
  State<_Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<_Shimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppDurations.shimmer,
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) => ShaderMask(
        blendMode: BlendMode.srcATop,
        shaderCallback: (bounds) => LinearGradient(
          colors: [p.shimmerBase, p.shimmerHighlight, p.shimmerBase],
          stops: const [0.35, 0.5, 0.65],
          transform: _SlideGradient(-1 + 2 * _controller.value),
        ).createShader(bounds),
        child: child,
      ),
    );
  }
}

class _SlideGradient extends GradientTransform {
  const _SlideGradient(this.percent);
  final double percent;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) =>
      Matrix4.translationValues(bounds.width * percent, 0, 0);
}

class _Marquee extends StatefulWidget {
  const _Marquee({required this.text, required this.style});
  final String text;
  final TextStyle style;

  @override
  State<_Marquee> createState() => _MarqueeState();
}

class _MarqueeState extends State<_Marquee> {
  final ScrollController _scroll = ScrollController();
  int _run = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loop(++_run));
  }

  @override
  void didUpdateWidget(covariant _Marquee oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      if (_scroll.hasClients) _scroll.jumpTo(0);
      WidgetsBinding.instance.addPostFrameCallback((_) => _loop(++_run));
    }
  }

  Future<void> _loop(int run) async {
    while (mounted && run == _run) {
      await Future<void>.delayed(const Duration(seconds: 2));
      if (!mounted || run != _run || !_scroll.hasClients) return;
      final extent = _scroll.position.maxScrollExtent;
      if (extent <= 0) return; // fits: nothing to scroll
      await _scroll.animateTo(
        extent,
        duration: Duration(milliseconds: (extent * 40).round()),
        curve: Curves.linear,
      );
      await Future<void>.delayed(const Duration(seconds: 1));
      if (!mounted || run != _run || !_scroll.hasClients) return;
      _scroll.jumpTo(0);
    }
  }

  @override
  void dispose() {
    _run++;
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    controller: _scroll,
    scrollDirection: Axis.horizontal,
    physics: const NeverScrollableScrollPhysics(),
    child: Text(widget.text, maxLines: 1, softWrap: false, style: widget.style),
  );
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.fill,
    this.iconColor,
    this.diameter = 40,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? fill;
  final Color? iconColor;
  final double diameter;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          width: AppSizes.iconButton,
          height: AppSizes.iconButton,
          child: Center(
            child: Container(
              width: diameter,
              height: diameter,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: fill ?? p.glassFill,
                border: Border.all(color: p.glassBorder, width: 0.5),
              ),
              child: Icon(
                icon,
                size: diameter * 0.5,
                color: iconColor ?? p.text,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ExplicitBadge extends StatelessWidget {
  const _ExplicitBadge();

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Semantics(
      label: 'Explicit',
      child: Container(
        margin: const EdgeInsets.only(right: AppSpacing.xs),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
        decoration: BoxDecoration(
          color: p.textSecondary,
          borderRadius: BorderRadius.circular(3),
        ),
        child: Text(
          'E',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: p.background,
          ),
        ),
      ),
    );
  }
}

class _GlassMiniPlayer extends StatelessWidget {
  const _GlassMiniPlayer({
    required this.track,
    required this.playing,
    required this.progress,
    required this.onToggle,
    required this.onOpen,
    required this.onDevices,
  });

  final Track track;
  final bool playing;
  final double progress;
  final VoidCallback onToggle;
  final VoidCallback onOpen;
  final VoidCallback onDevices;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return SizedBox(
      height: AppSizes.miniPlayer,
      child: _GlassSurface(
        radius: AppRadius.pill,
        native: true,
        child: Stack(
          children: [
            Positioned.fill(
              child: Semantics(
                button: true,
                label:
                    'Now playing ${track.title} by ${track.artist}. Open player',
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onOpen,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.m,
                    ),
                    child: Row(
                      children: [
                        _CoverImage(
                          url: track.imageUrl,
                          size: AppSizes.miniCover,
                          radius: AppRadius.m,
                        ),
                        const SizedBox(width: AppSpacing.m),
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _Marquee(
                                text: track.title,
                                style: AppTextStyles.cardTitle(p),
                              ),
                              Text(
                                track.artist,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.caption(p),
                              ),
                            ],
                          ),
                        ),
                        _CircleButton(
                          icon: CupertinoIcons.device_laptop,
                          label: 'Connect to a device',
                          onTap: onDevices,
                          fill: const Color(0x00000000),
                        ),
                        _CircleButton(
                          icon: playing
                              ? CupertinoIcons.pause_fill
                              : CupertinoIcons.play_fill,
                          label: playing ? 'Pause' : 'Play',
                          onTap: onToggle,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: AppSpacing.xl,
              right: AppSpacing.xl,
              bottom: AppSpacing.xs,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(1),
                child: SizedBox(
                  height: 2,
                  child: Stack(
                    children: [
                      Positioned.fill(child: ColoredBox(color: p.divider)),
                      FractionallySizedBox(
                        widthFactor: progress.clamp(0.0, 1.0),
                        child: ColoredBox(color: p.accent),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomTabBar extends StatelessWidget {
  const _BottomTabBar({required this.currentIndex, required this.onTap});

  final int currentIndex;
  final ValueChanged<int> onTap;

  static const List<CNTabBarItem> _items = [
    CNTabBarItem(
      label: 'Home',
      icon: CNSymbol('house'),
      activeIcon: CNSymbol('house.fill'),
    ),
    CNTabBarItem(label: 'Search', icon: CNSymbol('magnifyingglass')),
    CNTabBarItem(
      label: 'Library',
      icon: CNSymbol('books.vertical'),
      activeIcon: CNSymbol('books.vertical.fill'),
    ),
    CNTabBarItem(
      label: 'Premium',
      icon: CNSymbol('crown'),
      activeIcon: CNSymbol('crown.fill'),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final inset = MediaQuery.paddingOf(context).bottom;
    final height = AppSizes.tabBar + inset;

    if (_isIOS) {
      return SizedBox(
        height: height,
        child: CNTabBar(
          items: _items,
          currentIndex: currentIndex,
          onTap: onTap,
        ),
      );
    }
    // FALLBACK: non-iOS platforms.
    return CupertinoTabBar(
      currentIndex: currentIndex,
      onTap: onTap,
      activeColor: p.accent,
      inactiveColor: p.textSecondary,
      backgroundColor: p.background.withValues(alpha: 0.85),
      items: const [
        BottomNavigationBarItem(
          icon: Icon(CupertinoIcons.house),
          activeIcon: Icon(CupertinoIcons.house_fill),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(CupertinoIcons.search),
          label: 'Search',
        ),
        BottomNavigationBarItem(
          icon: Icon(CupertinoIcons.music_albums),
          activeIcon: Icon(CupertinoIcons.music_albums_fill),
          label: 'Library',
        ),
        BottomNavigationBarItem(
          icon: Icon(CupertinoIcons.star),
          activeIcon: Icon(CupertinoIcons.star_fill),
          label: 'Premium',
        ),
      ],
    );
  }
}

class _ToastPill extends StatelessWidget {
  const _ToastPill(this.message);
  final String message;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return _GlassSurface(
      radius: AppRadius.pill,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.m,
      ),
      child: DefaultTextStyle(
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: p.text,
          decoration: TextDecoration.none,
        ),
        child: Text(message, textAlign: TextAlign.center),
      ),
    );
  }
}

class _FullPlayerPage extends StatelessWidget {
  const _FullPlayerPage({required this.track});
  final Track track;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return CupertinoPageScaffold(
      backgroundColor: p.background,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: p.background.withValues(alpha: 0.8),
        middle: const Text('Now playing'),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.of(context).pop(),
          child: const Icon(CupertinoIcons.chevron_down),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              LayoutBuilder(
                builder: (context, c) => _CoverImage(
                  url: track.imageUrl,
                  size: math.min(c.maxWidth, 340),
                  radius: AppRadius.xl,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                track.title,
                textAlign: TextAlign.center,
                style: AppTextStyles.topTitle(p),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(track.artist, style: AppTextStyles.rowSubtitle(p)),
              const SizedBox(height: AppSpacing.xl),
              Text('Full player stub', style: AppTextStyles.caption(p)),
            ],
          ),
        ),
      ),
    );
  }
}

// ===== 6. SEARCH SECTIONS =====

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
  const _TitleRow({required this.onCamera});
  final VoidCallback onCamera;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Row(
      children: [
        const _CoverImage(
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
        SizedBox(
          width: AppSizes.iconButton,
          height: AppSizes.iconButton,
          child: CNButton.icon(
            icon: const CNSymbol('camera', size: 18),
            config: const CNButtonConfig(style: CNButtonStyle.glass),
            semanticLabel: 'Search by camera',
            onPressed: onCamera,
          ),
        ),
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
                  child: _CoverImage(
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
          _SectionHeader(
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
        const _SectionHeader(title: 'Browse all'),
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
      child: _Shimmer(
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
                _CoverImage(url: track.imageUrl, size: AppSizes.trackCover),
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
                          if (track.explicit) const _ExplicitBadge(),
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
              _CoverImage(
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
              _CoverImage(
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
              _CoverImage(
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
          child: _GlassSurface(
            radius: AppRadius.xl,
            native: true,
            padding: const EdgeInsets.all(AppSpacing.l),
            child: Stack(
              children: [
                Row(
                  children: [
                    _CoverImage(
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
                  child: _CircleButton(
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

class _Carousel extends StatelessWidget {
  const _Carousel({
    required this.height,
    required this.itemCount,
    required this.itemBuilder,
  });

  final double height;
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: height,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
      itemCount: itemCount,
      separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.m),
      itemBuilder: itemBuilder,
    ),
  );
}

class _WrapGrid extends StatelessWidget {
  const _WrapGrid({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      AppSpacing.l,
      AppSpacing.l,
      AppSpacing.l,
      0,
    ),
    child: Wrap(
      spacing: AppSpacing.m,
      runSpacing: AppSpacing.l,
      children: children,
    ),
  );
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

  Widget _artists(BuildContext context) => _Carousel(
    height: AppSizes.artistAvatar + AppSpacing.s + 36 * _textScale(context),
    itemCount: results.artists.length,
    itemBuilder: (_, i) => _ArtistCard(
      artist: results.artists[i],
      onTap: () => onOpen(results.artists[i].name),
    ),
  );

  Widget _albums(BuildContext context) => _Carousel(
    height: AppSizes.albumCover + AppSpacing.s + 36 * _textScale(context),
    itemCount: results.albums.length,
    itemBuilder: (_, i) => _AlbumCard(
      album: results.albums[i],
      onTap: () => onOpen(results.albums[i].title),
    ),
  );

  Widget _playlists(BuildContext context) => _Carousel(
    height: AppSizes.playlistCover + AppSpacing.s + 52 * _textScale(context),
    itemCount: results.playlists.length,
    itemBuilder: (_, i) => _PlaylistCard(
      playlist: results.playlists[i],
      onTap: () => onOpen(results.playlists[i].title),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);

    if (!results.hasFor(filter)) {
      return _EmptyState(
        icon: CupertinoIcons.search,
        title: 'No ${filter.label.toLowerCase()} for “$query”',
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
              _SectionHeader(
                title: 'Songs',
                actionLabel: 'Show all',
                onAction: () => onFilter(SearchFilter.songs),
              ),
              ..._tracks(results.tracks.take(5).toList()),
            ],
            if (results.artists.isNotEmpty) ...[
              _SectionHeader(
                title: 'Artists',
                actionLabel: 'Show all',
                onAction: () => onFilter(SearchFilter.artists),
              ),
              _artists(context),
            ],
            if (results.albums.isNotEmpty) ...[
              _SectionHeader(
                title: 'Albums',
                actionLabel: 'Show all',
                onAction: () => onFilter(SearchFilter.albums),
              ),
              _albums(context),
            ],
            if (results.playlists.isNotEmpty) ...[
              _SectionHeader(
                title: 'Playlists',
                actionLabel: 'Show all',
                onAction: () => onFilter(SearchFilter.playlists),
              ),
              _playlists(context),
            ],
            if (results.episodes.isNotEmpty) ...[
              _SectionHeader(
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
        return _WrapGrid(
          children: [
            for (final a in results.artists)
              _ArtistCard(artist: a, onTap: () => onOpen(a.name)),
          ],
        );
      case SearchFilter.albums:
        return _WrapGrid(
          children: [
            for (final a in results.albums)
              _AlbumCard(album: a, onTap: () => onOpen(a.title)),
          ],
        );
      case SearchFilter.playlists:
        return _WrapGrid(
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

// ===== 7. SEARCH PAGE =====

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
        builder: (_) => _FullPlayerPage(track: _nowPlaying),
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
        child: IgnorePointer(child: Center(child: _ToastPill(message))),
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
      SearchEmpty(:final query) => _EmptyState(
        icon: CupertinoIcons.search,
        title: 'No results for “$query”',
        subtitle: 'Check the spelling or try a different keyword.',
      ),
      SearchError(:final message) => _ErrorState(
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
                  onCamera: () => _showToast('Camera search coming soon'),
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
              child: _GlassMiniPlayer(
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
              child: _BottomTabBar(
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
