import 'package:flutter/material.dart';
import 'package:song_viewer/gui/pages/lists/chordsheets.dart';

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
      initialRoute: '/chordsheets',
      routes: {
        '/': (context) => const MyHomePage(title: 'Song Viewer'),
        '/chordsheets': (context) => const ChordsheetListView(),
      },
    );
  }
}
