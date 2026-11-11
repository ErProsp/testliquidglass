// lib/shared/controller.dart
//
// Shared SearchPageController and SearchState logic.

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'theme.dart';
import 'models.dart';
import 'repository.dart';

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