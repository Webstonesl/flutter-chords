import 'package:song_viewer/libs/database.dart';
import 'package:song_viewer/libs/songstructure/chordsheets/elements.dart';

import 'package:uuid/uuid.dart';

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
  Map<String, dynamic> _getData() {
    // TODO: implement getData
    throw UnimplementedError();
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
  RegExp(r'\\repeatpart\{([^\\]*?)(\\rep\{\d+\})?\}'):
      ChordsheetRepeat.parseTex,
  RegExp(r'\\transpose\{([+-]?\d+)\}'): ChordsheetTranspose.parseTex,
  RegExp(r'\\meter\{\\beatcount\}\{\\beatunit\}'): (p0) => [],
  RegExp(r'\\capo\{(.*?)\}'): (p0) => [],
  RegExp(r"[\n\s]*"): (p0) => []
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
    sheet.attributes = parseTexAttrs(cleanTex(attrs!));
  }
  String content = match.group(3) ?? "";
  content = cleanTex(content);
  sheet.elements = Scanner(content, chordSheetExpressions).list;
  return sheet;
}

Map<String, dynamic> parseTexAttrs(String tex) {
  Map<String, dynamic> attrs = {};
  Map<RegExp, List<dynamic> Function(Match)> attr_help = {
    // RegExp(r"\s\s+"): (p0) => [],
    RegExp(r"(\w+)\s*=\s*"): (p0) => [p0.group(1)!],
    RegExp(r"\d+"): (p0) => [int.parse(p0.group(0)!)],
    RegExp(r"\{(.*?)\}\s*"): (p0) => [p0.group(1)],
    RegExp(r"([^,]+)\s*"): (p0) => [p0.group(1)],
    RegExp(r",\s*"): (p0) => [],
  };
  List<dynamic> items = Scanner(tex, attr_help).list;
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
