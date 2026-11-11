// lib/shared/models.dart
//
// Shared data models used across pages.

import 'dart:convert';
import 'package:flutter/cupertino.dart';

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