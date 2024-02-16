import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:song_viewer/gui/widgets/chordsline.dart';
import 'package:song_viewer/gui/widgets/stateeditor.dart';
import 'package:song_viewer/libs/database.dart';
import 'package:song_viewer/libs/songstructure/chordsheets/chordsheet.dart';
import 'package:song_viewer/libs/songstructure/chordsheets/elements.dart';
import 'package:song_viewer/libs/songstructure/musictheory.dart' as mtheory;

class ChordsheetViewer extends StatefulWidget {
  final Chordsheet chordsheet;
  final MyDatabase database;
  const ChordsheetViewer(
      {super.key, required this.chordsheet, required this.database});
  @override
  State<StatefulWidget> createState() {
    return _ChordsheetViewerState();
  }
}

class _ChordsheetViewerState extends State<ChordsheetViewer> {
  int n = 0;
  bool showShare = false;
  @override
  Widget build(BuildContext context) {
    widget.chordsheet.reset();
    n = 0;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            if (widget.chordsheet.needsUpdate) {
              showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                        title: Text("Unsaved Element"),
                        content: Text("Do you want to save this chordsheet?"),
                        actions: [
                          TextButton(
                              onPressed: () {
                                Navigator.of(context).pop(null);
                              },
                              child: const Text("Cancel")),
                          TextButton(
                              onPressed: () {
                                Navigator.of(context).pop(false);
                              },
                              child: const Text("Don't Save")),
                          ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).pop(true);
                              },
                              child: const Text("Save")),
                        ],
                      )).then(
                (value) {
                  if (value == null) {
                    return;
                  }
                  if (value == false) {
                    Navigator.of(context).pop();
                    return;
                  }
                  if (value == true) {
                    widget.chordsheet.save(widget.database).then((value) {
                      Navigator.pop(context);
                    }, onError: (error) {
                      print(error);
                      return;
                    });
                  }
                },
              );
              return;
            }
            Navigator.pop(context);
          },
        ),
        title: Text([
          widget.chordsheet.title,
          if (widget.chordsheet.needsUpdate) '*'
        ].join(' ')),
        actions: [
          IconButton(
              onPressed: () {
                showDialog(
                        builder: (context) => Dialog(
                            child: StateEditorWidget(
                                state: widget.chordsheet.initialState!)),
                        context: context)
                    .then((value) {
                  if (value is mtheory.State) {
                    setState(() {
                      widget.chordsheet.initialState = value;
                    });
                  }
                });
                // Dialog(child:StateEditorWidget(state: widget.chordsheet.initialState!));
              },
              icon: const Icon(Icons.music_note)),
          IconButton(
              onPressed: () {
                showModalBottomSheet(
                    context: context,
                    builder: (context) =>
                        Column(mainAxisSize: MainAxisSize.min, children: [
                          ListTile(
                            title: Text("As PDF"),
                            onTap: () async {
                              Uint8List document =
                                  await widget.chordsheet.toPDF();
                              if (Platform.isLinux ||
                                  Platform.isMacOS ||
                                  Platform.isWindows) {
                                FilePicker.platform
                                    .saveFile(
                                  fileName: "Chordsheet.pdf",
                                )
                                    .then((filepath) {
                                  if (filepath == null) {
                                    return;
                                  }
                                  {
                                    File(filepath).writeAsBytes(document);

                                    ;
                                  }
                                });
                              }

                              Navigator.pop(context);
                            },
                          ),
                          ListTile(
                            title: Text("As My File Type"),
                            onTap: () {
                              Navigator.pop(context);
                            },
                          )
                        ]));
              },
              icon: Icon(Icons.share))
        ],
      ),
      body: SingleChildScrollView(
          child: Column(
        children: [
          for (ChordsheetElement element in widget.chordsheet.elements)
            buildElement(context, element)
        ],
      )),
    );
  }

  Widget buildChordSheetsPart(BuildContext context, ChordsheetPart part) {
    List<Widget> rows = [];

    List<List<ItemElement>> lines = [[]];
    for (ItemElement element in part.elements) {
      if (element is ItemLineBreak) {
        lines.last.add(element);
        lines.add([]);
      } else {
        lines.last.add(element);
      }
    }
    lines.last.add(ItemLineBreak());
    for (List<ItemElement> line in lines) {
      rows.add(ChordsheetLine(
          elements: line, initialState: widget.chordsheet.state!));
    }
    return Row(children: [
      Expanded(
          child: Container(
              padding: const EdgeInsets.only(top: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: rows,
              )))
    ]);
  }

  Widget buildElement(BuildContext context, ChordsheetElement element) {
    mtheory.State? state = widget.chordsheet.state;
    widget.chordsheet.state = element.applyTo(state!);
    n++;
    if (element is ChordsheetTranspose) {
      return Container(
          child: ListTile(
        leading: Text("$n."),
        title: Text(
            "Transpose ${element.transpose.n}: ${state.scale.toString()} -> ${widget.chordsheet.state!.scale}"),
        trailing: IconButton(
          icon: const Icon(Icons.delete),
          onPressed: () async {
            setState(() {
              widget.chordsheet.elements.remove(element);
            });
            widget.chordsheet.save(await MyDatabase.getDatabase(path: ""));
          },
        ),
        onTap: () {},
      ));
    }
    if (element is ChordsheetRepeat) {
      if (element.part == null) {
        for (ChordsheetElement el in widget.chordsheet.elements) {
          if (el is ChordsheetPart) {
            if (el.title == element.s) {
              element.part = el;
            }
          }
          if (el == element) {
            break;
          }
        }
      }
      if (element.part != null) {
        return Container(
          child: ListTile(
            title: Text(element.part!.title ?? "Unlabeled Part"),
            subtitle: ChordsheetLine(
              elements: element.part!.elements,
              initialState: state,
            ),
            titleTextStyle: Theme.of(context).textTheme.headlineSmall,
            subtitleTextStyle: Theme.of(context)
                .textTheme
                .bodyLarge!
                .merge(const TextStyle(fontWeight: FontWeight.bold)),
          ),
        );
      }
      return Container(
        child:
            ListTile(leading: Text("$n."), title: Text("Repeat: ${element.s}")),
      );
    }
    if (element is ChordsheetPart) {
      Widget c = Container(
        child: ListTile(
          title: Text(element.title ?? "Unlabeled Part"),
          subtitle: ChordsheetLine(
            elements: element.elements,
            initialState: state,
          ),
          titleTextStyle: Theme.of(context).textTheme.headlineSmall,
          subtitleTextStyle: Theme.of(context)
              .textTheme
              .bodyLarge!
              .merge(const TextStyle(fontWeight: FontWeight.bold)),
        ),
      );
      return c;
      // widget.chordsheet.currentState =
    }
    return ListTile(
        leading: Text("$n."), title: Text(element.runtimeType.toString()));
  }
}
