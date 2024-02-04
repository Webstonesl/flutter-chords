import 'dart:convert';
import 'dart:io';

import 'package:song_viewer/libs/songstructure/chordsheets/chordsheet.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:uuid/uuid.dart';

abstract class Model {
  static Uuid UUID = const Uuid();
  static Set<String> UUIDS = {};
  bool saved = false;
  String? _uuid;
  String get uuid {
    _uuid ??= UUID.v4();
    return _uuid!;
  }

  set uuid(String? uuid) {
    if (uuid == null) return;
    if (UUIDS.contains(uuid)) {
      throw Exception("Duplicate UUIDS");
    }
  }

  Map<String, dynamic> get data {
    Map<String, dynamic> d = getData();
    d["datatype"] = runtimeType.toString();
    d["uuid"] = uuid;
    return d;
  }

  Map<dynamic, dynamic>? oldData;
  Map<String, dynamic> getData();
  Future<void> _save(MyDatabase database, Map<dynamic, dynamic> newData) async {
    print(jsonEncode(newData));
  }

  Future<dynamic> _screen(dynamic item, MyDatabase database) async {
    if (item is Model) {
      return await item.save(database);
    } else if (item is Map) {
      return await _screenMap(item, database);
    } else if (item is Iterable) {
      return await _screenList(item, database);
    } else {
      return item;
    }
  }

  Future<Map<dynamic, dynamic>> _screenMap(
      Map<dynamic, dynamic> data, MyDatabase database) async {
    Map<dynamic, dynamic> result = {};
    for (dynamic key in data.keys) {
      dynamic value = await _screen(data[key], database);
      result[await _screen(key, database)] = value;
    }
    return result;
  }

  Future<List<dynamic>> _screenList(Iterable list, MyDatabase database) async {
    List<dynamic> result = [
      for (final element in list) await _screen(element, database)
    ];

    return result;
  }

  Future<Map<String, String>> save(MyDatabase database) async {
    Map<dynamic, dynamic> dt = data;
    // Filter data
    int t = 0, n = 0;
    dt = await _screen(dt, database);
    await _save(database, dt);
    while (t < n) {
      print("$t < $n");
      sleep(const Duration(milliseconds: 200));
    }
    return {'type': 'model', 'subtype': runtimeType.toString(), 'uuid': uuid};
  }
}

class MyDatabase {
  static MyDatabase? _database;
  late Database db;
  MyDatabase();

  final Map<Uuid, Model> _map = <Uuid, Model>{};
  Future<Model?> getModel(Uuid uuid) async {
    List<Map<String, dynamic>> l = await db
        .query("items", where: "uuid = ?", whereArgs: [uuid.toString()]);
    for (Map<String, dynamic> entry in l) {
      print(entry["datatype"]);
      for (String key in entry.keys) {}
    }
    return null;
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

  void insertAll(List<Model> sheets) {}

  void update(Model value) {}
}
