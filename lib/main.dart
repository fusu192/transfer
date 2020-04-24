
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/rendering.dart';
import 'pc.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:path/path.dart' as p;
import 'package:intl/intl.dart';
import 'package:progress_dialog/progress_dialog.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dio/dio.dart';
import 'package:open_file/open_file.dart';
import 'package:path/path.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tip_dialog/tip_dialog.dart';




void log(msg,{tag= "default_tag"}){
  var now =new DateTime.now();
  print("| (time)->"+now.toString()+" | (tag)->$tag  | (msg)->$msg");
}

const String title = "FileUpload Sample app";
String uploadURL = 'http://192.168.199.202:5000';
bool _visible=false;
var tasks={};

String _uploadFilePath = '';
String _uploadProgress = '';

ProgressDialog pr;


enum MediaType { Image, Video,}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FlutterDownloader.initialize();
  Future<void> getSDCardDir() async {
    Common().mobile_path=(await getExternalStorageDirectory()).path+ Platform.pathSeparator + 'Download';
    Common().sDCardDir = (await getExternalStorageDirectory()).path+ Platform.pathSeparator + 'Download';
  }
  // Permission check
  Future<void> getPermission() async {
    if (Platform.isAndroid) {
      PermissionStatus permission = await PermissionHandler().checkPermissionStatus(PermissionGroup.storage);
      if (permission != PermissionStatus.granted) {
        await PermissionHandler().requestPermissions([PermissionGroup.storage]);
      }
      await getSDCardDir();
    } else if (Platform.isIOS) {
      await getSDCardDir();
    }
  }
  Future.wait([initializeDateFormatting("zh_CN", null), getPermission()]).then((result) {
    runApp(mainApp());
  });
}


class mainApp extends StatefulWidget {
  @override
  _mainAppState createState() => _mainAppState();
}

class _mainAppState extends State<mainApp> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LoginPage(),
    );
  }
}




class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {

  GlobalKey<FormState> loginKey = GlobalKey<FormState>();

  String ip;
  String port;
  Response response;
  final TextEditingController controller_ip = new TextEditingController(text: "");
  final TextEditingController controller_port = new TextEditingController(text: "");



  Future connect(BuildContext context,String ip,String port) async{
    BaseOptions options = new BaseOptions(
      baseUrl: "http://$ip:$port",
      connectTimeout: 5000,
      receiveTimeout: 3000,
    );
    Dio dio = new Dio(options);
    response = await dio.get("/login", queryParameters: {});
    if(json.decode(response.toString())["success"]){
      uploadURL="http://$ip:$port";
      TipDialogHelper.dismiss();
      TipDialogHelper.success("Connect Successfully");

      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      await prefs.setString(ip, port);
      Navigator.of(context).pushAndRemoveUntil(
          new MaterialPageRoute(builder: (context) => new MyApp()), (route) => route == null
      );
      return true;
    }else{
      return false;
    }
  }


  init_content()async{
    SharedPreferences prefs = await SharedPreferences.getInstance();
    Set keys = prefs.getKeys();
    if(keys.isNotEmpty){
      for (var key in keys) {
        controller_ip.text=key;
        controller_port.text = prefs.getString(key);
      }
    }
  }

  @override
  void initState() {
    init_content();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('建立连接'),
        centerTitle: true,
      ),
      body:Stack(
        children: <Widget>[
          Column(
            children: <Widget>[
              Container(
                padding: EdgeInsets.all(16),
                child: Form(
                  key: loginKey,
                  autovalidate: true,
                  child: Column(
                    children: <Widget>[
                      TextFormField(
                        controller: controller_ip,
                        decoration: InputDecoration(
                          ///labelText: 'ip',
                          hintText: "例: 192.168.99.2",
                          hintStyle: TextStyle(
                            color: Colors.grey,
                            fontSize: 13,
                          ),
                          ///prefixIcon: Icon(Icons.info),
                        ),
                        onSaved: (value) {
                          ip = value;
                        },
                        onFieldSubmitted: (value) {},
                      ),
                      TextFormField(
                        controller: controller_port,
                        decoration: InputDecoration(
                          ///labelText: 'port',
                          hintText: '例: 5000',
                          hintStyle: TextStyle(
                            color: Colors.grey,
                            fontSize: 13,
                          ),
                          ///prefixIcon: Icon(Icons.lock),
                        ),
                        obscureText: false,
                        onSaved: (value) {
                          port = value;
                        },
                      )
                    ],
                  ),
                  onChanged: () {
                    print("onChanged");
                  },
                ),
              ),
              Container(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: RaisedButton(
                        padding: EdgeInsets.all(15),
                        child: Text(
                          "登录",
                          style: TextStyle(fontSize: 18),
                        ),
                        textColor: Colors.white,
                        color: Theme.of(context).primaryColor,
                        onPressed: () async {
                          TipDialogHelper.loading("Loading");
                          var loginForm = loginKey.currentState;
                          if (loginForm.validate()) {
                            loginForm.save();
                            if(ip=="" && port==""){
                              TipDialogHelper.dismiss();
                              Fluttertoast.showToast(msg: '请输入ip以及port！');
                            }else if(ip=="" && port!=""){
                              TipDialogHelper.dismiss();
                              Fluttertoast.showToast(msg: '请输入ip！');
                            }else if(ip!="" && port==""){
                              TipDialogHelper.dismiss();
                              Fluttertoast.showToast(msg: '请输入port！');
                            }else{
                              try{
                                await connect(context,ip, port);
                              }catch(e){
                                TipDialogHelper.dismiss();
                                Fluttertoast.showToast(msg: '连接失败！');
                              }
                            }
                          }

                        },
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
          TipDialogContainer(
              duration: const Duration(seconds: 1),
              outsideTouchable: true,
              onOutsideTouch: (Widget tipDialog) {
                if (tipDialog is TipDialog &&
                    tipDialog.type == TipDialogType.LOADING) {
                  TipDialogHelper.dismiss();
                }
              })
        ],
      )
    );
  }
}


class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {


    return new MaterialApp(
        title: 'Flutter Demo',
        theme: new ThemeData(
          primarySwatch: Colors.blue,
          fontFamily: 'RobotoMono'
        ),
        home:SliverTabDemoPage2(),
        debugShowCheckedModeBanner: false,
    );
  }
}


final request = new Dio(
    BaseOptions(
        baseUrl: uploadURL,
        connectTimeout: 50000,
        receiveTimeout: 30000
    )
);

void init() {
  request.interceptors.add(InterceptorsWrapper(
      onResponse: (Response response) {
        return response;
      }
  ));
}

Future upload_file(FormData formData, [Function onSendProgress]) async {
  try{
    await request.post(
      '/upload',
      data: formData,
      onSendProgress: onSendProgress,
    ).whenComplete((){

      if(pr.isShowing()){
        pr.hide().then((isHidden) {
          log(isHidden,tag:"isHidden");
        });
      }


      Fluttertoast.showToast(msg: '上传成功！');

      tasks[_uploadFilePath]="complete";
      tasks.forEach((key, value) {
        print('key = $key, value = $value');
      });
    });
  }catch (e) {
    Fluttertoast.showToast(msg: '上传失败！$e');
  }
}


/// 高级版 Sliver Tab
class SliverTabDemoPage2 extends StatefulWidget {
  @override
  _SliverTabDemoPageState createState() => _SliverTabDemoPageState();
}

class _SliverTabDemoPageState extends State<SliverTabDemoPage2> with TickerProviderStateMixin {
  TabController tabController;
  static int cur_index=0;
  final PageController pageController = new PageController();
  final ScrollController scrollController = new ScrollController();
  final int tabLength = 2;
  final double maxHeight = kToolbarHeight;
  final double minHeight = 30;
  final double tabIconSize = 30;

  List<Widget> renderTabs(double shrinkOffset) {
    double offset = (shrinkOffset > tabIconSize) ? tabIconSize : shrinkOffset;
    return [
      Column(
        children: <Widget>[
          Opacity(
            opacity: 1 - offset / tabIconSize,
            child: Icon(
              Icons.mobile_screen_share,
              size: tabIconSize - offset,
            ),
          ),
          new Expanded(
            child: new Center(
              child: new Text(
                "手机",style: TextStyle(fontFamily: 'RobotoMono'),
              ),
            ),
          )
        ],
      ),
      Column(
        children: <Widget>[
          Opacity(
            opacity: 1 - offset / tabIconSize,
            child: Icon(
              Icons.computer,
              size: tabIconSize - offset,
            ),
          ),
          new Expanded(
            child: new Center(
              child: new Text(
                "电脑",style: TextStyle(fontFamily: 'RobotoMono'),
              ),
            ),
          )
        ],
      ),
    ];
  }

  @override
  void initState() {
    tabController = new TabController(length: tabLength, vsync: this);
    super.initState();
  }



  void getFilePath(BuildContext context) async {

    try {
      String filePath = await FilePicker.getFilePath(type: FileType.any);
      log(filePath);
      if (filePath == null) {
        return;
      }
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
      final String savedDir = dirname(filePath);
      final String filename = basename(filePath);

      setState(() {
        _uploadFilePath = filePath;
      });

      log(filename);
      // 调用上传服务
      tasks[_uploadFilePath]="running";

      upload_file(
          FormData.fromMap({
            "file": await MultipartFile.fromFile(_uploadFilePath, filename: filename)
          }),
              (int count, int total) {
            // 设置上传进度
            String progress = ((count / total) * 100).toStringAsFixed(2);
            setState(() {
              _uploadProgress = progress;
              if(pr.isShowing()){
                pr.update(progress: double.parse(progress));
              }
            });
          }
      );
    } catch (e) {
      print("Error while picking the file: " + e.toString());
      Fluttertoast.showToast(msg: '上传失败！${e.toString()}');
    }

  }


  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: new Text("文件互传",style: TextStyle(fontFamily: 'RobotoMono'),

        ),
        centerTitle: true,
        leading: _visible?IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            setState(() {
              _visible = !_visible;
            });
          },
        ):SizedBox(),
        actions: <Widget>[
          1==0?IconButton(
            icon: Icon(Icons.file_upload),
            onPressed: () {
              setState(() {
                _visible = !_visible;
              });
            },
          ):SizedBox(),
          cur_index==0?IconButton(
            tooltip: "选择要上传的文件！",
            icon: Icon(Icons.add),
            onPressed: () {
              getFilePath(context);
            },
          ):SizedBox(),
        ],
      ),
      body: NestedScrollView(
        controller: scrollController,
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return <Widget>[
            SliverOverlapAbsorber(
              handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
              sliver: SliverPersistentHeader(
                pinned: true,
                delegate: GSYSliverHeaderDelegate(
                    maxHeight: maxHeight,
                    minHeight: minHeight,
                    changeSize: true,
                    snapConfig: FloatingHeaderSnapConfiguration(
                      vsync: this,
                      curve: Curves.bounceInOut,
                      duration: const Duration(milliseconds: 10),
                    ),
                    builder: (BuildContext context, double shrinkOffset, bool overlapsContent) {
                      return Container(
                        height: maxHeight,
                        color: Colors.blue,
                        child: TabBar(
                          controller: tabController,
                          indicatorColor: Colors.cyanAccent,
                          unselectedLabelColor: Colors.white.withAlpha(100),
                          labelColor: Colors.cyanAccent,
                          tabs: renderTabs(shrinkOffset),
                          onTap: (index) {
                            print(index);
                            setState(() {});
                            scrollController.animateTo(0,
                                duration: Duration(milliseconds: 100),
                                curve: Curves.fastOutSlowIn);
                            pageController.jumpToPage(index);
                          },
                        ),
                      );
                    }
                ),
              ),
            )
          ];
        },
        body: PageView(
          onPageChanged: (index) {
            setState(() {
              _visible=false;
              cur_index=index;
            });
            tabController.animateTo(index);
          },
          controller: pageController,
          children: List.generate(tabLength, (index) {
            return _visible?Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  Text('文件路径：$_uploadFilePath'),
                  Text('上传进度：$_uploadProgress')
                ],
              ),
            ):(index==0)
                ?FileManager()
                : MyHomePage(
                  burl:uploadURL ,
                  title: 'Downloader',
                  platform: Theme.of(context).platform,
              );
          }),
        ),
      ),
    );
  }
}

///动态头部处理
class GSYSliverHeaderDelegate extends SliverPersistentHeaderDelegate {
  GSYSliverHeaderDelegate({@required this.minHeight,
        @required this.maxHeight,
        @required this.snapConfig,
        this.child,
        this.builder,
        this.changeSize = false});

  final double minHeight;
  final double maxHeight;
  final Widget child;
  final BuilderDelegate builder;
  final bool changeSize;
  final FloatingHeaderSnapConfiguration snapConfig;
  AnimationController animationController;

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => math.max(maxHeight, minHeight);

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    if (builder != null) {
      return builder(context, shrinkOffset, overlapsContent);
    }
    return child;
  }

  @override
  bool shouldRebuild(GSYSliverHeaderDelegate oldDelegate) {
    return true;
  }

  @override
  FloatingHeaderSnapConfiguration get snapConfiguration => snapConfig;
}

typedef Widget BuilderDelegate(
    BuildContext context, double shrinkOffset, bool overlapsContent);



class FileManager extends StatefulWidget {
  @override
  _FileManagerState createState() => _FileManagerState();
}

class _FileManagerState extends State<FileManager> {

  List<FileSystemEntity> files = [];
  MethodChannel _channel = MethodChannel('openFileChannel');
  Directory parentDir;
  ScrollController controller = ScrollController();
  List<double> position = [];

  DateTime lastPopTime;
  double percentage = 0.0;

  @override
  void initState() {
    super.initState();
    parentDir = Directory(Common().sDCardDir);
    initPathFiles(Common().sDCardDir);
  }


  @override
  void dispose() {
    super.dispose();
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
        body: (files.length == 0
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
        )),
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
                  child: Text('上传', style: TextStyle(color: Color(0xff333333))),
                  onPressed: () {
                    Navigator.pop(context);
                    upload(context,file);
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
                  child: Text('重命名', style: TextStyle(color: Color(0xff333333))),
                  onPressed: () {
                    Navigator.pop(context);
                    renameFile(context,file);
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
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(''),
          content: Text('是否删除${p.basename(file.path)}？',overflow: TextOverflow.clip),
          actions: <Widget>[
            FlatButton(
              child: Text('确认'),
              onPressed: () {
                if (file.statSync().type == FileSystemEntityType.directory) {
                  Directory directory = Directory(file.path);
                  directory.deleteSync(recursive: true);
                } else if (file.statSync().type == FileSystemEntityType.file) {
                  file.deleteSync();
                }
                initPathFiles(file.parent.path);
                Navigator.pop(context);
                Fluttertoast.showToast(msg: '删除成功！',toastLength: Toast.LENGTH_SHORT);
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
                    Fluttertoast.showToast(msg: '修改成功！');
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }


  void upload(BuildContext context,FileSystemEntity file) async{
    final String savedDir = dirname(file.path);
    final String filename = basename(file.path);

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
    try {
      setState(() {
        _uploadFilePath = file.path;
      });
      // 调用上传服务
      tasks[_uploadFilePath]="running";

      upload_file(
          FormData.fromMap({
            "file": await MultipartFile.fromFile(_uploadFilePath, filename: filename)
          }),
              (int count, int total) {
            String progress = ((count / total) * 100).toStringAsFixed(2);
            setState(() {
              _uploadProgress = progress;
              if(pr.isShowing()){
                pr.update(progress: double.parse(progress));
              }
            });
          }
      );
    } catch (e) {
      print("Error while picking the file: " + e.toString());
      Fluttertoast.showToast(msg: '上传失败！${e.toString()}');
    }
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
    ///_files.sort((a, b) => a.path.toLowerCase().compareTo(b.path.toLowerCase()));
    _files.sort((a, b) => (b.statSync().modified.toLocal().millisecondsSinceEpoch).compareTo(a.statSync().modified.toLocal().millisecondsSinceEpoch));
    ///_folder.sort((a, b) => a.path.toLowerCase().compareTo(b.path.toLowerCase()));
    _folder.sort((a, b) => (b.statSync().modified.toLocal().millisecondsSinceEpoch).compareTo(a.statSync().modified.toLocal().millisecondsSinceEpoch));

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




