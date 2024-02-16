import 'package:flutter/material.dart';
import 'package:song_viewer/gui/widgets/defaultdrawer.dart';

class SetLists extends StatefulWidget {
  const SetLists();
  @override
  State<StatefulWidget> createState() {
    return _SetListsState();
  }
}

class _SetListsState extends State<SetLists> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const DefaultDrawer(),
      appBar: AppBar(
        title: const Text("Set Lists"),
        actions: [],
      ),
      floatingActionButton:
          FloatingActionButton(onPressed: () {}, child: Icon(Icons.add)),
    );
  }
}
