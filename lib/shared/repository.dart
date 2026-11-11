// lib/shared/repository.dart
//
// Shared search repository and mock data.

import 'dart:math' as math;

import 'package:flutter/cupertino.dart';

import 'models.dart';

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