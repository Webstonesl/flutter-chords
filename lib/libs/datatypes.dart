import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

String cleanLyrics(String input) {
  print("[input]\n$input");
  input = input.replaceAll(RegExp(r'\\\[[^[]*?\]'), '');
  RegExp(r'\\text\w+\{(.*?)\}').allMatches(input).forEach((RegExpMatch match) {
    input = input.replaceAll(match.group(0)!, match.group(1)!);
  });
  input = input.replaceAll(RegExp(r'\\(\w+|.)'), '');

  if (RegExp(r'[A-Za-z]').hasMatch(input)) {
    return input;
  }
  print("[output]\n$input");
  return "";
}

abstract class Model {
  bool saved = false;
  bool modified = false;
}

class Language extends Model {
  static List<Language> LANGUAGES = <Language>[];
  String? code;
  String name;

  Language({required this.code, required this.name});
}

class Word extends Model {
  int? id;
  String word;
  Language language;
  Word(this.word, this.language);
}

class Song extends Model {
  Uuid? songid;
  String? name;
  Map<String, dynamic> attributes = <String, dynamic>{};
  List<String> authors = <String>[];
  List<Part> parts = <Part>[];
  List<Chordsheet> chordsheets = <Chordsheet>[];
  static Map<String, dynamic> PARSE_ATTRS(String attrs) {
    Map<String, dynamic> map = {};
    RegExp brackets = RegExp(r'\{([^{]*?)\}');
    List<String> groups = [];
    while (brackets.hasMatch(attrs)) {
      RegExpMatch match = brackets.firstMatch(attrs)!;
      int n = groups.length;
      groups.add(match.group(1)!);
      attrs = [
        attrs.substring(0, match.start),
        '\\$n\\',
        attrs.substring(match.end)
      ].join('');
    }
    RegExp kvpair = RegExp(r'\s*(\w+)\s*=\s*(.*?)(?:,|$)');
    RegExp expect = RegExp(r"\\(\d+)\\");
    for (RegExpMatch match in kvpair.allMatches(attrs)) {
      String key = match.group(1)!;
      String value = match.group(2)!;
      if (expect.hasMatch(value)) {
        RegExpMatch match = expect.firstMatch(value)!;
        value = groups[int.parse(match.group(1)!)];
      }
      map[key] = value;
    }
    return map;
  }

  static List<Song> PARSE_TEX(String tex, {File? file}) {
    if (kDebugMode) {
      print("test1");
    }
    List<Song> results = <Song>[];
    for (RegExpMatch match in RegExp(
            r'\\beginsong\{(.*?)\}\s*(?:\[(.*?)\])?(.*?)\\endsong',
            dotAll: true)
        .allMatches(tex)) {
      Song song = Song();
      Chordsheet chordsheet = Chordsheet();
      song.chordsheets.add(chordsheet);
      chordsheet.songs.add(song);
      chordsheet.file = file;
      List<String> name = match.group(1)!.split('\\\\');
      for (int i = 1; i < name.length; i++) {
        name[i] = '(${name[i]})';
      }
      song.name = name.join(' ');
      if (match.group(2) != null) {
        Map<String, dynamic> attrs = PARSE_ATTRS(match.group(2)!);
        if (attrs.containsKey('by')) {
          for (String author in (attrs['by'] as String).split(',')) {
            song.authors.add(author.trim());
          }
        }
      }
      String contents = match.group(3)!;
      List<Map<String, dynamic>> groups = [];
      RegExp partsMatch =
          RegExp(r"\\begin(verse|chorus)(\*?)(.*?)\\end\1", dotAll: true);

      while (partsMatch.hasMatch(contents)) {
        RegExpMatch match = partsMatch.firstMatch(contents)!;
        int n = groups.length;
        groups.add({'content': match.group(0)!.trim()});
        contents = [
          contents.substring(0, match.start),
          '\\$n\\',
          contents.substring(match.end)
        ].join('');
        String contents2 = match.group(3)!;
        Part part = Part();
        for (RegExpMatch m2
            in RegExp(r'\\versetitle\{([^{]*?)\}').allMatches(contents2)) {
          part.title = m2.group(1)!.replaceAll(':', '');
          contents2 = contents2.replaceAll(m2.group(0)!, "\n").trim();
        }

        part.lyrics = cleanLyrics(contents2);
        if (part.lyrics != null) {
          if (part.lyrics != "") {
            part.song = song;
            groups.last['chordsheet'] = chordsheet;
            groups.last['part'] = part;
            song.parts.add(part);
          }
        }
      }

      // print(match.group(3));

      results.add(song);
    }
    return results;
  }
}

class PartType extends Model {
  static List<Color> colors = <Color>[];
  static Map<RegExp, PartType> Types = {
    RegExp(r'Chorus\s*(\w*)'): PartType(name: "Chorus %s"),
  };
  String? name;
  Map<String, String> localnames = <String, String>{};
  Color? color;
  PartType({required this.name, this.color});
}

class Part extends Model {
  Song? song;
  Uuid? partid;
  PartType? partType;
  String? title;
  String? lyrics;
  Color? localColor;
  Part({this.song});
  Color? get color =>
      localColor ?? ((partType == null) ? null : partType!.color);
  List<Language> languages = [];
}

class Chordsheet extends Model {
  List<Song> songs = [];
  Uuid? csid;
  File? file;
  String notes = "";
  Map<String, dynamic> attributes = <String, dynamic>{};
  List<ChordsheetPart> parts = <ChordsheetPart>[];
  void parse_tex() {}
}

class ChordsheetPart extends Model {
  int? index;

  Part? part;
  Chordsheet? chordsheet;
  String? content;
  String notes = "";
  ChordsheetPart({required this.chordsheet});
}

class File extends Model {
  Uuid? fileid;
  String? filename;
  String? filetype;
  Uint8List? data;
}
