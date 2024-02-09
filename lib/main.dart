import 'dart:io';

import 'package:flutter/material.dart';
import 'package:song_viewer/libs/database.dart';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path_provider/path_provider.dart';
import 'gui/app.dart';
import 'package:path/path.dart' as path;

Future<void> main() async {
  if (Platform.isLinux || Platform.isWindows) {
    sqfliteFfiInit();
  }

  databaseFactory = databaseFactoryFfi;
  String os = Platform.operatingSystem;

  if (Platform.isLinux) {
    Map<String, String> envVars = Platform.environment;
    String home = envVars['HOME']!;
    print(home);
    String dir = [
      '',
      for (String v in home.split('/'))
        if (v.trim().isNotEmpty) v,
      '.local/song_viewer'
    ].join("/");
    if (!Directory(dir).existsSync()) {
      Directory(dir).createSync(recursive: true);
    }
    await MyDatabase.getDatabase(path: '$dir/chordsheets.sqlite3')
        .then((value) {
      runApp(const MyApp());
    });
  } else {
    getDatabasesPath().then((value) async {
      MyDatabase.getDatabase(path: path.join(value, "chordsheets2.sqlite3"))
          .then(
        (value) {
          runApp(const MyApp());
        },
      );
    });
  }

  if (Platform.isLinux || Platform.isMacOS || Platform.isWindows) {
    print(Directory.current);
  }
}
