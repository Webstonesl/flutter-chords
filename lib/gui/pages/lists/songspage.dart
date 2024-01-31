import 'package:flutter/material.dart';
import 'package:song_viewer/gui/widgets/defaultdrawer.dart';

import '../../../libs/database.dart';
import '../../../libs/datatypes.dart' as types;

class SongsPage extends StatefulWidget {
  List<types.Song> songs = <types.Song>[];
  @override
  State<StatefulWidget> createState() {
    return SongsPageState_();
  }
}

class SongsPageState_ extends State<SongsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: DefaultDrawer(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            for (types.Song song in widget.songs)
              ListTile(
                title: Text(song.name ?? ""),
              )
          ],
        ),
      ),
      floatingActionButton: IconButton(
        icon: Icon(Icons.add),
        onPressed: () {
          Navigator.pushReplacementNamed(context, "/songs/editor",
              arguments: {'song': null});
        },
      ),
    );
  }
}
