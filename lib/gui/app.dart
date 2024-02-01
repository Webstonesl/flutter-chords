import 'package:flutter/material.dart';
import 'package:song_viewer/gui/pages/lists/songspage.dart';
import 'package:song_viewer/gui/pages/viewers/songeditor.dart';

import 'mainpage.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Song Viewer',
      darkTheme: ThemeData.dark(useMaterial3: true),
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
        useMaterial3: true,
      ),
      initialRoute: '/songs',
      routes: {
        '/': (context) => const MyHomePage(title: 'Song Viewer'),
        '/songs': (context) => SongsPage(),
        '/songs/editor': (context) => const SongEditorPage()
      },
    );
  }
}
