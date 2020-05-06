import 'dart:io';
import 'package:flutter_ffmpeg/flutter_ffmpeg.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class Display extends StatefulWidget {
  List<String> locations;
  Display({this.locations});
  @override
  _DisplayState createState() => _DisplayState();
}

class _DisplayState extends State<Display> {
  // final FlutterFFprobe _flutterFFprobe = new FlutterFFprobe();
  final FlutterFFmpeg _flutterFFmpeg = new FlutterFFmpeg();

  void onPlayAudio(String path) async {
    AudioPlayer audioPlayer = AudioPlayer();
    await audioPlayer.play(path, isLocal: true);
  }

  merge() async {
    final Directory directory = await getExternalStorageDirectory();
    final File file = File('${directory.path}/my_file.txt');
    String outputPath = directory.path + "/output.mp3";
    String temp = "";
    for (int i = 0; i < widget.locations.length; i++) {
      temp = temp + "file " + "'" + widget.locations[i] + "'";
      // temp = temp + widget.locations[i];
      
      if (i != widget.locations.length - 1) {
        temp = temp + "\n";
      }
    }
    await file.writeAsString(temp).then((value) {
      print("file created");
    });

    print(temp);
    print(file.path);
    print(outputPath);

    // ------------------------------------------------
    // this is the part which was supposed to do the merging part
    // and then would've deleted other recorded parts.
    // ------------------------------------------------

    _flutterFFmpeg
        .execute(
            // "ffmpeg -f concat -i ${file.path} -c copy ${widget.locations[0]}")
            "ffmpeg -f concat -i ${file.path} -c copy $outputPath")
        .then((rc) => print("FFmpeg process exited with rc $rc"))
        .catchError((e) {
      print(e);
    });

    // String temptwo = await file.readAsString();
    // print("string two ----");
    // print(temptwo);
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
          onPressed: merge,
          child: Text("Merge all"),
        )
      ]),
    );
  }
}
