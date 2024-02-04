import 'dart:ui';

import 'package:song_viewer/libs/songstructure/chordsheets/chordsheet.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:uuid/uuid.dart';

abstract class Model {
  static Set<Uuid> UUIDS = {};
  Uuid? _uuid;
  Uuid? get uuid => _uuid;
  set uuid(Uuid? uuid) {
    if (uuid == null) return;
    if (UUIDS.contains(uuid)) {
      throw Exception("Duplicate UUIDS");
    }
  }

  Map<String, dynamic> get data {
    Map<String, dynamic> d = _getData();
    d["datatype"] = runtimeType.toString();
    d["uuid"] = uuid.toString();
    return d;
  }

  Map<String, dynamic> _getData();
  bool save() {
    return false;
  }

  bool delete() {
    return false;
  }
}

class MyDatabase {
  static MyDatabase? _database;
  late Database db;
  MyDatabase() {}

  Map<Uuid, Model> _map = <Uuid, Model>{};
  Future<Model?> getModel(Uuid uuid) async {
    List<Map<String, dynamic>> l = await db
        .query("items", where: "uuid = ?", whereArgs: [uuid.toString()]);
    for (Map<String, dynamic> entry in l) {
      print(entry["datatype"]);
      for (String key in entry.keys) {}
    }
  }

  Future<List<Chordsheet>> getChordsheets() async {
    return [];
  }

  static Future<MyDatabase> getDatabase({required String path}) async {
    if (_database != null) {
      return _database!;
    }
    MyDatabase database = MyDatabase();

    database.db = await databaseFactory.openDatabase(path,
        options: OpenDatabaseOptions(
          version: 1,
          onCreate: (db, version) {
            db.execute('''
              CREATE TABLE items (
                uuid TEXT,
                data TEXT,
                PRIMARY KEY(uuid)
              );
              ''');
          },
        ));
    _database = database;

    return _database!;
  }

  void insert(List<Chordsheet> sheets) {}
}
