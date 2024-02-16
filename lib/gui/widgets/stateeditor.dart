import 'package:flutter/material.dart';
import 'package:song_viewer/libs/songstructure/musictheory.dart' as theory;

class StateEditorWidget extends StatefulWidget {
  final theory.State state;

  const StateEditorWidget({super.key, required this.state});
  @override
  State<StatefulWidget> createState() {
    return _StateEditorState();
  }
}

class _StateEditorState extends State<StateEditorWidget> {
  theory.State? _state;
  int? bpm;
  int? upper;
  int? lower;
  @override
  Widget build(BuildContext context) {
    _state ??= widget.state;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          "Info Editor",
          style: Theme.of(context).textTheme.titleLarge,
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const Text("Transpose:"),
            IconButton(
                onPressed: () {
                  setState(() {
                    _state = _state! + const theory.Transpose(-1);
                  });
                },
                icon: const Icon(Icons.remove)),
            Text(
              _state!.scale.toString(),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            IconButton(
                onPressed: () {
                  setState(() {
                    _state = _state! + const theory.Transpose(1);
                  });
                },
                icon: const Icon(Icons.add))
          ],
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Rhythm:"),
            Column(
              children: [
                Container(
                    margin: const EdgeInsets.all(10),
                    width: 20,
                    height: 50,
                    child: Column(
                      children: [
                        Expanded(
                            child: TextFormField(
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          initialValue: (_state!.rhythm.upper ?? 4).toString(),
                          onChanged: (value) {
                            int? n = int.tryParse(value);
                            upper = n;
                          },
                        )),
                        Expanded(
                            child: TextFormField(
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          initialValue: (_state!.rhythm.lower ?? 4).toString(),
                          onChanged: (value) {
                            int? n = int.tryParse(value);
                            lower = n;
                          },
                        ))
                      ],
                    ))
              ],
            ),
            SizedBox(
              width: 100,
              height: 50,
              child: TextFormField(
                keyboardType: TextInputType.number,
                initialValue: (_state!.rhythm.bpm ?? 0).toString(),
                onChanged: (value) {
                  int? n = int.tryParse(value);
                  bpm = n;
                },
              ),
            )
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Set Starting Scale(Incase it is wrong):"),
            DropdownMenu(
              initialSelection: _state!.scale,
              dropdownMenuEntries: [
                for (int i = 0; i < 12; i++)
                  DropdownMenuEntry(
                      value: theory.Scale(
                          key: theory.Key(i), type: theory.ScaleType.major),
                      label: theory.Scale(
                              key: theory.Key(i), type: theory.ScaleType.major)
                          .toString())
              ],
              onSelected: (value) {
                if (value == null) {
                  return;
                }
                setState(() {
                  _state = _state! + value!;
                });
              },
            )
          ],
        ),
        ElevatedButton(
            onPressed: () {
              _state =
                  _state! + theory.Rhythm(bpm: bpm, upper: upper, lower: lower);
              Navigator.pop(context, _state!);
            },
            child: const Text("OK"))
      ],
    );
  }
}
