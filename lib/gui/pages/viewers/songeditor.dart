import 'dart:convert';
import 'dart:math';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:song_viewer/libs/datatypes.dart' as types;

class PartEditorWidget extends StatefulWidget {
  types.Part part;
  int nr;
  void Function(void Function()) action;
  PartEditorWidget(
      {required this.part, required this.nr, super.key, required this.action});
  @override
  State<StatefulWidget> createState() {
    return PartEditorState();
  }
}

class PartEditorState extends State<PartEditorWidget> {
  bool closed = true;

  static Map<Brightness, List<Color>> colors = {
    Brightness.dark: [
      const Color(0xff092635),
      const Color(0xFF1B4242),
      const Color(0xFF5C8374),
    ],
    Brightness.light: []
  };

  @override
  Widget build(BuildContext context) {
    print(Theme.of(context).brightness);

    int n = widget.nr % colors[Theme.of(context).brightness]!.length;

    return Container(
        margin: EdgeInsets.all(8),
        decoration: BoxDecoration(
            color: colors[Theme.of(context).brightness]![n],
            borderRadius: BorderRadius.circular(8)),
        child: closed
            ? ListTile(
                leading: Icon(Icons.arrow_right_alt),
                title: Text(widget.part.title ?? "<Unnamed Part>"),
                onTap: () {
                  setState(() {
                    closed = false;
                  });
                },
              )
            : ListTile(
                title: Row(children: [
                  IconButton(
                    icon: Icon(Icons.arrow_drop_up),
                    onPressed: () {
                      setState(() {
                        closed = true;
                      });
                    },
                  ),
                  Expanded(
                      child: TextFormField(
                          decoration: InputDecoration(labelText: "Title"),
                          initialValue: widget.part.title ?? "")),
                  IconButton(
                      onPressed: () {
                        widget.action(() {
                          widget.part.song!.parts.remove(widget.part);
                          widget.part.song = null;
                        });
                      },
                      icon: Icon(Icons.delete))
                ]),
                subtitle: Container(
                  padding: EdgeInsets.symmetric(horizontal: 40),
                  child: TextFormField(
                    decoration: InputDecoration(labelText: "Lyrics"),
                    initialValue: widget.part.lyrics ?? "",
                    maxLines: null,
                    minLines: 2,
                  ),
                )));
  }
}

class SongEditorPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _SongEditorPageState();
  }
}

class _SongEditorPageState extends State<SongEditorPage> {
  types.Song song = types.Song();
  @override
  Widget build(BuildContext context) {
    LocalKey key = ObjectKey(song);
    return Scaffold(
        appBar: AppBar(
          title: Text('Song Viewer'),
          actions: [
            IconButton(
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
                          Utf8Decoder().convert(value.files[0].bytes!));
                      setState(() {
                        this.song = songs[0];
                      });
                    }
                    print(value.files[0].extension);
                  });
                },
                icon: Icon(Icons.download))
          ],
        ),
        body: SingleChildScrollView(
          child: Form(
              key: ObjectKey(song),
              child: Column(children: [
                Card(
                    child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: TextFormField(
                    decoration: InputDecoration(labelText: 'Title'),
                    key: key,
                    initialValue: song.name ?? "",
                    onChanged: (value) {
                      song.name = value;
                    },
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
                            style: Theme.of(context)
                                .primaryTextTheme
                                .headlineMedium,
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
                                      setState() {
                                        song.authors.add(value);
                                      }
                                    }
                                  },
                                ),
                                trailing: IconButton(
                                  icon: Icon(Icons.remove),
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
                                    InputDecoration(labelText: 'Add Author'),
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
                Card(
                  child: Column(children: [
                    for (int i = 0; i < song.parts.length; i++)
                      PartEditorWidget(
                          key: ObjectKey(song.parts[i]),
                          part: song.parts[i],
                          nr: i,
                          action: setState)
                  ]),
                )
              ])),
        ));
  }
}
