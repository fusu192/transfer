import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_uploader/flutter_uploader.dart';
import 'package:path/path.dart';

const String title = "FileUpload Sample app";
const String uploadURL = "http://192.168.199.202:5000/upload";
const String uploadBinaryURL = "https://us-central1-flutteruploader.cloudfunctions.net/upload/binary";


void log(msg,{tag= "default_tag"}){
  var now =new DateTime.now();
  print("| (time)->"+now.toString()+" | (tag)->$tag  | (msg)->$msg");
}


class UploadItem {
  final String id;
  final String tag;
  final String path;
  final MediaType type;
  final String remoteHash;
  final int remoteSize;
  final int progress;
  final UploadTaskStatus status;

  UploadItem({
    this.id,
    this.tag,
    this.path,
    this.type,
    this.remoteHash,
    this.remoteSize,
    this.progress = 0,
    this.status = UploadTaskStatus.undefined,
  });

  UploadItem copyWith({
    UploadTaskStatus status,
    int progress,
    String remoteHash,
    int remoteSize,
  }) =>
      UploadItem(
        id: this.id,
        tag: this.tag,
        path: this.path,
        type: this.type,
        status: status ?? this.status,
        progress: progress ?? this.progress,
        remoteHash: remoteHash ?? this.remoteHash,
        remoteSize: remoteSize ?? this.remoteSize,
      );

  bool isCompleted() =>
      this.status == UploadTaskStatus.canceled || this.status == UploadTaskStatus.complete || this.status == UploadTaskStatus.failed;
}


enum MediaType { Image}
class UploadScreen extends StatefulWidget {
  UploadScreen({Key key}) : super(key: key);
  @override
  _UploadScreenState createState() => _UploadScreenState();
}
class _UploadScreenState extends State<UploadScreen> {

  FlutterUploader uploader = FlutterUploader();
  Map<String, UploadItem> _tasks = {};
  @override
  void initState() {
    super.initState();
  }
  @override
  void dispose() {
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plugin example app'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: ListView.separated(
                padding: EdgeInsets.all(20.0),
                itemCount: _tasks.length,
                itemBuilder: (context, index) {
                  final item = _tasks.values.elementAt(index);
                  log("${item.tag} - ${item.status}");
                  return UploadItemView(
                    item: item,
                    onCancel: cancelUpload,
                  );
                },
                separatorBuilder: (context, index) {
                  return Divider(
                    color: Colors.black,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }


  Future cancelUpload(String id) async {
    await uploader.cancel(taskId: id);
  }
}


typedef CancelUploadCallback = Future<void> Function(String id);

class UploadItemView extends StatelessWidget {
  final UploadItem item;
  final CancelUploadCallback onCancel;

  UploadItemView({
    Key key,
    this.item,
    this.onCancel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final progress = item.progress.toDouble() / 100;
    final widget = item.status == UploadTaskStatus.running
        ? LinearProgressIndicator(value: progress)
        : Container();
    final buttonWidget = item.status == UploadTaskStatus.running
        ? Container(
          height: 50,
          width: 50,
          child: IconButton(
            icon: Icon(Icons.cancel),
            onPressed: () => onCancel(item.id),
          ),
        )
        : Container();
    return Row(
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(item.tag),
              Container(
                height: 5.0,
              ),
              Text(item.status.description),
              (item.status == UploadTaskStatus.complete && item.remoteHash != null)
                  ? Builder(builder: (context) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _compareMd5(item.path, item.remoteHash),
                    _compareSize(item.path, item.remoteSize),
                  ],
                );
              }) :Container(),
              Container(
                height: 5.0,
              ),
              widget
            ],
          ),
        ),
        buttonWidget
      ],
    );
  }

  Text _compareMd5(String localPath, String remoteHash) {
    var digest = md5.convert(File(localPath).readAsBytesSync());
    if (digest.toString().toLowerCase() == remoteHash) {
      return Text(
        'Hash $digest √',
        style: TextStyle(color: Colors.green),
      );
    } else {
      return Text(
        'Hash $digest vs $remoteHash ƒ',
        style: TextStyle(color: Colors.red),
      );
    }
  }

  Text _compareSize(String localPath, int remoteSize) {
    final length = File(localPath).lengthSync();
    if (length == remoteSize) {
      return Text(
        'Length $length √',
        style: TextStyle(color: Colors.green),
      );
    } else {
      return Text(
        'Length $length vs $remoteSize ƒ',
        style: TextStyle(color: Colors.red),
      );
    }
  }
}
