
class TexEnvironment {
  final List<TexEnvironment> environments = <TexEnvironment>[];
  String text;
  String start;
  String end;
  TexEnvironment(this.text, {this.start = "{", this.end = "}"}) {
    String? start;
    int startPos;
    String? envText;
    String end;
    for (int i = 0; i < text.length; i++) {
      print(text[i]);
    }
  }
}
