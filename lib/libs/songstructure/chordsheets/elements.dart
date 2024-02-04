import 'package:song_viewer/libs/database.dart';
import 'package:song_viewer/libs/songstructure/chordsheets/chordsheet.dart';

import 'package:song_viewer/libs/songstructure/musictheory.dart';
import 'package:song_viewer/libs/songstructure/texutils.dart';

abstract class ItemElement extends Model {
  dynamic render(State s);
  @override
  String getTableName() {
    return "items";
  }
}

class ItemChord extends ItemElement {
  String input;

  Chord? chord;
  static Map<RegExp, List<int>> modKeys = {
    // "": [0, 4, 7],

    RegExp("m(?!aj)"): [-4, 3],
    RegExp("dim"): [-4, 3, -7, 6],
    RegExp(r"sus(?!\d+)"): [-4, -3, 2, 5],
    RegExp(r"sus(?=\d+)"): [-4, -3],
    RegExp("2"): [2],
    RegExp("4"): [5],
    RegExp("9"): [2],
    RegExp(r"add(?=\d+)"): [],
    RegExp("11"): [5],
    RegExp("maj7"): [11],
    RegExp("7"): [10],

    // "sus2": []
  };
  ItemChord(this.input, [ChordsheetPart? part]) {
    RegExp exp = RegExp(r"\s*([A-G][#&b]*)\s*([^/\]]*)\s*(?:\/([A-G][#&b]))?");
    Match? c = exp.matchAsPrefix(input);
    if (c == null) {
      return;
    }
    Set<int> keys = {0, 4, 7};
    String mod = c.group(2)!;
    for (int i = 0; i < mod.length;) {
      int oi = i;
      for (RegExp key in modKeys.keys) {
        Match? m = key.matchAsPrefix(mod, i);
        if (m != null) {
          for (int k in modKeys[key]!) {
            if (k < 0) {
              keys.remove(k.abs());
            } else {
              keys.add(k);
            }
          }
          i = m.end;
        }
      }
      if (oi == i) {
        throw UnsupportedError("$mod - ${mod.substring(i)}");
      }
    }

    Key k = Key.getKeyFromStringTex(c.group(1)!)!;
    Set<Key> ks = {};
    for (int key in keys) {
      ks.add(Key((key + k.value) % 12));
    }
    Key? b = (c.group(3) != null) ? Key.getKeyFromStringTex(c.group(3)!) : null;
    chord = Chord(key: k, bass: b, mod: c.group(2)!, keys: ks, types: {});
  }

  @override
  String render(State s) {
    if (chord == null) {
      return input;
    }
    return (chord! + s.transpose).render(s);
  }

  @override
  Map<String, dynamic> _getData() {
    // TODO: implement getData
    throw UnimplementedError();
  }
}

class ItemMeasure extends ItemElement {
  Rhythm? rhythm;

  @override
  String render(State s) {
    return "";
  }

  @override
  Map<String, dynamic> _getData() {
    // TODO: implement getData
    throw UnimplementedError();
  }
}

class ItemLyric extends ItemElement {
  String lyrics;
  ItemLyric(this.lyrics);

  @override
  render(State s) {
    return lyrics;
  }

  @override
  Map<String, dynamic> _getData() {
    // TODO: implement getData
    throw UnimplementedError();
  }
}

class ItemRepeat extends ItemElement {
  RepeatType type;
  int? n;
  ItemRepeat(String s) : type = RepeatType.start {
    if (s == 'r') {
      type = RepeatType.end;
    } else if (s == 'l') {
      type = RepeatType.start;
    } else {
      type = RepeatType.number;
      n = int.parse(s);
    }
  }

  @override
  render(State s) {
    return "";
  }

  @override
  Map<String, dynamic> _getData() {
    // TODO: implement getData
    throw UnimplementedError();
  }
}

class ItemLineBreak extends ItemElement {
  @override
  render(State s) {
    // TODO: implement render
    throw UnimplementedError();
  }

  @override
  Map<String, dynamic> _getData() {
    // TODO: implement getData
    throw UnimplementedError();
  }
}

class ItemGroup extends ItemElement {
  List<ItemElement> items = [];

  @override
  render(State s) {
    // TODO: implement render
    throw UnimplementedError();
  }

  @override
  Map<String, dynamic> _getData() {
    // TODO: implement getData
    throw UnimplementedError();
  }
}

class ChordsheetPart extends ChordsheetElement {
  String? title;
  List<Chord> chord = <Chord>[];
  List<ItemElement> elements = <ItemElement>[];
  static List<ChordsheetElement> parseTex(Match match) {
    ChordsheetPart part = ChordsheetPart();
    Map<RegExp, List<ItemElement> Function(Match)> expressions = {
      RegExp(r'\n|(?:\\\\)'): (match) => [ItemLineBreak()],
      RegExp(r'[^\{\}|\\\n]+'): (match) => [ItemLyric(match.group(0)!)],
      RegExp(r'\|'): (match) => [ItemMeasure()],
      RegExp(r'\\\[(.*?)\]'): (match) => [ItemChord(match.group(1)!, part)],
      RegExp(r"\\(\s)"): (match) => [ItemLyric(match.group(1)!)],
      RegExp(r"\\halfspace"): (match) => [ItemLineBreak()],
      RegExp(r"\\(l|r)rep"): (match) => [ItemRepeat(match.group(1)!)],
      RegExp(r"\\rep\{(\d+)\}"): (match) => [ItemRepeat(match.group(1)!)],
      RegExp(r'\\versetitle\{([^\\]*?)(?:\\singer\{.*?\})?\}'): (match) {
        part.title = [
          for (String c in getCharacters(match.group(1)!))
            if (RegExp(r'[A-Za-z\-\s0-9]').hasMatch(c)) c
        ].join('');
        return [];
      },
      RegExp(r'\\\w+'): (match) => [],
      RegExp(r'[\{\}]'): (match) => [],
      RegExp(r'\\(?!.)'): (match) => [],
    };

    String content = match.group(2)!;
    part.elements = Scanner(content, expressions).list;

    return [part];
  }

  @override
  State applyTo(State s) {
    // TODO: implement applyTo
    throw UnimplementedError();
  }

  @override
  Map<String, dynamic> _getData() {
    // TODO: implement getData
    throw UnimplementedError();
  }

  @override
  String getTableName() {
    // TODO: implement getTableName
    throw UnimplementedError();
  }
}

class ChordsheetRepeat extends ChordsheetElement {
  static List<ChordsheetRepeat> parseTex(Match match) {
    ChordsheetRepeat repeat = ChordsheetRepeat();
    repeat.s = match.group(1)!;
    return [repeat];
  }

  int? n;
  ChordsheetPart? part;
  String s = '';

  @override
  State applyTo(State s) {
    throw UnimplementedError();
  }

  @override
  Map<String, dynamic> _getData() {
    throw UnimplementedError();
  }

  @override
  String getTableName() {
    throw UnimplementedError();
  }
}

class ChordsheetTranspose extends ChordsheetElement {
  Transpose transpose;

  ChordsheetTranspose(int t) : transpose = Transpose(t);
  static List<ChordsheetTranspose> parseTex(Match match) {
    return [ChordsheetTranspose(int.parse(match.group(1)!))];
  }

  @override
  State applyTo(State s) {
    return s + transpose;
  }

  @override
  Map<String, dynamic> _getData() {
    throw UnimplementedError();
  }

  @override
  String getTableName() {
    throw UnimplementedError();
  }
}