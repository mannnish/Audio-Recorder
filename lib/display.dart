import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

class Display extends StatefulWidget {
  List<String> locations;
  Display({this.locations});
  @override
  _DisplayState createState() => _DisplayState();
}

class _DisplayState extends State<Display> {
  void onPlayAudio(String path) async {
    AudioPlayer audioPlayer = AudioPlayer();
    await audioPlayer.play(path, isLocal: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Saved Files"),
      ),
      body: Column(children: [
        Expanded(
          child: ListView.builder(
            itemCount: widget.locations.length,
            itemBuilder: (BuildContext context, int index) {
              return InkWell(
                  onTap: () {
                    onPlayAudio(widget.locations[index]);
                  },
                  child: Text(widget.locations[index]));
            },
          ),
        ),
        RaisedButton(
          onPressed: () async {
            null;
          },
          child: Text("Merge all"),
        )
      ]),
    );
  }
}
