import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:song_viewer/libs/songstructure/chordsheets/chordsheet.dart';
import 'package:song_viewer/libs/songstructure/chordsheets/elements.dart';
import 'package:song_viewer/libs/songstructure/musictheory.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:uuid/uuid.dart';

abstract class Model {
  static Uuid UUID = const Uuid();
  static Set<String> UUIDS = {};
  DateTime? lastAccess;

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
    _uuid = uuid;
  }

  Map<String, dynamic> get data {
    Map<String, dynamic> d = getData();

    return {
      "datatype": runtimeType.toString(),
      "data": getData(),
    };
  }

  Map<dynamic, dynamic>? oldData;
  Map<String, dynamic> getData();
  Future<void> _save(MyDatabase database, Map<dynamic, dynamic> newData) async {
    if (!saved) {
      await database.db
          .insert("items", {"uuid": uuid, "data": json.encode(newData)});
      saved = true;
    } else {
      if (oldData != newData) {
        print(uuid);
        print(runtimeType.toString());
        print(await database.db.update("items", {"data": json.encode(newData)},
            where: "uuid = ?", whereArgs: [uuid]));
        oldData = newData;
      }
    }
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
    database._cache[uuid] = this;
    while (t < n) {
      print("$t < $n");
      sleep(const Duration(milliseconds: 200));
    }
    return {'type': 'model', 'subtype': runtimeType.toString(), 'uuid': uuid};
  }

  Future<void> delete(MyDatabase myDatabase) async {
    await myDatabase.db
        .rawDelete("DELETE FROM \"items\" WHERE uuid = ?", [uuid]);
  }
}

class MyDatabase {
  static MyDatabase? _database;
  late Database db;
  MyDatabase();

  final Map<String, dynamic> _cacheMap = <String, Map<String, dynamic>>{};
  final Map<String, Model> _cache = <String, Model>{};
  Future<Map<String, dynamic>?> _getMap(String uuid) async {
    List<Map<String, dynamic>> item =
        await db.query("items", where: "uuid = ?", whereArgs: [uuid]);
    if (item.isEmpty) {
      return null;
    }
    return json.decode(item.first["data"]);
  }

  Future<Chordsheet?> _chordsheet(String uuid, Map<String, dynamic> map) async {
    Chordsheet cs = Chordsheet(attributes: {});
    cs.uuid = uuid;
    cs.title = map.remove("title");
    cs.attributes = map.remove("attrs");
    cs.elements = [
      for (Map<String, dynamic> element in map.remove("elements"))
        if (element["type"] == "model")
          (await getModel(element["uuid"])) as ChordsheetElement
    ];
    cs.initialState = State.fromMap(map.remove("start"));

    return cs;
  }

  Future<ChordsheetPart?> _chordsheetpart(
      String uuid, Map<String, dynamic> data) async {
    ChordsheetPart part = ChordsheetPart();
    part._uuid = uuid;
    part.title = data.remove('title');
    part.elements = [
      for (Map<String, dynamic> element in data["elements"])
        ItemElement.getItemElement(element)
    ];

    return part;
  }

  Future<ChordsheetRepeat> _chordsheetrepeat(
      String uuid, Map<String, dynamic> data) async {
    ChordsheetRepeat repeat = ChordsheetRepeat();
    repeat.s = data["title"];
    repeat.n = data["n"];
    repeat.part = (data["part"] is Map<String, dynamic>)
        ? await getModel(data["part"]["uuid"]) as ChordsheetPart
        : null;
    return repeat;
  }

  Future<Model?> getModel(String uuid) async {
    // if (_cache[uuid] != null) {
    //   return _cache[uuid]!;
    // }
    Map<String, dynamic>? data = //_cacheMap[uuid] ??
        await _getMap(uuid);
    // if (data == null) {
    //   return null;
    // }
    Model? result;
    // print(data);
    if (data == null) {
      throw Exception("Data is null for $uuid");
    }
    switch (data!["datatype"]) {
      case "Chordsheet":
        result = await _chordsheet(uuid, data["data"]);
        break;
      case "ChordsheetPart":
        result = await _chordsheetpart(uuid, data["data"]);
        break;
      case "ChordsheetTranspose":
        result = ChordsheetTranspose(data["data"]["transpose"]);
        break;
      case "ChordsheetRepeat":
        result = await _chordsheetrepeat(uuid, data["data"]);

      default:
        throw UnsupportedError('${data["datatype"]}\n${data}');
    }

    if (result != null) {
      result.uuid = uuid;

      result.saved = true;
      _cache[uuid] ??= result;
    }

    return result;
  }

  Future<List<Chordsheet>> getChordsheets() async {
    List<Map<String, dynamic>> data = await db.query("items");

    List<String> cs = [];
    for (Map<String, dynamic> item in data) {
      Map<String, dynamic> itemData = json.decode(item["data"]);
      _cacheMap.putIfAbsent(item["uuid"], () => itemData);

      if (itemData["datatype"] == "Chordsheet") {
        cs.add(item["uuid"]);
      }
    }
    List<Chordsheet> results = [
      for (String uuid in cs) (await getModel(uuid)) as Chordsheet
    ];

    return results;
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
