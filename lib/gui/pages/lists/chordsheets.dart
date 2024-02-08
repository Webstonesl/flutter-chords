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
          title: const Text("Chordsheets"),
          actions: [
            if (search == null)
              IconButton(
                  onPressed: () {
                    setState(() {
                      chordsheets = _database!.getChordsheets();
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
                      Future.forEach(
                              sheets, (element) => element.save(_database!))
                          .then((value) {
                        setState(() {
                          chordsheets = _database!.getChordsheets();
                        });
                      });

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
            if (snapshot.hasError) {
              return Text(snapshot.error.toString());
            }
            if (!snapshot.hasData) {
              return const CircularProgressIndicator();
            }
            return FutureBuilder(
                future: chordsheets,
                builder: (context, snapshot) {
                  print(snapshot);
                  if (snapshot.hasError) {
                    return Text(snapshot.error.toString());
                  }
                  if (!snapshot.hasData) {
                    return const CircularProgressIndicator();
                  }
                  return Column(children: [
                    SearchBar(
                      leading: Icon(Icons.search),
                      onChanged: (value) async {},
                    ),
                    SingleChildScrollView(
                        child: Column(
                      children: [
                        for (Chordsheet cs in snapshot.data!)
                          ListTile(
                            title: Text(cs.title),
                            subtitle: Text([
                              if (cs.attributes["by"] != null)
                                cs.attributes["by"],
                              if (cs.initialState != null)
                                cs.initialState!.scale.toString(),
                              if (cs.attributes["bpm"] != null)
                                cs.attributes["bpm"]
                            ].join(" | ")),
                            trailing: IconButton(
                                onPressed: () {
                                  AlertDialog dialog = AlertDialog(
                                    icon: const Icon(Icons.delete),
                                    title: Text("Delete \"${cs.title}\"?"),
                                    content: Text(
                                        "Are you sure you want to delete \"${cs.title}\"?"),
                                    actions: [
                                      TextButton(
                                          onPressed: () {
                                            Navigator.pop(context);
                                          },
                                          child: const Text("Cancel")),
                                      ElevatedButton(
                                          onPressed: () {
                                            cs.delete(_database!).then(
                                              (value) {
                                                setState(() {
                                                  chordsheets = _database!
                                                      .getChordsheets();
                                                });
                                              },
                                            );

                                            Navigator.pop(context);
                                          },
                                          child: const Text("Delete"))
                                    ],
                                  );
                                  showDialog(
                                    context: context,
                                    builder: (context) => dialog,
                                  );
                                },
                                icon: const Icon(Icons.delete)),
                            onTap: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          ChordsheetViewer(chordsheet: cs)));
                            },
                          )
                      ],
                    ))
                  ]);
                });
          },
        ));
  }
}
