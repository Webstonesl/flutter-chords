import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:song_viewer/gui/pages/viewers/chordsheetviewer.dart';
import 'package:song_viewer/libs/database.dart';
import 'package:song_viewer/libs/songstructure/chordsheets/chordsheet.dart';

class ChordsheetListView extends StatefulWidget {
  const ChordsheetListView({super.key});

  @override
  State<StatefulWidget> createState() {
    return _ChordsheetListViewState();
  }
}

class _ChordsheetListViewState extends State<ChordsheetListView> {
  MyDatabase? _database;
  late Future<MyDatabase> database;
  late Future<List<Chordsheet>> chordsheets;
  // List<Chordsheet> chordsheets = <Chordsheet>[];
  @override
  void initState() {
    database = MyDatabase.getDatabase(path: "");
    database.then(
      (value) {
        setState(() {
          chordsheets = value.getChordsheets();
        });
      },
    );
    super.initState();
  }

  String? search;
  @override
  Widget build(BuildContext context) {
    if (_database == null) {
      MyDatabase.getDatabase(path: "").then((value) {
        setState(() {
          _database = value;
        });
      });
    }
    return Scaffold(
        key: const ValueKey("CSList"),
        appBar: AppBar(
          leading: const Row(children: []),
          title: search == null
              ? const Text("Chordsheets")
              : TextField(
                  decoration: const InputDecoration(
                      icon: Icon(Icons.search), labelText: "Search"),
                  focusNode: primaryFocus,
                ),
          actions: [
            if (search == null)
              IconButton(
                  onPressed: () {
                    setState(() {
                      search = "";
                    });
                  },
                  icon: const Icon(Icons.search)),
            IconButton(
                onPressed: () async {
                  FilePicker.platform.pickFiles(
                      dialogTitle: 'Import Song',
                      type: FileType.custom,
                      withData: true,
                      allowedExtensions: ['tex']).then((value) {
                    if (value == null) {
                      return;
                    }
                    if (value.files[0].extension!.toLowerCase() == 'tex') {
                      List<Chordsheet> sheets = parseTexChordsheets(
                          const Utf8Decoder().convert(value.files[0].bytes!));
                      for (Chordsheet sheet in sheets) {
                        print(sheet.save(_database!));
                      }
                      // setState(() {
                      //   _database!.insert(sheets);
                      // });
                      if (sheets.length == 1) {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => ChordsheetViewer(
                                      chordsheet: sheets.first,
                                    )));
                      }
                    }
                  });
                },
                icon: const Icon(Icons.download))
          ],
        ),
        body: FutureBuilder(
          future: database,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const CircularProgressIndicator();
            }
            return FutureBuilder(
                future: chordsheets,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const CircularProgressIndicator();
                  }
                  return SingleChildScrollView(
                      child: Column(
                    children: [
                      for (Chordsheet cs in snapshot.data!)
                        ListTile(
                          title: Text(cs.title),
                          onTap: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        ChordsheetViewer(chordsheet: cs)));
                          },
                        )
                    ],
                  ));
                });
          },
        ));
  }
}
