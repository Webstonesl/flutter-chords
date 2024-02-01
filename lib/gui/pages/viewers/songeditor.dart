import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:song_viewer/gui/widgets/csparteditor.dart';
import 'package:song_viewer/gui/widgets/parteditor.dart';
import 'package:song_viewer/libs/datatypes.dart' as types;

class SongEditorPage extends StatefulWidget {
  const SongEditorPage({super.key});

  @override
  State<StatefulWidget> createState() {
    return _SongEditorPageState();
  }
}

class _SongEditorPageState extends State<SongEditorPage> {
  types.Song song = types.Song();
  bool showChords = false;
  @override
  Widget build(BuildContext context) {
    LocalKey key = ObjectKey(song);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Song Viewer'),
        actions: [
          IconButton(
            tooltip: showChords ? 'Lyrics' : 'Chordsheets',
            icon: Icon(showChords ? Icons.list : Icons.music_note),
            onPressed: () {
              setState(() {
                showChords = !showChords;
              });
            },
          ),
          IconButton(
              tooltip: "Import Song",
              onPressed: () async {
                FilePicker.platform.pickFiles(
                    dialogTitle: 'Import Song',
                    type: FileType.custom,
                    withData: true,
                    allowedExtensions: ['txt', 'tex']).then((value) {
                  if (value == null) {
                    return;
                  }
                  if (value.files[0].extension!.toLowerCase() == 'tex') {
                    List<types.Song> songs = types.Song.PARSE_TEX(
                        const Utf8Decoder().convert(value.files[0].bytes!));
                    setState(() {
                      song = songs[0];
                    });
                  }
                });
              },
              icon: const Icon(Icons.download))
        ],
      ),
      body: OrientationBuilder(builder: (context, orientation) {
        if (orientation == Orientation.portrait) {
          return Column(mainAxisSize: MainAxisSize.min, children: [
            buildInfoForm(context),
            if (!showChords) buildLyrics(context),
            if (showChords) buildChordSheets(context),
          ]);
        } else {
          return Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            SizedBox(
                width: MediaQuery.of(context).size.width / 3,
                child: buildInfoForm(context)),
            if (!showChords) buildLyrics(context),
            if (showChords) buildChordSheets(context),
          ]);
        }
      }),

      //])
    );
  }

  Widget buildInfoForm(BuildContext context) {
    return SingleChildScrollView(
      child: Form(
          key: ObjectKey(song),
          child: Column(children: [
            Card(
                child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: TextFormField(
                decoration: const InputDecoration(labelText: 'Title'),
                key: Key("Title"),
                initialValue: song.name ?? "",
                onChanged: (value) {
                  song.name = value;
                },
                style: Theme.of(context).textTheme.headlineLarge,
              ),
            )),
            Card(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        "Authors",
                        style:
                            Theme.of(context).primaryTextTheme.headlineMedium,
                      )),
                  SingleChildScrollView(
                    child: Column(
                      children: [
                        for (int i = 0; i < song.authors.length; i++)
                          ListTile(
                            title: TextFormField(
                              key: ValueKey("author_$i"),
                              decoration: InputDecoration(
                                  labelText: i < song.authors.length
                                      ? 'Author ${i + 1}'
                                      : 'Add Author'),
                              initialValue: i < song.authors.length
                                  ? song.authors[i]
                                  : "",
                              onChanged: (value) {
                                if (i < song.authors.length) {
                                  song.authors[i] = value;
                                } else {
                                  setState(() {
                                    song.authors.add(value);
                                  });
                                }
                              },
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.remove),
                              onPressed: () {
                                setState(() {
                                  song.authors.removeAt(i);
                                });
                              },
                            ),
                          ),
                        Container(
                          padding: const EdgeInsets.fromLTRB(8, 0, 8, 5),
                          margin: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              boxShadow: [
                                BoxShadow(
                                    blurRadius: 5,
                                    offset: Offset.fromDirection(5.4977))
                              ],
                              borderRadius: BorderRadius.circular(8)),
                          child: TextFormField(
                            key: ValueKey("author_${song.authors.length}"),
                            initialValue: '',
                            decoration:
                                const InputDecoration(labelText: 'Add Author'),
                            onChanged: (value) {
                              if (value.isNotEmpty) {
                                setState(() {
                                  song.authors.add(value);
                                });
                              }
                            },
                          ),
                        )
                      ],
                    ),
                  )
                ])),
          ])),
    );
  }

  List<types.Chordsheet> get chordsheets => song.chordsheets;
  types.Chordsheet? chordsheet;
  Widget buildChordSheets(BuildContext context) {
    int i = 1;
    if (chordsheet == null) {
      return Expanded(
          child: Column(children: [
        Expanded(
            child: ListView.builder(
          itemCount: song.chordsheets.length,
          itemBuilder: (context, index) => ListTile(
            title: Text("Chordsheet ${index + 1}"),
            onTap: () {
              setState(() {
                chordsheet = chordsheets[index];
              });
            },
          ),
        )),
      ]));
    }
    return Expanded(
        child: Column(
      children: [
        ListTile(
            leading: IconButton(
                onPressed: () {
                  setState(() {
                    chordsheet = null;
                  });
                },
                icon: const Icon(Icons.arrow_back)),
            title: const Text("Chordsheet")),
        Expanded(
          child: ListView.builder(
              itemCount: chordsheet!.parts.length,
              itemBuilder: (context, index) =>
                  ChordsheetPartEditorWidget(part: chordsheet!.parts[index])),
        ),
        ListTile(
          leading: const Icon(Icons.add),
          title: const Text("Add Part"),
          onTap: () {
            setState(() {
              chordsheet!.parts
                  .add(types.ChordsheetPart(chordsheet: chordsheet!));
            });
          },
        )
      ],
    ));
  }

  Widget buildLyrics(BuildContext context) {
    return Expanded(
        child: Column(children: [
      Expanded(
        child: ReorderableListView.builder(
            onReorder: (oldIndex, newIndex) {
              if (newIndex > oldIndex) {
                newIndex -= 1;
              }
              setState(() {
                song.parts.insert(newIndex, song.parts.removeAt(oldIndex));
              });
            },
            primary: true,
            itemCount: song.parts.length,
            itemBuilder: (context, i) => PartEditorWidget(
                key: ObjectKey(song.parts[i]),
                part: song.parts[i],
                nr: i,
                action: setState)),
      ),
      ListTile(
        leading: const Icon(Icons.add),
        title: const Text("Add Part"),
        onTap: () {
          setState(() {
            song.parts.add(types.Part(song: song));
          });
        },
      )
    ]));
  }
}
