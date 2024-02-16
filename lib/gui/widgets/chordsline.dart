import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:song_viewer/libs/songstructure/chordsheets/elements.dart' as el;
import 'package:song_viewer/libs/songstructure/musictheory.dart' as mtheory;

class ChordsheetLine extends StatefulWidget {
  final List<el.ItemElement> elements;

  mtheory.State _initialState;

  mtheory.State get initialState => _initialState;
  set initialState(mtheory.State state) {
    _initialState = state;
  }

  Function()? callback;
  ChordsheetLine(
      {super.key, required this.elements, required initialState, this.callback})
      : _initialState = initialState;

  @override
  State<StatefulWidget> createState() {
    return _ChordsheetLineState();
  }
}

class _ChordsheetLineState extends State<ChordsheetLine> {
  Image? _image;
  @override
  void initState() {
    super.initState();
    PictureRecorder picr = PictureRecorder();

    Canvas canvas = Canvas(picr);
    picr.endRecording().toImage(10, 10).then((value) {
      value.toByteData().then(
        (value) {
          setState(() {
            _image = Image.memory(Uint8List.view(value!.buffer));
          });
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    double height = _CSLinePainter.getHeight(widget.elements, context,
        state: widget.initialState, width: MediaQuery.of(context).size.width);
    return FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: SizedBox(
          width: 200,
          height: height,
          child: CustomPaint(
            painter: _CSLinePainter(context,
                elements: widget.elements, state: widget.initialState),
            size: Size.infinite,
          ),
        ));
  }
}

class _CSLinePainter extends CustomPainter {
  final mtheory.State state;
  final List<el.ItemElement> elements;
  final BuildContext context;
  static const TextStyle _lyrics =
      TextStyle(fontFamily: "mono", fontSize: 16, fontWeight: FontWeight.w500);
  static const TextStyle _chords = TextStyle(
      fontFamily: "Times New Roman", fontSize: 16, fontWeight: FontWeight.w500);
  TextStyle get lyrics => Theme.of(context)
      .textTheme
      .bodyLarge!
      .merge(_lyrics)
      .merge(TextStyle(color: foreground));
  TextStyle get chords => Theme.of(context)
      .textTheme
      .bodyLarge!
      .merge(_chords)
      .merge(TextStyle(color: foreground));
  Color get foreground => Theme.of(context).colorScheme.onBackground;
  _CSLinePainter(this.context, {required this.state, required this.elements});

  @override
  void paint(Canvas canvas, Size size) {
    double xLyrics = 0;
    double xChords = 0;
    double yLyrics = 24;
    double yChords = yLyrics - 20;
    int c = 0;
    for (int i = 0; i < elements.length; i++) {
      el.ItemElement element = elements[i];

      if (element is el.ItemLineBreak) {
        c += 1;
      } else {
        c = 0;
      }
      if (element is el.ItemLyric) {
        TextPainter painter = TextPainter(
            textDirection: TextDirection.ltr,
            text: TextSpan(text: element.lyrics, style: lyrics),
            textAlign: TextAlign.left);
        painter.layout();

        // if (xLyrics + 20 < xChords) {
        //   xLyrics = xChords - 20;
        // }
        painter.paint(canvas, Offset(xLyrics, yLyrics));

        xLyrics += painter.width;
      } else if (element is el.ItemChord) {
        TextPainter painter = TextPainter(
            textDirection: TextDirection.ltr,
            text: TextSpan(text: element.render(state), style: chords),
            textAlign: TextAlign.left);
        painter.layout();

        if (xChords < xLyrics) {
          xChords = xLyrics;
        }

        painter.paint(canvas, Offset(xChords, yChords));
        xChords += painter.width + 10;
      } else if (element is el.ItemMeasure) {
        xChords = max(xLyrics, xChords);
        xLyrics = xChords;
        Paint p = Paint();
        p.color = foreground;
        p.strokeWidth = 1;

        p.style = PaintingStyle.stroke;

        canvas.drawLine(
            Offset(xLyrics, yChords), Offset(xLyrics, yLyrics + 24), p);
        xLyrics = max(xLyrics, xChords);
        xChords = xLyrics;
      } else if (element is el.ItemRepeat) {
        if (element.type != mtheory.RepeatType.number) {
          xChords = max(xLyrics, xChords);
          xLyrics = xChords;
          Paint thick = Paint();
          thick.color = foreground;
          thick.strokeWidth = 3;
          Paint thin = Paint();

          thin.color = foreground;
          Paint dot = Paint();
          dot.color = foreground;

          late List<int> mtype;
          if (element.type == mtheory.RepeatType.start) {
            mtype = [1, 2, 3];
          } else {
            mtype = [3, 2, 1];
          }
          for (int n in mtype) {
            switch (n) {
              case 1:
                canvas.drawLine(Offset(xLyrics, yChords),
                    Offset(xLyrics, yLyrics + 24), thick);
                xLyrics += 4;
                break;
              case 2:
                canvas.drawLine(Offset(xLyrics, yChords),
                    Offset(xLyrics, yLyrics + 24), thin);
                xLyrics += 3;
                break;
              case 3:
                xLyrics += 5;
                canvas.drawOval(
                    Rect.fromCenter(
                        center:
                            Offset(xLyrics, (yLyrics + 24 + yChords) / 2 - 10),
                        width: 4,
                        height: 4),
                    dot);
                canvas.drawOval(
                    Rect.fromCenter(
                        center:
                            Offset(xLyrics, (yLyrics + 24 + yChords) / 2 + 10),
                        width: 4,
                        height: 4),
                    dot);
                xLyrics += 7;
                break;
            }
          }

          xLyrics += 5;
        } else {
          xChords = max(xLyrics, xChords);
          xLyrics = xChords;
          TextPainter painter = TextPainter(
            text: TextSpan(
                text: "(x${(element.n ?? 2)})",
                style: Theme.of(context).textTheme.headlineSmall),
            textDirection: TextDirection.ltr,
          );
          painter.layout();
          painter.paint(canvas, Offset(xLyrics, (yChords + yLyrics) / 2));
          xLyrics += painter.width;
          xChords = xLyrics;
        }
      } else if (element is el.ItemLineBreak) {
        if ((c == 1) && (i != 0) && (elements.length - 1 > i)) {
          yLyrics += 48;
          yChords += 48;
        } else {
          yLyrics += 5;
          yChords += 5;
        }
        xChords = 0;
        xLyrics = 0;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CSLinePainter oldDelegate) {
    if (state != oldDelegate.state) {
      return true;
    }
    return false;
  }

  static double getHeight(List<el.ItemElement> elements, BuildContext context,
      {required mtheory.State state, double width = 200}) {
    double xLyrics = 0;
    double xChords = 0;
    double yLyrics = 24;
    double yChords = yLyrics - 24;
    int c = 0;
    for (int i = 0; i < elements.length; i++) {
      el.ItemElement element = elements[i];

      if (element is el.ItemLineBreak) {
        c += 1;
      } else {
        c = 0;
      }
      if (element is el.ItemLyric) {
        TextPainter painter = TextPainter(
            textDirection: TextDirection.ltr,
            text: TextSpan(text: element.lyrics, style: _lyrics),
            textAlign: TextAlign.left);
        painter.layout();

        xLyrics += painter.width;
      } else if (element is el.ItemChord) {
        TextPainter painter = TextPainter(
            textDirection: TextDirection.ltr,
            text: TextSpan(text: element.render(state), style: _chords),
            textAlign: TextAlign.left);
        painter.layout();

        if (xChords < xLyrics) {
          xChords = xLyrics;
        }

        xChords += painter.width + 10;
      } else if (element is el.ItemMeasure) {
        xChords = max(xLyrics, xChords);
        xLyrics = xChords;
        Paint p = Paint();
        p.color = Colors.white;
        p.strokeWidth = 1;

        p.style = PaintingStyle.stroke;

        xLyrics = max(xLyrics, xChords);
        xChords = xLyrics + 5;
      } else if (element is el.ItemRepeat) {
        if (element.type != mtheory.RepeatType.number) {
          xChords = max(xLyrics, xChords);
          xLyrics = xChords;
          Paint thick = Paint();
          thick.color = Colors.white;
          thick.strokeWidth = 3;
          Paint thin = Paint();

          thin.color = Colors.white;
          Paint dot = Paint();
          dot.color = Colors.white;

          late List<int> mtype;
          if (element.type == mtheory.RepeatType.start) {
            mtype = [1, 2, 3];
          } else {
            mtype = [3, 2, 1];
          }
          for (int n in mtype) {
            switch (n) {
              case 1:
                xLyrics += 4;
                break;
              case 2:
                xLyrics += 3;
                break;
              case 3:
                xLyrics += 5;

                xLyrics += 7;
                break;
            }
          }

          xLyrics += 5;
        } else {
          xChords = max(xLyrics, xChords);
          xLyrics = xChords;
          TextPainter painter = TextPainter(
            text: TextSpan(
                text: "(x${(element.n ?? 2)})",
                style: Theme.of(context).textTheme.headlineSmall),
            textDirection: TextDirection.ltr,
          );
          painter.layout();

          xLyrics += painter.width;
          xChords = xLyrics;
        }
      } else if (element is el.ItemLineBreak) {
        if ((c == 1) && (i != 0) && (elements.length - 1 > i)) {
          yLyrics += 48;
          yChords += 48;
        } else {
          yLyrics += 5;
          yChords += 5;
        }
        xChords = 0;
        xLyrics = 0;
      }
    }
    return yLyrics + 24;
  }
}
