import 'package:song_viewer/libs/songstructure/chordsheets/chordsheet.dart';

import 'package:song_viewer/libs/songstructure/musictheory.dart';
import 'package:song_viewer/libs/songstructure/texutils.dart';

abstract class ItemElement {
  dynamic render(State s);
  dynamic getData();
  Map<String, dynamic> get data =>
      {'itemtype': runtimeType.toString(), 'data': getData()};
  static ItemElement getItemElement(Map<String, dynamic> map) {
    dynamic data = map["data"];
    switch (map["itemtype"]) {
      case "ItemLyric":
        return ItemLyric(data);
      case "ItemChord":
        return ItemChord(data["text"],
            key: data["chord"]["key"],
            bass: data["chord"]["bass"],
            mod: data["chord"]["mod"]);
      case "ItemLineBreak":
        return ItemLineBreak();
      case "ItemMeasure":
        return ItemMeasure();
    }

    return ItemLineBreak();
  }
}

class ItemChord extends ItemElement {
  String? input;

  Chord? chord;
  static Map<RegExp, List<int>> modKeys = {
    // "": [0, 4, 7],

    RegExp("m(?!aj)"): [-4, 3],
    RegExp("dim"): [-4, 3, -7, 6],
    RegExp(r"sus(?!\d+)"): [-4, -3, 2, 5],
    RegExp(r"sus(?=\d+)"): [-4, -3],
    RegExp("2"): [2],
    RegExp("4"): [5],
    RegExp("5"): [-4],
    RegExp("6"): [9],
    RegExp("9"): [2],
    RegExp(r"add(?=\d+)"): [],
    RegExp("11"): [5],
    RegExp("maj7"): [11],
    RegExp("7"): [10],

    // "sus2": []
  };
  ItemChord(this.input,
      {ChordsheetPart? part, int? key, int? bass, String? mod}) {
    Set<int> keys = {0, 4, 7};
    Key k;
    Key? b;
    if (key == null) {
      RegExp exp =
          RegExp(r"\s*([A-G][#&b]*)\s*([^/\]]*)\s*(?:\/([A-G][#&b]))?");
      Match? c = exp.matchAsPrefix(input!);
      if (c == null) {
        return;
      }

      mod = c.group(2)!;
      k = Key.getKeyFromStringTex(c.group(1)!)!;
      b = (c.group(3) != null) ? Key.getKeyFromStringTex(c.group(3)!) : null;
    } else {
      k = Key(key);
      b = bass == null ? null : Key(bass);
      if (mod == null) {
        throw Exception("Mod cannot be null");
      }
    }
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

    Set<Key> ks = {};
    for (int keyv in keys) {
      ks.add(Key((keyv + k.value) % 12));
    }

    chord = Chord(key: k, bass: b, mod: mod!, keys: ks, types: {});
  }

  @override
  String render(State s) {
    if (chord == null) {
      return input!;
    }
    return (chord! + s.transpose).render(s);
  }

  @override
  getData() {
    return {
      'chord': chord == null
          ? null
          : {
              'key': chord!.key.value,
              'bass': chord!.bass == chord!.key ? null : chord!.bass.value,
              'mod': chord!.mod,
            },
      'text': chord == null ? input : null
    };
  }
}

class ItemMeasure extends ItemElement {
  Rhythm? rhythm;

  @override
  String render(State s) {
    return "";
  }

  @override
  getData() {
    if (rhythm != null) {
      return rhythm!.getData();
    } else {
      return null;
    }
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
  getData() {
    return lyrics;
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
  getData() {
    return {"repeat": type.index, "number": n};
  }
}

class ItemLineBreak extends ItemElement {
  @override
  render(State s) {}

  @override
  getData() {
    return null;
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
      RegExp(r'\\\[(.*?)\]'): (match) => [ItemChord(match.group(1)!)],
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
    return s;
  }

  @override
  Map<String, dynamic> getData() {
    return {
      'title': title,
      'elements': [for (ItemElement element in elements) element.data]
    };
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
  String? get title => (part == null) ? s : part!.title;
  @override
  State applyTo(State s) {
    return s;
  }

  @override
  Map<String, dynamic> getData() {
    return {
      'title': s,
      'n': n,
      'part': part,
    };
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
  Map<String, dynamic> getData() {
    return {'transpose': transpose.getData()};
  }
}
