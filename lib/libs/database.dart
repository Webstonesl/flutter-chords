import 'dart:io';
import 'dart:typed_data';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';

enum DBSource { DBLocal, DBServer, DBNone }

class DB {
  String server_url = "http://127.0.0.1:8000";
  static DB? db;

  final Database database;
  DB(this.database);
  get() async {}
  static Future<DB> getDB() async {
    if (DB.db != null) {
      if (!DB.db!.database.isOpen) {
        return DB.db!;
      }
    }
    bool ex = await databaseFactory.databaseExists('songs.db');
    Database db = await databaseFactory.openDatabase('songs.db');
    if (!ex) {
      await db.rawQuery(r'''CREATE TABLE "tblfiles" (
          "fileid"	TEXT,
          "filename"	TEXT NOT NULL,
          "data"	BLOB NOT NULL,
          "filetype" TEXT NOT NULL,
          "update_date"	TEXT,
          "grabbed" INTEGER,
          PRIMARY KEY("fileid"),
          "saved" 
        );''');
      await db.rawQuery(r'''CREATE TABLE "tblsongs" (
        "songid"	TEXT,
        "title"	TEXT NOT NULL,
        "attrs"	TEXT,
        "fileid"	TEXT NOT NULL,
        "grabbed" INTEGER,
        PRIMARY KEY("songid"),
        FOREIGN KEY("fileid") REFERENCES "tblfiles"("fileid") ON UPDATE CASCADE
      );''');
      await db.rawQuery(r'''CREATE TABLE "tblparts" (
        "songid"	TEXT,
        "partid"	INTEGER,
        "title"	TEXT,
        "ptype"	TEXT,
        "lyrics"	TEXT,
        "content"	TEXT NOT NULL,
        "grabbed" INTEGER,
        PRIMARY KEY("songid","partid"),
        FOREIGN KEY("songid") REFERENCES "tblsongs"("songid")
      );''');
    }
    HttpClient client = HttpClient();
    DB w = DB(db);
    await w.get();
    return w;
  }
}
