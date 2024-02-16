import 'package:flutter/material.dart';

String cleanTex(String tex) {
  Map<RegExp, String Function(Match)> expressions = {
    RegExp(r'''(?<!\\)%.*?\n'''): (p0) => "",
    RegExp(r'''\\([`~"'^])([A-Za-z])'''): (p0) {
      Map<String, int> codes = {
        '`': 0x0300,
        '\'': 0x0301,
        '^': 0x0302,
        '~': 0x0303,
        '"': 0x0308
      };
      return String.fromCharCodes(
          [codes[p0.group(1)!]!, for (int c in p0.group(2)!.codeUnits) c]);
    },
    RegExp(r'''\\([`~"'^])\{([A-Za-z])\}'''): (p0) {
      Map<String, int> codes = {
        '`': 0x0300,
        '\'': 0x0301,
        '^': 0x0302,
        '~': 0x0303,
        '"': 0x0308
      };
      return String.fromCharCodes(
          [codes[p0.group(1)!]!, for (int c in p0.group(2)!.codeUnits) c]);
    },
    RegExp(r"''"): (p0) => String.fromCharCode(0x201C),
    RegExp(r"``"): (p0) => String.fromCharCode(0x201E),
  };

  for (RegExp exp in expressions.keys) {
    while (exp.hasMatch(tex)) {
      Match match = exp.firstMatch(tex)!;
      String value = expressions[exp]!(match);
      tex = [tex.substring(0, match.start), value, tex.substring(match.end)]
          .join('');
    }
  }
  return tex;
}

Iterable<String> getCharacters(String s) {
  return s.characters;
}
