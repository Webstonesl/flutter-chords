import 'dart:typed_data';

import 'package:flutter/material.dart' as mat;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:song_viewer/libs/database.dart';
import 'package:song_viewer/libs/songstructure/chordsheets/elements.dart';

import '../musictheory.dart';
import '../texutils.dart';

class Chordsheet extends Model {
  String title;
  Map<String, dynamic> attributes;
  State? _initialState;
  State? get initialState => _initialState ?? getState();
  set initialState(State? state) {
    _initialState = state;
  }

  State? get state => currentState ?? initialState;
  set state(State? state) {
    currentState = state;
  }

  State? currentState;
  void reset() {
    currentState = initialState;
  }

  List<ChordsheetElement> elements = [];
  Chordsheet({
    this.title = "",
    required this.attributes,
    State? initialState,
  }) : _initialState = initialState;

  State? getState() {
    Rhythm rhythm = Rhythm(bpm: null, upper: null, lower: null);

    Set<Key> keys = {};

    for (ChordsheetElement el in elements) {
      if (el is ChordsheetPart) {
        for (ItemElement item in el.elements) {
          if (item is ItemChord) {
            if (item.chord != null) {
              keys.addAll(item.chord!.keys);

              for (int i = 0; i < 12; i++) {
                Set<int> nrs = {};
                for (Key key in keys) {
                  nrs.add((key.value - i + 12) % 12);
                }

                nrs.retainWhere(
                    (element) => {0, 2, 4, 5, 7, 9, 11}.contains(element));

                if (nrs.length > 4) {
                  return State(
                      repeats: <RepeatState>[],
                      scale: Scale(key: Key(i), type: ScaleType.major),
                      rhythm: rhythm);
                }
              }
            }
          }
        }
      }
    }
    return null;
  }

  @override
  Map<String, dynamic> getData() {
    Map<String, dynamic> map = {};
    map["title"] = title;
    map["start"] = initialState!.data;
    map["attrs"] = attributes;
    map["elements"] = elements;
    return map;
  }

  static pw.TextStyle partTitleFont = pw.TextStyle(
      fontWeight: pw.FontWeight.bold,
      fontSize: 16,
      fontBold: pw.Font.timesBold());
  static pw.TextStyle chordsheetTitleFont = const pw.TextStyle();
  static pw.TextStyle lyricFont = const pw.TextStyle();
  pw.Widget _part(State state, ChordsheetPart element) {
    List<pw.Wrap> rows = [];
    List<List<ItemElement>> lines = [[]];
    for (ItemElement item in element.elements) {
      lines.last.add(item);
      if (item is ItemLineBreak) {
        lines.add([]);
      }
    }

    for (List<ItemElement> line in lines) {
      List<pw.Widget> wrap = [];
      List<pw.Widget> column = [];

      for (int i = 0; i < line.length; i++) {
        void moveOver() {
          if (column.isEmpty) {
            return;
          }
          wrap.add(pw.Column(
              children: column,
              mainAxisAlignment: pw.MainAxisAlignment.end,
              crossAxisAlignment: pw.CrossAxisAlignment.start));

          column = [];
        }

        ItemElement el = line[i];
        if (el is ItemLineBreak) {
          moveOver();
        } else if (el is ItemLyric) {
          if (i > 0) {
            if (line[i - 1] is ItemLyric) {
              moveOver();
            }
          }

          column.add(pw.Text(el.lyrics, style: lyricFont));
        } else {
          moveOver();
          if (el is ItemChord) {
            column.add(pw.Text(el.render(state)));
          }
        }
      }

      rows.add(pw.Wrap(
          children: wrap, crossAxisAlignment: pw.WrapCrossAlignment.end));
    }
    return pw.Column(
        mainAxisAlignment: pw.MainAxisAlignment.start,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(element.title ?? "", style: partTitleFont),
          for (pw.Wrap wrap in rows) wrap
        ]);
  }

  pw.Widget _element(State state, ChordsheetElement element) {
    if (element is ChordsheetPart) {
      return _part(state, element);
    } else if (element is ChordsheetRepeat) {
      return pw.Text("Repeat ${element.title}", style: partTitleFont);
    }
    return pw.Text(element.runtimeType.toString(),
        style: pw.TextStyle(
            fontItalic: pw.Font.timesItalic(), fontStyle: pw.FontStyle.italic));
  }

  Future<Uint8List> toPDF([State? initialState]) async {
    initialState ??= this.initialState;
    State state = initialState!;
    List<pw.Widget> widgets = [];
    for (ChordsheetElement element in elements) {
      widgets.add(_element(state, element));
      state = element.applyTo(state);
    }
    pw.Document document = pw.Document(title: title, creator: "Webstones");
    document.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      build: (context) {
        return [
          pw.Text(title,
              style: pw.TextStyle(
                font: pw.Font.timesBold(),
                fontSize: 18,
              )),
          for (pw.Widget widget in widgets) widget
        ];
      },
    ));

    return await document.save();
  }
}

class Scanner<T> {
  final Map<RegExp, List<T> Function(Match)> expressions;
  final List<T> list;
  Scanner(String input, this.expressions) : list = [] {
    for (int i = 0; i < input.length;) {
      int oi = i;
      for (RegExp exp in expressions.keys) {
        Match? match = exp.matchAsPrefix(input, i);

        if (match != null) {
          list.addAll(expressions[exp]!(match));
          i = match.end;
          break;
        }
      }
      if (oi == i) {
        throw UnsupportedError("Input: '${input.substring(i)}' not supported");
      }
    }
  }
}

Map<RegExp, List<ChordsheetElement> Function(Match)> chordSheetExpressions = {
  RegExp(r'\\begin(verse|chorus)\*?[\n\s]*(.*?)[\s\n]*\\end\1', dotAll: true):
      ChordsheetPart.parseTex,
  RegExp(r'\\repeatpart\{([^\\]*?)(\\rep\{\d+\})?\s*(?:\\singer\{.*\}?})?([^\\]*?)\}'):
      ChordsheetRepeat.parseTex,
  RegExp(r'\\transpose\{([+-]?\d+)\}'): ChordsheetTranspose.parseTex,
  RegExp(r'\\meter\{\\beatcount\}\{\\beatunit\}'): (p0) =>
      [ChordsheetRhythmChange()],
  RegExp(r'\\meter\{(\d+)\}\{(\d+)\}'): (p0) => [
        ChordsheetRhythmChange(
            upper: int.parse(p0.group(1)!), lower: int.parse(p0.group(2)!))
      ],
  RegExp(r'\\tempo\{(\d+)\}'): (p0) =>
      [ChordsheetRhythmChange(bpm: int.tryParse(p0.group(1)!))],
  RegExp(r'\\capo\{(.*?)\}'): (p0) => [],
  RegExp(r"\\prefer\w*"): (p0) => [],
  RegExp(r'\\musicnote\{.*?\}'): (p0) => [],
  RegExp(r"[\n\s]*"): (p0) => [],
};

Chordsheet parseTexChordsheet(RegExpMatch match) {
  Chordsheet sheet = Chordsheet(attributes: {});

  int i = 0;
  sheet.title = [
    for (String title in cleanTex(match.group(1)!).split("\\\\"))
      (i++ == 0) ? title : "($title)"
  ].join(" ");
  String? attrs = match.group(2);
  if (attrs != null) {
    sheet.attributes = parseTexAttrs(cleanTex(attrs));
  }
  String content = match.group(3) ?? "";
  content = cleanTex(content);
  sheet.elements = Scanner(content, chordSheetExpressions).list;
  Rhythm rhythm = Rhythm(
      bpm: sheet.attributes["bpm"],
      upper: sheet.attributes["beatcount"],
      lower: sheet.attributes["beatunit"]);
  sheet.initialState = sheet.initialState! + rhythm;
  for (int i = 0; i < sheet.elements.length; i++) {
    if (sheet.elements[i] is ChordsheetTranspose) {
      sheet.elements.removeAt(i--);
      continue;
    } else if (sheet.elements[i] is ChordsheetRhythmChange) {
      ChordsheetRhythmChange rc =
          sheet.elements.removeAt(i--) as ChordsheetRhythmChange;
      sheet.initialState = sheet.initialState! +
          Rhythm(bpm: rc.bpm, upper: rc.upper, lower: rc.lower);
    } else {
      break;
    }
  }
  return sheet;
}

Map<String, dynamic> parseTexAttrs(String tex) {
  Map<String, dynamic> attrs = {};
  Map<RegExp, List<dynamic> Function(Match)> attrHelp = {
    // RegExp(r"\s\s+"): (p0) => [],
    RegExp(r"(\w+)\s*=\s*"): (p0) => [p0.group(1)!],
    RegExp(r"\d+"): (p0) => [int.parse(p0.group(0)!)],
    RegExp(r"\{(.*?)\}\s*"): (p0) => [p0.group(1)],
    RegExp(r"([^,]+)\s*"): (p0) => [p0.group(1)],
    RegExp(r",\s*"): (p0) => [],
  };
  List<dynamic> items = Scanner(tex, attrHelp).list;
  for (int i = 0; i + 1 < items.length; i += 2) {
    attrs[items[i] as String] = items[i + 1];
  }

  return attrs;
}

List<Chordsheet> parseTexChordsheets(String text) {
  List<Chordsheet> chordsheets = <Chordsheet>[];
  RegExp regex = RegExp(r'\\beginsong\{([^{}]*)\}(?:\[(.*?)\])?(.*?)\\endsong',
      dotAll: true);
  for (RegExpMatch match in regex.allMatches(text)) {
    chordsheets.add(parseTexChordsheet(match));
  }
  return chordsheets;
}

abstract class ChordsheetElement extends Model {
  State applyTo(State s);
}
