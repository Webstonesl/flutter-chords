import 'package:flutter/material.dart';

class DefaultDrawer extends StatefulWidget {
  const DefaultDrawer({super.key});

  @override
  State<StatefulWidget> createState() {
    return DefaultDrawerState_();
  }
}

class DefaultDrawerState_ extends State<DefaultDrawer> {
  @override
  Widget build(BuildContext context) {
    return Drawer(
        child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DrawerHeader(
            decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.inversePrimary),
            child: SizedBox(
              height: 100,
              child: Text("Song Viewer",
                  style: Theme.of(context).textTheme.headlineLarge),
            )),
        SingleChildScrollView(
          child: Column(children: [
            ListTile(
              leading: const Icon(Icons.music_note),
              title: const Text("Songs"),
              onTap: () {
                while (Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
                Navigator.pushNamed(context, '/songs');
              },
            ),
            ListTile(
              leading: const Icon(Icons.file_copy),
              title: const Text("Files"),
              onTap: () {
                while (Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
                Navigator.pushNamed(context, '/files');
              },
            ),
          ]),
        )
      ],
    ));
  }
}
