import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:song_viewer/gui/pages/viewers/chordsheetviewer.dart';
import 'package:song_viewer/gui/widgets/defaultdrawer.dart';
import 'package:song_viewer/libs/database.dart';
import 'package:song_viewer/libs/songstructure/chordsheets/chordsheet.dart';
import 'package:dart_levenshtein/dart_levenshtein.dart';

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
          chordsheets = value.getChordsheets().then((value) {
            value.sort(
              (a, b) => a.title.compareTo(b.title),
            );
            return value;
          });
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
        drawer: const DefaultDrawer(),
        appBar: AppBar(
          title: const Text("Chordsheets"),
          actions: [
            if (search == null)
              IconButton(
                  onPressed: () {
                    setState(() {
                      chordsheets = _database!.getChordsheets().then((value) {
                        value.sort((a, b) => a.title.compareTo(b.title));
                        return value;
                      });
                    });
                  },
                  icon: const Icon(Icons.search)),
            IconButton(
                onPressed: () async {
                  FilePicker.platform.pickFiles(
                      dialogTitle: 'Import Song',
                      type: FileType.custom,
                      withData: true,
                      allowMultiple: true,
                      allowedExtensions: ['tex']).then((value) {
                    if (value == null) {
                      return;
                    }
                    List<Chordsheet> sheets = [];

                    for (PlatformFile file in value.files) {
                      try {
                        if (value.files[0].extension!.toLowerCase() == 'tex') {
                          sheets.addAll(parseTexChordsheets(
                              const Utf8Decoder().convert(file.bytes!)));
                        }
                      } catch (e) {
                        print(e);
                        print(file.name);
                        return;
                      }
                    }

                    if (sheets.length == 1) {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => ChordsheetViewer(
                                  chordsheet: sheets.first,
                                  database: _database!))).then(
                        (value) {
                          setState(() {
                            chordsheets = _database!.getChordsheets();
                          });
                        },
                      );
                    } else {
                      for (Chordsheet cs in sheets) {
                        cs.save(_database!);
                      }
                      setState(() {
                        chordsheets = _database!.getChordsheets();
                      });
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
                  if (snapshot.hasError) {
                    return Text(snapshot.error.toString());
                  }
                  if (!snapshot.hasData) {
                    return const CircularProgressIndicator();
                  }
                  return SingleChildScrollView(
                      child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: SearchBar(
                            leading: const Icon(Icons.search),
                            onChanged: (val) async {
                              setState(() {
                                chordsheets = _database!
                                    .getChordsheets()
                                    .then((value) async {
                                  if (val.isNotEmpty) {
                                    value.sort((cs1, cs2) {
                                      if (cs1.title
                                          .toUpperCase()
                                          .contains(val.toUpperCase())) {
                                        return -2;
                                      }
                                      return cs1.title
                                          .toUpperCase()
                                          .compareTo(cs2.title);
                                    });
                                  } else {
                                    value.sort((cs1, cs2) =>
                                        cs1.title.compareTo(cs2.title));
                                  }
                                  return value;
                                });
                              });
                            },
                          )),
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
                                                chordsheets =
                                                    _database!.getChordsheets();
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
                                    builder: (context) => ChordsheetViewer(
                                          chordsheet: cs,
                                          database: _database!,
                                        ))).then((value) {});
                          },
                        )
                    ],
                  ));
                });
          },
        ));
  }
}
