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
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
            color:
                widget.part.color ?? colors[Theme.of(context).brightness]![n],
            borderRadius: BorderRadius.circular(8)),
        child: ListTile(
            trailing: !closed
                ? IconButton(
                    onPressed: () {
                      widget.action(() {
                        widget.part.song!.parts.remove(widget.part);
                        widget.part.song = null;
                      });
                    },
                    icon: const Icon(Icons.delete))
                : null,
            title: Row(children: [
              IconButton(
                icon: Icon(closed
                    ? Icons.keyboard_arrow_right
                    : Icons.keyboard_arrow_down),
                onPressed: () {
                  widget.action(() {
                    setState(() {
                      closed = !closed;
                    });
                  });
                },
              ),
              closed
                  ? Text(widget.part.title ??
                      (widget.part.lyrics == null
                          ? null
                          : widget.part.lyrics!.split('\n')[0]) ??
                      "<Unnamed Part>")
                  : Expanded(
                      child: TextFormField(
                          decoration: const InputDecoration(labelText: "Title"),
                          initialValue: widget.part.title ?? "",
                          onChanged: (value) {
                            widget.part.title = value;
                          })),
            ]),
            subtitle: !closed
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: TextFormField(
                      decoration: const InputDecoration(labelText: "Lyrics"),
                      initialValue: widget.part.lyrics ?? "",
                      maxLines: null,
                      minLines: 2,
                      onChanged: (value) {
                        widget.part.lyrics = value;
                      },
                    ),
                  )
                : const Text("")));
  }
}
