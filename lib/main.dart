import 'package:flutter/cupertino.dart';

import 'search_page.dart'; // Assicurati che search_page.dart sia nella stessa cartella (lib/)

void main() {
  runApp(const SpotifySearchApp());
}

class SpotifySearchApp extends StatelessWidget {
  const SpotifySearchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const CupertinoApp(
      title: 'Spotify Search Demo',
      debugShowCheckedModeBanner: false,
      // Impostiamo il tema scuro di default (può adattarsi automaticamente in base alle impostazioni di sistema)
      theme: CupertinoThemeData(
        brightness: Brightness.dark,
        primaryColor: Color(0xFF1DB954), // Verde in stile Spotify
      ),
      home: SearchPage(),
    );
  }
}
