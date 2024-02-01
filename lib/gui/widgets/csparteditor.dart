import 'package:flutter/material.dart';
import 'package:song_viewer/libs/datatypes.dart';

class ChordsheetPartEditorWidget extends StatefulWidget {
  final ChordsheetPart part;

  const ChordsheetPartEditorWidget({super.key, required this.part});
  @override
  State<StatefulWidget> createState() {
    return ChordsheetPartEditorState();
  }
}

class ChordsheetPartEditorState extends State<ChordsheetPartEditorWidget> {
  ChordsheetPart get part => widget.part;
  TextEditingController controller = TextEditingController();
  @override
  Widget build(BuildContext context) {
    print(Theme.of(context).textTheme.bodyLarge!.height);
    return Container(
        padding: const EdgeInsets.all(8),
        child: Form(
            key: ObjectKey(part),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownMenu<Part>(
                  dropdownMenuEntries: [
                    for (Song s in part.chordsheet!.songs)
                      for (Part p in s.parts)
                        DropdownMenuEntry(value: p, label: p.title ?? "Part")
                  ],
                  onSelected: (value) {
                    setState(() {
                      part.part = value!;
                      part.content = value.lyrics;
                      controller.text = part.content!;
                    });
                  },
                ),
                TextFormField(
                  controller: controller,
                  key: Key("content"),
                  onChanged: (value) {
                    part.content = value;
                  },
                  maxLines: null,
                  decoration: InputDecoration(
                      border: OutlineInputBorder(
                          borderSide: BorderSide.none,
                          borderRadius: BorderRadius.circular(8))),
                )
              ],
            )));
  }
}
