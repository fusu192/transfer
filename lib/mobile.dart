import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:path/path.dart' as p;
import 'package:intl/intl.dart';
import 'package:progress_dialog/progress_dialog.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_uploader/flutter_uploader.dart';
import 'package:path/path.dart';
import 'package:open_file/open_file.dart';


const String title = "FileUpload Sample app";
const String uploadURL = "http://192.168.199.202:5000/upload";
const String uploadBinaryURL = "https://us-central1-flutteruploader.cloudfunctions.net/upload/binary";
enum MediaType { Image, Video}

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

void log(msg,{tag= "default_tag"}){
  var now =new DateTime.now();
  print("| (time)->"+now.toString()+" | (tag)->$tag  | (msg)->$msg");
}

ProgressDialog pr;

class Common {
  factory Common() => _getInstance();
  static Common get instance => _getInstance();
  static Common _instance; // 单例对象
  static Common _getInstance() {
    if (_instance == null) {
      _instance = Common._internal();
    }
    return _instance;
  }
  Common._internal();
  String sDCardDir;
  String mobile_path;
  String getFileSize(int fileSize) {
    String str = '';
    if (fileSize < 1024) {
      str = '${fileSize.toStringAsFixed(2)}B';
    } else if (1024 <= fileSize && fileSize < 1048576) {
      str = '${(fileSize / 1024).toStringAsFixed(2)}KB';
    } else if (1048576 <= fileSize && fileSize < 1073741824) {
      str = '${(fileSize / 1024 / 1024).toStringAsFixed(2)}MB';
    }
    return str;
  }
  String selectIcon(String ext) {
    String iconImg = 'assets/images/unknown.png';

    switch (ext) {
      case '.ppt':
      case '.pptx':
        iconImg = 'assets/images/ppt.png';
        break;
      case '.doc':
      case '.docx':
        iconImg = 'assets/images/word.png';
        break;
      case '.xls':
      case '.xlsx':
        iconImg = 'assets/images/excel.png';
        break;
      case '.jpg':
      case '.jpeg':
      case '.png':
      case '.webp':
        iconImg = 'assets/images/image.png';
        break;
      case '.txt':
        iconImg = 'assets/images/txt.png';
        break;
      case '.mp3':
        iconImg = 'assets/images/mp3.png';
        break;
      case '.mp4':
        iconImg = 'assets/images/video.png';
        break;
      case '.rar':
      case '.zip':
        iconImg = 'assets/images/zip.png';
        break;
      case '.psd':
        iconImg = 'assets/images/psd.png';
        break;
      default:
        iconImg = 'assets/images/file.png';
        break;
    }
    return iconImg;
  }
}



class FileManager extends StatefulWidget {
  @override
  _FileManagerState createState() => _FileManagerState();
}

class _FileManagerState extends State<FileManager> {
  FlutterUploader uploader = FlutterUploader();
  StreamSubscription _progressSubscription;
  StreamSubscription _resultSubscription;
  Map<String, UploadItem> _tasks = {};


  List<FileSystemEntity> files = [];
  MethodChannel _channel = MethodChannel('openFileChannel');
  Directory parentDir;
  ScrollController controller = ScrollController();
  List<double> position = [];

  DateTime lastPopTime;
  double percentage = 0.0;




  Future getVideo(File video) async {
    final String savedDir = dirname(video.path);
    final String filename = basename(video.path);
    final tag = "$filename video upload ${_tasks.length + 1}";
    final url = uploadURL;

    var fileItem = FileItem(
      filename: filename,
      savedDir: savedDir,
      fieldname: "file",
    );

    var taskId = await uploader.enqueue(
      url: url,
      data: {"name": "john"},
      files: [fileItem],
      method: UploadMethod.POST,
      tag: tag,
      showNotification: true,
    );

    setState(() {
      _tasks.putIfAbsent(tag, () => UploadItem(
        id: taskId,
        tag: tag,
        path: video.path,
        type: MediaType.Video,
        status: UploadTaskStatus.enqueued,
      ));
    });
  }

  Future cancelUpload(String id) async {
    await uploader.cancel(taskId: id);
  }


  @override
  void initState() {
    super.initState();
    parentDir = Directory(Common().sDCardDir);
    initPathFiles(Common().sDCardDir);

    _progressSubscription = uploader.progress.listen((progress) {
      final task = _tasks[progress.tag];
      log("progress: ${progress.progress}", tag:progress.tag);
      if (task == null) return;

      setState(() {
        pr.update(progress: progress.progress.toDouble());
        _tasks[progress.tag] = task.copyWith(progress: progress.progress, status: progress.status);
      });

      if (task.isCompleted()) return;
    });

    _resultSubscription = uploader.result.listen((result) {
      log("id: ${result.taskId}, status: ${result.status}, response: ${result.response}, statusCode: ${result.statusCode}, tag: ${result.tag}, headers: ${result.headers}");
      final task = _tasks[result.tag];
      if (task == null) return;
      final responseJson = jsonDecode(result.response);
      setState(() {
        if(result.status.description=="Completed"||result.status.description=="Failed"||result.status.description=="Cancelled"){
          pr.hide().then((isHidden) {
            log(isHidden,tag:"isHidden");
          });
          if(!pr.isShowing()){
            var a=result.status.description;
            if(a=="Completed"){
              Fluttertoast.showToast(msg: 'Completed');
            }
            else if(a=="Failed"){
              Fluttertoast.showToast(msg: 'Failed');
            }
            else if(a=="Cancelled"){
              Fluttertoast.showToast(msg: 'Cancelled');
            }
          }
        }

        _tasks[result.tag] = task.copyWith(
          status: result.status,
          remoteHash: responseJson['md5'],
          remoteSize: responseJson['length'],
        );
      });
    }, onError: (ex, stacktrace) {
      log("exception: $ex");
      log("stacktrace: $stacktrace" ?? "no stacktrace");
      final exp = ex as UploadException;
      final task = _tasks[exp.tag];
      if (task == null) return;
      setState(() {
        _tasks[exp.tag] = task.copyWith(status: exp.status);
      });
    }
    );
  }


  @override
  void dispose() {
    super.dispose();
    _progressSubscription?.cancel();
    _resultSubscription?.cancel();
  }


  static Future<void> pop() async {
    await SystemChannels.platform.invokeMethod('SystemNavigator.pop');
  }

  Future<bool> onWillPop() async {
    if (parentDir.path.replaceAll('/','') != Common().sDCardDir.replaceAll('/','')) {
      initPathFiles(parentDir.parent.path);
      jumpToPosition(false);
    } else {
      if(lastPopTime == null || DateTime.now().difference(lastPopTime) > Duration(seconds: 2)){
        lastPopTime = DateTime.now();
        Fluttertoast.showToast(msg: '再按一次退出');
      }else{
        lastPopTime = null;
        await pop();
      }
      ///SystemNavigator.pop();
    }
    return false;
  }


  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: onWillPop,
      child: Scaffold(
        appBar: PreferredSize(
            child: AppBar(
              centerTitle: true,
              elevation: 0.0,
              backgroundColor: Colors.white,
              bottom: PreferredSize(
                child: Text(Common().mobile_path,
                    style: new TextStyle(fontSize: 7.0,)
                ),
                preferredSize: Size.fromHeight(0.0),
              ),
            ),
            preferredSize: Size.fromHeight(43)
        ),
        body: files.length == 0
            ? Center(child: Text('The folder is empty'))
            : ListView.builder(
          physics: BouncingScrollPhysics(),
          controller: controller,
          itemCount: files.length,
          itemBuilder: (BuildContext context, int index) {
            if (FileSystemEntity.isFileSync(files[index].path))
              return _buildFileItem(context,files[index]);
            else
              return _buildFolderItem(context,files[index]);
          },
        ),
      ),
    );
  }

  Widget _buildFileItem(BuildContext context,FileSystemEntity file) {
    String modifiedTime = DateFormat('yyyy-MM-dd HH:mm:ss', 'zh_CN').format(file.statSync().modified.toLocal());

    return InkWell(
      child: Container(
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(width: 0.5, color: Color(0xffe5e5e5))),
        ),
        child: ListTile(
          leading: Image.asset(Common().selectIcon(p.extension(file.path))),
          title: Text(file.path.substring(file.parent.path.length + 1)),
          subtitle: Text('$modifiedTime  ${Common().getFileSize(file.statSync().size)}', style: TextStyle(fontSize: 8.0)),
        ),
      ),
      onTap: () {
        log("点击事件！$file",tag:"file");
        log(file.path);
        openFile(file.path);
      },
      onLongPress: () {
        showModalBottomSheet(
          context: context,
          builder: (BuildContext context) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                CupertinoButton(
                  pressedOpacity: 0.6,
                  child: Text('重命名', style: TextStyle(color: Color(0xff333333))),
                  onPressed: () {
                    Navigator.pop(context);
                    renameFile(context,file);
                  },
                ),
                Divider(
                  color: Colors.grey,
                ),
                CupertinoButton(
                  pressedOpacity: 0.6,
                  child: Text('删除', style: TextStyle(color: Color(0xff333333))),
                  onPressed: () {
                    Navigator.pop(context);
                    deleteFile(context,file);
                  },
                ),
                Divider(
                color: Colors.grey,
                ),
                CupertinoButton(
                  pressedOpacity: 0.6,
                  child: Text('上传', style: TextStyle(color: Color(0xff333333))),
                  onPressed: () {
                    Navigator.pop(context);
                    upload(context,file);
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildFolderItem(BuildContext context,FileSystemEntity file) {
    String modifiedTime = DateFormat('yyyy-MM-dd HH:mm:ss', 'zh_CN').format(file.statSync().modified.toLocal());

    return InkWell(
      child: Container(
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(width: 0.5, color: Color(0xffe5e5e5))),
        ),
        child: ListTile(
          leading: Image.asset('assets/images/folder.png'),
          title: Row(
            children: <Widget>[
              Expanded(child: Text(file.path.substring(file.parent.path.length + 1))),
              Text(
                '${_calculateFilesCountByFolder(file)}项',
                style: TextStyle(color: Colors.grey),
              )
            ],
          ),
          subtitle: Text(modifiedTime, style: TextStyle(fontSize: 12.0)),
          trailing: Icon(Icons.chevron_right),
        ),
      ),
      onTap: () {
        // 点进一个文件夹，记录进去之前的offset
        // 返回上一层跳回这个offset，再清除该offset
        position.add(controller.offset);
        initPathFiles(file.path);
        jumpToPosition(true);
      },
      onLongPress: () {
        showModalBottomSheet(
          context: context,
          builder: (BuildContext context) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                CupertinoButton(
                  pressedOpacity: 0.6,
                  child: Text('重命名', style: TextStyle(color: Color(0xff333333))),
                  onPressed: () {
                    Navigator.pop(context);
                    renameFile(context,file);
                  },
                ),
                CupertinoButton(
                  pressedOpacity: 0.6,
                  child: Text('删除', style: TextStyle(color: Color(0xff333333))),
                  onPressed: () {
                    Navigator.pop(context);
                    deleteFile(context,file);
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  // 计算以 . 开头的文件、文件夹总数
  int _calculatePointBegin(List<FileSystemEntity> fileList) {
    int count = 0;
    for (var v in fileList) {
      if (p.basename(v.path).substring(0, 1) == '.') count++;
    }
    return count;
  }

  // 计算文件夹内 文件、文件夹的数量，以 . 开头的除外
  int _calculateFilesCountByFolder(Directory path) {
    var dir = path.listSync();
    int count = dir.length - _calculatePointBegin(dir);
    return count;
  }

  void jumpToPosition(bool isEnter) async {
    if (isEnter)
      controller.jumpTo(0.0);
    else {
      try {
        await Future.delayed(Duration(milliseconds: 1));
        controller?.jumpTo(position[position.length - 1]);
      } catch (e) {}
      position.removeLast();
    }
  }

  // 初始化该路径下的文件、文件夹
  void initPathFiles(String path) {
    try {
      setState(() {
        parentDir = Directory(path);
        sortFiles();
      });
    } catch (e) {
      log(e);
      log("Directory does not exist！");
    }
  }

  void deleteFile(BuildContext context,FileSystemEntity file) {
    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: Text('删除'),
          content: Text('删除后不可恢复'),
          actions: <Widget>[
            CupertinoDialogAction(
              child: Text('取消', style: TextStyle(color: Colors.blue)),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            CupertinoDialogAction(
              child: Text('确定', style: TextStyle(color: Colors.blue)),
              onPressed: () {
                if (file.statSync().type == FileSystemEntityType.directory) {
                  Directory directory = Directory(file.path);
                  directory.deleteSync(recursive: true);
                } else if (file.statSync().type == FileSystemEntityType.file) {
                  file.deleteSync();
                }
                initPathFiles(file.parent.path);
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  // 重命名
  void renameFile(BuildContext context,FileSystemEntity file) {
    TextEditingController _controller = TextEditingController(text: p.basename(file.path));
    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(
            child: CupertinoAlertDialog(
              title: Text('重命名'),
              content: Padding(
                padding: EdgeInsets.only(top: 10.0),
                child: TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(2.0)),
                    hintText: '请输入新名称',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(2.0)),
                    contentPadding: EdgeInsets.all(10.0),
                  ),
                ),
              ),
              actions: <Widget>[
                CupertinoDialogAction(
                  child: Text('取消', style: TextStyle(color: Colors.blue)),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
                CupertinoDialogAction(
                  child: Text('确定', style: TextStyle(color: Colors.blue)),
                  onPressed: () async {
                    String newName = _controller.text;
                    if (newName.trim().length == 0) {
                      Fluttertoast.showToast(msg: '名字不能为空', gravity: ToastGravity.CENTER);
                      return;
                    }
                    String newPath = file.parent.path + Platform.pathSeparator + newName;
                    file.renameSync(newPath);
                    initPathFiles(file.parent.path);
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }


  void upload(BuildContext context,FileSystemEntity file) {
    getVideo(file);
    pr = new ProgressDialog(context, type: ProgressDialogType.Download);
    pr.style(
      message: 'Uploading file...',
      borderRadius: 10.0,
      backgroundColor: Colors.white,
      elevation: 10.0,
      insetAnimCurve: Curves.easeInOut,
      progress:0.0,
      maxProgress: 100.0,
      progressTextStyle: TextStyle(
          color: Colors.black, fontSize: 13.0, fontWeight: FontWeight.w400),
      messageTextStyle: TextStyle(
          color: Colors.black, fontSize: 19.0, fontWeight: FontWeight.w600),
    );
    pr.show();

  }

  // 排序
  void sortFiles(){
    List<FileSystemEntity> _files = [];
    List<FileSystemEntity> _folder = [];
    for (var v in parentDir.listSync()) {
      // 去除以 .开头的文件/文件夹
      if (p.basename(v.path).substring(0, 1) == '.') {
        continue;
      }
      if (FileSystemEntity.isFileSync(v.path))
        _files.add(v);
      else
        _folder.add(v);
    }
    _files.sort((a, b) => a.path.toLowerCase().compareTo(b.path.toLowerCase()));
    _folder.sort((a, b) => a.path.toLowerCase().compareTo(b.path.toLowerCase()));
    files.clear();
    files.addAll(_folder);
    files.addAll(_files);
  }

  Future openFile(String path) async {
    final result=await OpenFile.open(path);
    log("type=${result.type}  message=${result.message}");
    ///final Map<String, dynamic> args = <String, dynamic>{'path': path};
    ///await _channel.invokeMethod('openFile', args);
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
