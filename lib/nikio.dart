import 'dart:async';
import 'dart:io' as io;

import 'package:audioplayers/audioplayers.dart';
import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:flutter/material.dart';
import 'package:flutter_audio_recorder/flutter_audio_recorder.dart';
import 'package:path_provider/path_provider.dart';
import 'package:v1/display.dart';

class RecorderExample extends StatefulWidget {
  final LocalFileSystem localFileSystem;

  RecorderExample({localFileSystem})
      : this.localFileSystem = localFileSystem ?? LocalFileSystem();

  @override
  State<StatefulWidget> createState() => new RecorderExampleState();
}

class RecorderExampleState extends State<RecorderExample> {
  FlutterAudioRecorder _recorder;
  Recording _current;
  RecordingStatus _currentStatus = RecordingStatus.Unset;
  int index = 0;
  Duration totalDuration = Duration(seconds: 0);
  Duration undoDuration = Duration(seconds: 0);
  Duration timeLimit = Duration(seconds: 30);
  String customBatchPath;
  String customPath;
  bool _undoused;
  bool _canrecordfurther;
  String pathtodel;
  List<String> locations, tempLocations;
  bool canMerge = false;

  @override
  void initState() {
    super.initState();
    // it wil set index, duration, new path for a whole new batch
    _init();
    // it will initialize but wont start for batch[0]
  }

  @override
  Widget build(BuildContext context) {
    return new Center(
      child: new Padding(
        padding: new EdgeInsets.all(8.0),
        child: new Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              new Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: new FlatButton(
                      onPressed: _canrecordfurther == true
                          ? () {
                              switch (_currentStatus) {
                                case RecordingStatus.Initialized:
                                  {
                                    _start();
                                    break;
                                  }
                                case RecordingStatus.Recording:
                                  {
                                    _stop();
                                    break;
                                  }
                                case RecordingStatus.Stopped:
                                  {
                                    _initafterpause();
                                    break;
                                  }
                                default:
                                  break;
                              }
                            }
                          : null,
                      child: _buildText(_currentStatus),
                      color: Colors.lightBlue,
                    ),
                  ),
                  new FlatButton(
                    onPressed: _currentStatus != RecordingStatus.Unset
                        ? _stopBatch
                        : null,
                    child:
                        new Text("Stop", style: TextStyle(color: Colors.white)),
                    color: Colors.blueAccent,
                  ),
                  SizedBox(
                    width: 8,
                  ),
                  new FlatButton(
                    onPressed: _currentStatus == RecordingStatus.Recording
                        ? () {
                            print("nothing");
                          }
                        : () {
                            if (!_undoused) {
                              setState(() {
                                // delete the file
                                locations.removeLast();
                                File file =
                                    widget.localFileSystem.file(pathtodel);
                                file.deleteSync(recursive: true);
                                // cant use undo again now
                                _undoused = true;
                                // print("deleted the file at $index");
                                totalDuration -= undoDuration;
                                if (totalDuration < timeLimit) {
                                  _canrecordfurther = true;
                                }
                              });
                            }
                          },
                    child:
                        new Text("Undo", style: TextStyle(color: Colors.white)),
                    color: Colors.redAccent,
                  ),
                ],
              ),
              new Text("Status : $_currentStatus"),
              new Text("File: ${_current?.path}"),
              new Text("index: $index"),
              new Text("Files saved: ${locations.length}"),
              new Text("total duration: $totalDuration"),
              new Text(
                  "Audio recording duration : ${_current?.duration.toString()}"),
              Row(
                children: [
                  canMerge == true
                      ? RaisedButton(
                          onPressed: _currentStatus != RecordingStatus.Recording
                              ? () {
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) => Display(
                                              locations: tempLocations)));
                                }
                              : null,
                          child: Text('Merge'),
                        )
                      : SizedBox(width: 5),
                ],
              ),
            ]),
      ),
    );
  }

  _initafterpause() async {
    setState(() {
      index++;
    });
    customPath = customBatchPath + '__$index';
    // print("new location added");
    _recorder = FlutterAudioRecorder(customPath, audioFormat: AudioFormat.WAV);
    await _recorder.initialized;
    var current = await _recorder.current(channel: 0);
    print(current);
    setState(() {
      _current = current;
      _currentStatus = current.status;
      print(_currentStatus);
    });
  }

  _init() async {
    try {
      if (await FlutterAudioRecorder.hasPermissions) {
        io.Directory appDocDirectory;
        if (io.Platform.isIOS) {
          appDocDirectory = await getApplicationDocumentsDirectory();
        } else {
          appDocDirectory = await getExternalStorageDirectory();
        }
        index = 0;
        customBatchPath = appDocDirectory.path +
            '/' +
            DateTime.now().millisecondsSinceEpoch.toString();
        setState(() {
          customPath = customBatchPath + '__$index';
        });
        // print("new location added");
        _recorder =
            FlutterAudioRecorder(customPath, audioFormat: AudioFormat.WAV);
        await _recorder.initialized;
        // after initialization
        var current = await _recorder.current(channel: 0);
        print(current);
        setState(() {
          // reset every variable used
          locations = [];
          _undoused = true;
          totalDuration = Duration(seconds: 0);
          undoDuration = Duration(seconds: 0);
          _canrecordfurther = true;
          _current = current;
          _currentStatus = current.status;
          print(_currentStatus);
        });
      } else {
        Scaffold.of(context).showSnackBar(
            new SnackBar(content: new Text("You must accept permissions")));
      }
    } catch (e) {
      print(e);
    }
  }

  _start() async {
    try {
      await _recorder.start();
      var recording = await _recorder.current(channel: 0);
      setState(() {
        _current = recording;
        canMerge = false;
      });

      const tick = const Duration(milliseconds: 50);
      new Timer.periodic(tick, (Timer t) async {
        if (_currentStatus == RecordingStatus.Stopped) {
          t.cancel();
        }
        var current = await _recorder.current(channel: 0);
        setState(() {
          if (_current.status != RecordingStatus.Stopped) {
            _current = current;
            _currentStatus = _current.status;
            // print(_current.duration.toString());
            Duration temp = timeLimit - totalDuration - _current.duration;
            // print("time left :  $temp");
            if (temp.inSeconds <= 0) {
              t.cancel();
              _canrecordfurther = false;
              _stop();
            }
          }
        });
      });
    } catch (e) {
      print(e);
    }
  }

  _stop() async {
    if (_current.status == RecordingStatus.Recording) {
      var result = await _recorder.stop();
      print("Stop recording: ${result.path}");
      print("Stop recording: ${result.duration}");
      setState(() {
        // for total time and undo function
        locations.add(result.path);
        _undoused = false;
        totalDuration += result.duration;
        undoDuration = result.duration;
        pathtodel = result.path;
        // mandatory
        _current = result;
        _currentStatus = _current.status;
      });
    }
  }

  _stopBatch() async {
    _stop();
    setState(() {
      tempLocations = locations;
      canMerge = true;
    });
    _init();
  }

  Widget _buildText(RecordingStatus status) {
    var text = "";
    switch (_currentStatus) {
      case RecordingStatus.Initialized:
        {
          if (index == 0) {
            text = 'Start';
          } else {
            text = 'Resume';
          }
          // when tapped this call _start to start with index
          break;
        }
      case RecordingStatus.Recording:
        {
          text = 'Pause';
          // when tapped this call _stop to stop with index and call initafter(index++)
          break;
        }
      case RecordingStatus.Stopped:
        {
          text = 'Press Again';
          // to create new batch which means call _init
          break;
        }
      default:
        break;
    }
    return Text(text, style: TextStyle(color: Colors.white));
  }
}
