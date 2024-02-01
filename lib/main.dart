import 'dart:io';

import 'package:flutter/material.dart';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'gui/app.dart';

Future<void> main() async {
  if (Platform.isLinux || Platform.isWindows) {
    sqfliteFfiInit();
  }

  databaseFactory = databaseFactoryFfi;

  runApp(const MyApp());
}
