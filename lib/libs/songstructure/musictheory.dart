abstract class MusicalElement {
  const MusicalElement();
  dynamic getData();
}

class Key extends MusicalElement {
  final int _value;
  int get value {
    int n = _value;
    while (n < 0) {
      n += 12;
    }
    while (n >= 12) {
      n -= 12;
    }
    return n;
  }

  Key(this._value);

  Key operator +(int c) {
    while (value + c < 0) {
      c += 12;
    }
    while (value + c >= 12) {
      c -= 12;
    }
    return Key(value + c);
  }

  @override
  bool operator ==(Object a) {
    if (a is Key) {
      return a.value == value;
    }
    return false;
  }

  static final Map<String, int> _keynames = {
    'A': 0,
    'B': 2,
    'C': 3,
    'D': 5,
    'E': 7,
    'F': 8,
    'G': 10
  };
  static final Map<int, String> _keycodes = {
    0: 'A',
    2: 'B',
    3: 'C',
    5: 'D',
    7: 'E',
    8: 'F',
    10: 'G'
  };
  static final RegExp regex = RegExp(r"[A-G][#&b]*");
  static Key? getKeyFromStringTex(String s, [int start = 0]) {
    Match? m = regex.matchAsPrefix(s, start);
    if (m == null) {
      return null;
    }
    s = m.group(0)!;

    Key k = Key(_keynames[s[0]]!);
    for (int i = 1; i < s.length; i++) {
      if (s[i] == '#') {
        k = k + 1;
      } else if (['&', 'b'].contains(s[i])) {
        k = k + -1;
      }
    }
    return k;
  }

  String render(State state) {
    Accidental accidental = state.scale.getAccidental() ?? Accidental.sharp;
    if (_keycodes.containsKey(value)) {
      return _keycodes[value]!;
    } else {
      int v = value;
      if (accidental == Accidental.sharp) {
        v = (v += 11) % 12;
      } else {
        v = (v + 1) % 12;
      }
      return [_keycodes[v]!, state.accidentalStrings[accidental]!].join('');
    }
  }

  @override
  getData() {
    return value;
  }
}

class Rhythm extends MusicalElement {
  final int? bpm;
  final int? upper;
  final int? lower;

  Rhythm({required this.bpm, required this.upper, required this.lower});

  @override
  getData() {
    return {'bpm': bpm, 'upper': upper, 'lower': lower};
  }

  static Rhythm fromMap(Map<String, dynamic> data) {
    return Rhythm(bpm: data["bpm"], upper: data["upper"], lower: data["lower"]);
  }
}

enum ChordType { major, minor, dim, sus, add2, add4 }

class Chord extends MusicalElement {
  final Key key;
  final Key? _bass;
  final Set<ChordType> types;
  final String mod;
  Key get bass => _bass ?? key;

  final Set<Key> keys;

  Chord(
      {required this.mod,
      required this.key,
      required Key? bass,
      required this.keys,
      required this.types})
      : _bass = bass;
  Chord operator +(Transpose t) {
    return Chord(
        key: key + t.n,
        bass: _bass == null ? null : _bass + t.n,
        mod: mod,
        keys: keys,
        types: types);
  }

  String render(State s) {
    return [key.render(s), mod, if (_bass != null) "/${_bass.render(s)}"]
        .join('');
  }

  @override
  getData() {
    return {
      'key': key.getData(),
      'bass': _bass == null ? null : bass.getData(),
      'mod': mod
    };
  }
}

enum ScaleType { major, naturalMinor }

class Scale extends MusicalElement {
  final Key key;

  final ScaleType type;

  Scale({required this.key, required this.type});
  Accidental? getAccidental() {
    int v = key.value;
    if (type == ScaleType.naturalMinor) {
      v += 3;
    }
    if ([3, 10, 5, 7, 2].contains(v)) {
      return Accidental.sharp;
    } else if ([8, 1, 6, 11, 4].contains(v)) {
      return Accidental.flat;
    } else {
      return null;
    }
  }

  Scale operator +(Transpose t) {
    return Scale(key: key + t.n, type: type);
  }

  @override
  bool operator ==(Object o) {
    if (o is! Scale) {
      return false;
    }
    return (o.key.value == key.value) && (type == o.type);
  }

  @override
  String toString() {
    return key.render(State(
        repeats: [],
        rhythm: Rhythm(bpm: null, upper: null, lower: null),
        scale: this));
  }

  @override
  getData() {
    return {'key': key.getData(), 'type': type.index};
  }

  static Scale fromMap(data) {
    return Scale(key: Key(data["key"]), type: ScaleType.values[data["type"]]);
  }
}

enum RepeatType { start, end, number }

class Repeat extends MusicalElement {
  final RepeatType type;
  int? number;
  final Repeat? start;
  Repeat? end;
  Repeat({required this.type, this.start, this.number});

  @override
  getData() {
    // TODO: implement getData
    throw UnimplementedError();
  }
}

class RepeatState {
  final Repeat? start;
  final Repeat? end;
  final int n;
  final int i;

  RepeatState({this.start, required this.end, this.n = 2, required this.i});
  RepeatState? next() {
    if (i + 1 < n) {
      return RepeatState(start: start, end: end, i: i + 1, n: n);
    }
    return null;
  }
}

class Transpose extends MusicalElement {
  final int n;

  const Transpose(this.n);

  @override
  getData() {
    return n;
  }
}

enum Accidental {
  sharp,
  flat,
}

class State {
  final List<RepeatState> repeats;
  Map<Accidental, String> accidentalStrings = {
    Accidental.sharp: String.fromCharCode(0x0023),
    Accidental.flat: String.fromCharCode(0x0266d)
  };
  final Scale scale;
  final Rhythm rhythm;
  final Transpose transpose;
  State(
      {required this.repeats,
      required this.scale,
      required this.rhythm,
      this.transpose = const Transpose(0)});
  State operator +(MusicalElement element) {
    if (element is Transpose) {
      Transpose t = Transpose(transpose.n + element.n);
      return State(
          repeats: repeats.toList(),
          scale: scale + element,
          rhythm: rhythm,
          transpose: t);
    } else if (element is Scale) {
      return State(
          repeats: repeats.toList(),
          scale: element,
          rhythm: rhythm,
          transpose: transpose);
    } else if (element is Rhythm) {
      int? bpm = element.bpm ?? rhythm.bpm;
      int? upper = element.upper ?? rhythm.upper;
      int? lower = element.lower ?? rhythm.lower;
      return State(
          repeats: repeats.toList(),
          scale: scale,
          rhythm: Rhythm(bpm: bpm, upper: upper, lower: lower));
    }
    throw UnimplementedError("Not yet implemented");
  }

  Map<String, dynamic> get data => {
        'scale': scale.getData(),
        'rhythm': rhythm.getData(),
        'transpose': transpose.getData(),
      };

  static State? fromMap(Map<String, dynamic> data) {
    return State(
        repeats: [],
        scale: Scale.fromMap(data["scale"]),
        rhythm: Rhythm.fromMap(data["rhythm"]),
        transpose: Transpose(data["transpose"]));
  }
}
