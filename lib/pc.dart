
import 'package:dio/dio.dart';
import 'dart:isolate';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter_easyrefresh/easy_refresh.dart';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:progress_dialog/progress_dialog.dart';
import 'package:path/path.dart' as p;

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
      case '.apk':
        iconImg = 'assets/images/apk.png';
        break;
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
      case '.csv':
        iconImg = 'assets/images/excel.png';
        break;
      case '.tif':
      case '.jpeg':
      case '.png':
      case '.webp':
      case '.gif':
      case '.jpg':
      case '.bmp':
      case '.pcx':
      case '.tga':
      case '.exif':
      case '.fpx':
      case '.svg':
      case '.psd':
      case '.cdr':
      case '.pcd':
      case '.dxf':
      case '.ufo':
      case '.eps':
      case '.ai':
      case '.raw':
      case '.wmf':
        iconImg = 'assets/images/image.png';
        break;
      case '.pdf':
        iconImg = 'assets/images/pdf.png';
        break;
      case '.py':
      case '.pyc':
      case '.pyw':
      case '.pyo':
      case '.pyd':
        iconImg = 'assets/images/python.png';
        break;
      case '.java':
      case '.class':
        iconImg = 'assets/images/java.png';
        break;
      case '.sh':
        iconImg = 'assets/images/shell.png';
        break;
      case '.yaml':
        iconImg = 'assets/images/yaml.png';
        break;
      case '.txt':
        iconImg = 'assets/images/txt.png';
        break;
      case '.bin':
        iconImg = 'assets/images/bin.png';
        break;
      case '.js':
        iconImg = 'assets/images/js.png';
        break;
      case '.css':
        iconImg = 'assets/images/css.png';
        break;
      case '.html':
        iconImg = 'assets/images/html.png';
        break;
      case '.mp1':
      case '.mp2':
      case '.mp3':
      case '.cda':
      case '.wav':
      case '.wma':
      case '.aac':
      case '.flac':
      case '.ape':
      case '.amr':
      case '.ogg':
      case '.vqf':
      case '.mid':
      case '.aif':
      case '.aiff':
      case '.au':
      case '.voc':
      case '.ra':
      case '.rm':
      case '.ram':
      case '.mod':
      case '.s3m':
      case '.xm':
      case '.mtm':
      case '.far':
      case '.kar':
      case '.it':
        iconImg = 'assets/images/mp3.png';
        break;
      case '.mp4':
      case '.wmv':
      case '.asf':
      case '.asx':
      case '.3gp':
      case '.mov':
      case '.m4v':
      case '.rm':
      case '.rmvb':
      case '.avi':
      case '.dat':
      case '.mkv':
      case '.flv':
      case '.vob':
        iconImg = 'assets/images/mp4.png';
        break;
      case '.rar':
      case '.zip':
      case '.tar.xz':
      case '.tar.bz2':
      case '.tar.gz':
      case '.tar':
      case '.xz':
      case '.bz2':
      case '.gz':
      case '.z':
      case '.cab':
      case '.arj':
      case '.lzh':
      case '.ace':
      case '.7-zip':
      case '.gzip':
      case '.uue':
      case '.bz2':
      case '.jar':
      case '.iso':
        iconImg = 'assets/images/zip.png';
        break;
      default:
        iconImg = 'assets/images/file.png';
        break;
    }
    return iconImg;
  }
}

void log(msg,{tag= "default_tag"}){
  var now =new DateTime.now();
  print("| (time)->"+now.toString()+" | (tag)->$tag  | (msg)->$msg");
}

class MyHomePage extends StatefulWidget with WidgetsBindingObserver {
  final TargetPlatform platform;
  final String title;
  final String burl;

  MyHomePage({Key key, this.burl,this.title, this.platform}) : super(key: key);
  @override
  _MyHomePageState createState() => new _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  ProgressDialog pr;

  EasyRefreshController _controller;
  ScrollController _scrollController;
  // 条目总数
  int _page = 1;
  int _per_page=60;
  // 反向
  bool _reverse = false;
  // 方向
  Axis _direction = Axis.vertical;
  // Header浮动
  bool _headerFloat = false;
  // 无限加载
  bool _enableInfiniteLoad = true;
  // 控制结束
  bool _enableControlFinish = false;
  // 任务独立
  bool _taskIndependence = false;
  // 震动
  bool _vibration = false;
  // 是否开启刷新
  bool _enableRefresh = true;
  // 是否开启加载
  bool _enableLoad = true;
  // 顶部回弹
  bool _topBouncing = true;
  // 底部回弹
  bool _bottomBouncing = true;
  List<_TaskInfo> _tasks=[];
  List<_ItemHolder> _items=[];
  bool _isLoading;
  bool _permissionReady;
  String _localPath;
  ReceivePort _port = ReceivePort();
  String _curdir="";
  int this_page_data_num=1;
  int plus_num=0;
  int _total_page=15;
  String baseurl="";



  @override
  void initState() {
    super.initState();
    baseurl="${widget.burl}";
    _controller = EasyRefreshController();
    _scrollController = ScrollController();

    _bindBackgroundIsolate();
    FlutterDownloader.registerCallback(downloadCallback);
    _isLoading = true;
    _permissionReady = false;
    _prepare();
  }

  @override
  void dispose() {
    _unbindBackgroundIsolate();
    super.dispose();
  }

  void _bindBackgroundIsolate() {
    bool isSuccess = IsolateNameServer.registerPortWithName(_port.sendPort, 'downloader_send_port');
    if (!isSuccess) {
      _unbindBackgroundIsolate();
      _bindBackgroundIsolate();
      return;
    }
    _port.listen((dynamic data) {
      print('UI Isolate Callback: $data');
      String id = data[0];
      DownloadTaskStatus status = data[1];
      int progress = data[2];

      final task = _tasks?.firstWhere((task) => task.taskId == id);
      if (task != null) {
        setState(() {
          task.status = status;
          task.progress = progress;
        });
      }
    });
  }

  void _unbindBackgroundIsolate() {
    IsolateNameServer.removePortNameMapping('downloader_send_port');
  }


  DateTime lastPopTime;

  static Future<void> pop() async {
    await SystemChannels.platform.invokeMethod('SystemNavigator.pop');
  }

  Future<bool> onWillPop() async {
      if(lastPopTime == null || DateTime.now().difference(lastPopTime) > Duration(seconds: 2)){
        lastPopTime = DateTime.now();
        Fluttertoast.showToast(msg: '再按一次退出');
      }else{
        lastPopTime = null;
        await pop();
      }
      ///SystemNavigator.pop();
    return false;
  }

  static void downloadCallback(String id, DownloadTaskStatus status, int progress) {
    print('Background Isolate Callback: task ($id) is in status ($status) and process ($progress)');
    final SendPort send = IsolateNameServer.lookupPortByName('downloader_send_port');
    send.send([id, status, progress]);
  }

  void renameFile(BuildContext context,String filename,int index) {
    TextEditingController _controller = TextEditingController(text: filename);
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

                    BaseOptions options = new BaseOptions(
                      baseUrl: baseurl,
                      connectTimeout: 5000,
                      receiveTimeout: 3000,
                    );
                    Dio dio = new Dio(options);
                    response = await dio.put("/rename/$filename/$newName", queryParameters: {});

                    Navigator.pop(context);

                    if(response.data["success"]){
                      setState(() {
                        _items[index].name=newName;
                      });
                      Fluttertoast.showToast(msg: '修改成功！');
                    }else{
                      Fluttertoast.showToast(msg: '修改失败！${response.data["msg"]}');
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future download1(Dio dio, String url, savePath) async {
    CancelToken cancelToken = CancelToken();
    try {
      await dio.download(url, savePath, onReceiveProgress: showDownloadProgress, cancelToken: cancelToken).whenComplete((){
        Fluttertoast.showToast(msg: '下载成功！');
        if(pr.isShowing()){
          pr.hide().then((isHidden) {
            log(isHidden,tag:"isHidden");
          });
        }
      });
    } catch (e) {
      Fluttertoast.showToast(msg: '下载失败！$e');
    }
  }

  downloadFile(BuildContext context,String filename,int index) async{
    try{
      var dio = Dio();
      dio.interceptors.add(LogInterceptor());
      _localPath = (await _findLocalPath()) + Platform.pathSeparator + 'Download';
      String url=baseurl+"/download/"+filename;

      pr = new ProgressDialog(context, type: ProgressDialogType.Download);
      pr.style(
        message: 'Downloading file...',
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
      await download1(dio, url, _localPath+Platform.pathSeparator + filename);
    }
    catch (e) {
      Fluttertoast.showToast(msg: '下载失败！$e');
    }
  }

  void showDownloadProgress(received, total) {
    if (total != -1) {
      if(pr.isShowing()){
        pr.update(progress: double.parse((received / total * 100).toStringAsFixed(2)));
      }
    }
  }


  Response response;
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: onWillPop,
        child: new Scaffold(
          appBar: PreferredSize(
              child: AppBar(
                centerTitle: true,
                elevation: 0.0,
                backgroundColor: Colors.white,
                bottom: PreferredSize(
                  child: Text(_curdir,
                      style:new TextStyle(fontSize: 7.0,)
                  ),
                  preferredSize: Size.fromHeight(0.0),
                ),
              ),
              preferredSize: Size.fromHeight(43)
          ),
          body: _isLoading
              ?new Center(
                  child: new CircularProgressIndicator(),
              )
              :_permissionReady
              ?Center(
                child: Container(
                  height: _direction == Axis.vertical ? double.infinity : 210.0,
                  child: EasyRefresh.custom(
                  enableControlFinishRefresh: true,
                  enableControlFinishLoad: true,
                  taskIndependence: _taskIndependence,
                  controller: _controller,
                  scrollController: _scrollController,
                  reverse: _reverse,
                  scrollDirection: _direction,
                  topBouncing: _topBouncing,
                  bottomBouncing: _bottomBouncing,
                  header: ClassicalHeader(
                    enableInfiniteRefresh: false,
                    bgColor: _headerFloat ? Theme.of(context).primaryColor : null,
                    infoColor: _headerFloat ? Colors.black87 : Colors.teal,
                    float: _headerFloat,
                    enableHapticFeedback: _vibration,
                  ),
                  footer: ClassicalFooter(
                    enableInfiniteLoad: _enableInfiniteLoad,
                    enableHapticFeedback: _vibration,
                  ),
                  onRefresh: _enableRefresh
                      ? () async {
                    await Future.delayed(Duration(seconds: 2), () {
                      _isLoading=true;
                      _tasks=[];
                      _items=[];
                      plus_num=0;
                      _page = 1;

                      if (mounted) {
                        setState(() {
                        });
                        _prepare();
                        if (!_enableControlFinish) {
                          _controller.resetLoadState();
                          _controller.finishRefresh(success:true);
                        }
                      }
                    });
                  }
                      : null,
                  onLoad: _enableLoad
                      ? () async {
                    await Future.delayed(Duration(seconds: 2), () {
                      if (mounted) {
                        setState(() {
                          _page += 1;
                        });
                        _prepare();
                        if (!_enableControlFinish) {
                          _controller.finishLoad(success:true,noMore: _page>_total_page);
                        }
                      }
                    });
                  }
                      : null,
                  slivers: <Widget>[
                      SliverList(
                      delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              var item=_items[index];
                          return item.task == null
                              ? new Container(
                                padding: const EdgeInsets.symmetric(
                                horizontal: 16.0, vertical: 8.0
                                ),
                                child: Text(
                                  item.name,
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue,
                                      fontSize: 18.0
                                  ),
                                ),
                              )
                              : new Container(
                                padding: const EdgeInsets.only(
                                  left: 16.0, right: 8.0
                                ),
                                child: InkWell(
                                  onTap: item.task.status == DownloadTaskStatus.complete
                                  ? () {
                                    _openDownloadedFile(item.task).then((success) {
                                      if (!success) {
                                        Scaffold.of(context).showSnackBar(
                                          SnackBar(
                                              content: Text('Cannot open this file')
                                          )
                                        );
                                      }
                                    });
                                  }
                                  : null,
                                  onLongPress: (){
                                    showModalBottomSheet(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: <Widget>[
                                            CupertinoButton(
                                              pressedOpacity: 0.6,
                                              child: Text('下载', style: TextStyle(color: Color(0xff333333))),
                                              onPressed: () {
                                                Navigator.pop(context);
                                                downloadFile(context,item.name,index);
                                              },
                                            ),
                                            Divider(
                                              color: Colors.grey,
                                            ),
                                            CupertinoButton(
                                              pressedOpacity: 0.6,
                                              child: Text('删除', style: TextStyle(color: Color(0xff333333))),
                                              onPressed: () async{
                                                BaseOptions options = new BaseOptions(
                                                  baseUrl: baseurl,
                                                  connectTimeout: 5000,
                                                  receiveTimeout: 3000,
                                                );
                                                Dio dio = new Dio(options);
                                                response = await dio.delete("/del/${item.name}", queryParameters: {});

                                                Navigator.pop(context);
                                                showDialog(
                                                  barrierDismissible: false,
                                                  context: context,
                                                  builder: (BuildContext context) {
                                                    return AlertDialog(
                                                      title: Text(''),
                                                      content: Text('是否删除${item.name}？',overflow: TextOverflow.clip),
                                                      actions: <Widget>[
                                                        FlatButton(
                                                          child: Text('确认'),
                                                          onPressed: () {
                                                            if(response.data["success"]){
                                                              setState(() {
                                                                _items.removeAt(index);
                                                              });
                                                              Fluttertoast.showToast(msg: '删除成功！',toastLength: Toast.LENGTH_SHORT);
                                                            }else{
                                                              Fluttertoast.showToast(msg: '删除失败！${response.data["msg"]}',toastLength: Toast.LENGTH_SHORT);
                                                            }
                                                            Navigator.pop(context);
                                                          },
                                                        ),
                                                        FlatButton(
                                                          child: Text('取消'),
                                                          onPressed: () {
                                                            Navigator.pop(context);
                                                          },
                                                        ),
                                                      ],
                                                    );
                                                  },
                                                );
                                              },
                                            ),
                                            Divider(
                                              color: Colors.grey,
                                            ),
                                            CupertinoButton(
                                              pressedOpacity: 0.6,
                                              child: Text('重命名', style: TextStyle(color: Color(0xff333333))),
                                              onPressed: () {
                                                Navigator.pop(context);
                                                renameFile(context,item.name,index);
                                              },
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  },
                                  child: new Stack(
                                    children: <Widget>[
                                      new Container(
                                        width: double.infinity,
                                        height: 60.0,
                                        child: new Row(
                                          crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                          children: <Widget>[
                                            Image.asset(Common().selectIcon(p.extension(item.name))),
                                            new Expanded(
                                              child: new Text(
                                                item.name,
                                                maxLines: 1,
                                                softWrap: true,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ].where((child) => child != null).toList(),
                                  ),
                                ),
                              );
                            },
                        childCount: _items.length,
                      ),
                    ),
                  ]
                ),
              ),
          ):new Container(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Padding(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Text('Please grant accessing storage permission to continue -_-',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Colors.blueGrey, fontSize: 18.0
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 32.0,
                  ),
                  FlatButton(
                      onPressed: () {
                        _checkPermission().then((hasGranted) {
                          setState(() {
                            _permissionReady = hasGranted;
                          });
                        });
                      },
                      child: Text(
                        'Retry',
                        style: TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                            fontSize: 20.0
                        ),
                      )
                  )
                ],
              ),
            ),
          ),
          persistentFooterButtons: <Widget>[
            _enableControlFinish
                ? FlatButton(
                onPressed: () {
                  _controller.resetLoadState();
                  _controller.finishRefresh();
                },
                child: Text("完成刷新", style: TextStyle(color: Colors.black)
                )
            )
                : SizedBox(
              width: 0.0,
              height: 0.0,
            ),
            _enableControlFinish
                ? FlatButton(
                onPressed: () {
                  _controller.finishLoad(noMore: _page<=_total_page);
                },
                child: Text("完成加载", style: TextStyle(color: Colors.black)
                )
            )
                : SizedBox(
              width: 0.0,
              height: 0.0,
            ),
          ],
        )
    );
  }



  Future<bool> _openDownloadedFile(_TaskInfo task) {
    return FlutterDownloader.open(taskId: task.taskId);
  }


  Future<bool> _checkPermission() async {
    if (widget.platform == TargetPlatform.android) {
      PermissionStatus permission = await PermissionHandler().checkPermissionStatus(PermissionGroup.storage);
      if (permission != PermissionStatus.granted) {
        Map<PermissionGroup, PermissionStatus> permissions = await PermissionHandler().requestPermissions([PermissionGroup.storage]);
        if (permissions[PermissionGroup.storage] == PermissionStatus.granted) {
          return true;
        }
      } else {
        return true;
      }
    } else {
      return true;
    }
    return false;
  }

  Future<Null> _prepare() async {
    final tasks = await FlutterDownloader.loadTasks();
    Response response;

    BaseOptions options = new BaseOptions(
      baseUrl: baseurl,
      connectTimeout: 5000,
      receiveTimeout: 3000,
    );
    Dio dio = new Dio(options);
    response = await dio.get("/four/"+_page.toString()+"/"+_per_page.toString(), queryParameters: {});

    if (response.statusCode == HttpStatus.ok) {
      var temp= json.decode(response.toString())['data'];

      this_page_data_num=json.decode(response.toString())["this_page_data_num"];

      temp?.forEach((name){
        _tasks.add(_TaskInfo(name: name['name'], link: name['link']+Uri.encodeComponent(name['name'])));
        _items.add(_ItemHolder(name: name['name'], task: _tasks[plus_num]));
        plus_num++;
      });

      _curdir=json.decode(response.toString())["cur_dir"];
      _total_page=json.decode(response.toString())["total_page"];

    } else {
      log('Error');
    }

    tasks?.forEach((task) {
      for (_TaskInfo info in _tasks) {
        if (info.link == task.url) {
          info.taskId = task.taskId;
          info.status = task.status;
          info.progress = task.progress;
        }
      }
    });

    _permissionReady = await _checkPermission();
    _localPath = (await _findLocalPath()) + Platform.pathSeparator + 'Download';

    final savedDir = Directory(_localPath);
    bool hasExisted = await savedDir.exists();
    if (!hasExisted) {
      savedDir.create();
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<String> _findLocalPath() async {
    final directory = widget.platform == TargetPlatform.android
        ? await getExternalStorageDirectory()
        : await getApplicationDocumentsDirectory();
    return directory.path;
  }
}

class _TaskInfo {
  final String name;
  final String link;

  String taskId;
  int progress = 0;
  DownloadTaskStatus status = DownloadTaskStatus.undefined;

  _TaskInfo({this.name, this.link});
}

class _ItemHolder {
  String name;
  final _TaskInfo task;

  _ItemHolder({this.name, this.task});
}