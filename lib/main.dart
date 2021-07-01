import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:logger/logger.dart';
import 'package:permission_handler/permission_handler.dart';

import 'image_list.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Camera',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: CameraIndex(),
    );
  }
}

class CameraIndex extends StatefulWidget {
  CameraIndex({Key? key}) : super(key: key);

  @override
  _CameraIndexState createState() => _CameraIndexState();
}

class _CameraIndexState extends State<CameraIndex>  with WidgetsBindingObserver, TickerProviderStateMixin {
  var logger = Logger();

  late Future<bool> _camerasFuture;
  //可用的相机
  List<CameraDescription> _cameras = [];

  //当前使用的摄像机
  late CameraDescription _useCameras;
  //相机的controller
  CameraController? controller;

  //拍摄的照片
  List<XFile> imageFile = [];

  var scale = 1.0;


  ///闪光灯按钮动画效果
  late AnimationController _flashModeControlRowAnimationController;
  late Animation<double> _flashModeControlRowAnimation;

  @override
  void initState() {
    setState(() {
      _flashModeControlRowAnimationController = AnimationController(
        duration: const Duration(milliseconds: 300),
        vsync: this,
      );

      _flashModeControlRowAnimation = CurvedAnimation(
        parent: _flashModeControlRowAnimationController,
        curve: Curves.easeInCubic,
      );
    });

    //初始化摄像头
    _camerasFuture = initCameras();


    super.initState();
  }



  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        centerTitle: true,
        title: Text("Camera"),
        actions: [
          IconButton(
              onPressed: onFlashModeButtonPressed,
              icon: Icon(_flashModeIcon())
          )
        ],
      ),
      body: SafeArea(
        bottom: true,
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: FutureBuilder(
                    future: _camerasFuture,
                    builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
                      if(snapshot.connectionState == ConnectionState.waiting){
                        return  Text("正在查找可用的摄像头");
                      }
                      if( snapshot.connectionState == ConnectionState.done){
                        if(controller?.value.isInitialized??false){
                          return  Transform.scale(
                            scale: scale,
                            child: Center(
                              child: CameraPreview(controller!),
                            ),
                          );
                        }else{
                          return Text("没有可用的摄像头");
                        }
                      }else{
                        return Text("没有可用的摄像头");
                      }
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      ImageWidget(),
                      IconButton(
                        splashRadius:50,
                        iconSize: 80,
                        icon: const Icon(Icons.camera,color: Colors.white,),
                        onPressed: controller != null &&
                            controller!.value.isInitialized &&
                            !controller!.value.isRecordingVideo
                            ? onTakePictureButtonPressed
                            : null,
                      ),
                      IconButton(
                        iconSize: 30,
                        icon: const Icon(Icons.flip_camera_android_outlined,color: Colors.white,),
                        onPressed: controller != null &&
                            controller!.value.isInitialized &&
                            !controller!.value.isRecordingVideo
                            ? changeCamera
                            : null,)
                    ],
                  ),
                )
              ],
            ),
            Positioned(
              top: 0,
              left: 0,
              child: _flashModeControlRowWidget()
            ),
          ],
        ),
      ),
    );
  }


  ///闪光灯操作按钮
  Widget _flashModeControlRowWidget() {
    return SizeTransition(
      sizeFactor: _flashModeControlRowAnimation,
      child: Container(
        width: MediaQuery.of(context).size.width,
        color: Colors.black26,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          mainAxisSize: MainAxisSize.max,
          children: [
            IconButton(
              disabledColor: Colors.white24,
              icon: Icon(Icons.flash_off),
              color: controller?.value.flashMode == FlashMode.off
                  ? Colors.orange
                  : Colors.white,
              onPressed: controller != null
                  ? () => onSetFlashModeButtonPressed(FlashMode.off)
                  : null,
            ),
            IconButton(
              disabledColor: Colors.white24,
              icon: Icon(Icons.flash_auto),
              color: controller?.value.flashMode == FlashMode.auto
                  ? Colors.orange
                  : Colors.white,
              onPressed: controller != null
                  ? () => onSetFlashModeButtonPressed(FlashMode.auto)
                  : null,
            ),
            IconButton(
              disabledColor: Colors.white24,
              icon: Icon(Icons.flash_on),
              color: controller?.value.flashMode == FlashMode.always
                  ? Colors.orange
                  : Colors.white,
              onPressed: controller != null
                  ? () => onSetFlashModeButtonPressed(FlashMode.always)
                  : null,
            ),
            IconButton(
              disabledColor: Colors.white24,
              icon: Icon(Icons.highlight),
              color: controller?.value.flashMode == FlashMode.torch
                  ? Colors.orange
                  : Colors.white,
              onPressed: controller != null
                  ? () => onSetFlashModeButtonPressed(FlashMode.torch)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  _flashModeIcon(){
    if(controller?.value.flashMode == FlashMode.off){
      return Icons.flash_off;
    }
    if(controller?.value.flashMode == FlashMode.auto){
      return Icons.flash_auto;
    }
    if(controller?.value.flashMode == FlashMode.always){
      return Icons.flash_on;
    }
    if(controller?.value.flashMode == FlashMode.torch){
      return Icons.highlight;
    }
    return Icons.flash_on_sharp;
  }

  ///闪光灯动画
  void onFlashModeButtonPressed() {
    if (_flashModeControlRowAnimationController.value == 1) {
      _flashModeControlRowAnimationController.reverse();
    } else {
      _flashModeControlRowAnimationController.forward();
    }
  }

  ///获取可用的摄像头并初始化第一个
  Future<bool> initCameras() async {
    var status = await Permission.camera.request();

    if(!status.isGranted){
      showToast("需要摄像机权限");
      return false ;
    }

    _cameras = await  availableCameras();
    await onNewCameraSelected(_cameras.first);
    ///解决图像拉伸问题
    var camera = controller!.value;
    final size = MediaQuery.of(context).size;
    var scale = size.aspectRatio * camera.aspectRatio;
    setState(() {
      if (scale < 1) scale = 1 / scale;
    });
    return true;
  }

  ///切换摄像头
  Future<bool> onNewCameraSelected(CameraDescription cameraDescription) async {
    if (controller != null) {
      await controller!.dispose();
    }
    final CameraController cameraController = CameraController(
      cameraDescription,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.bgra8888,
    );
    controller = cameraController;

    cameraController.addListener(() {
      if (mounted) setState(() {});
      if (cameraController.value.hasError) {
        showToast('Camera error ${cameraController.value.errorDescription}');
      }
    });

    try {
      await cameraController.initialize();
      _useCameras = cameraDescription;
      if (mounted) {
        setState(() {});
      }
      return true;
    } on CameraException catch (e) {
      logger.e(e);

      if(e.code == "cameraPermission"){
        showToast("需要摄像机权限");
      }else{
        showToast(e.description.toString());
      }
      return false;
    }
  }
  /// 切换摄像头
  void changeCamera() {
    for(int i =0;i<_cameras.length; i++){
      if(_cameras[i].name != _useCameras.name){
        onNewCameraSelected(_cameras[i]);
        return;
      }
      if(i == _cameras.length){
        onNewCameraSelected(_cameras[0]);
      }
    }
  }

  ///拍照
  void onTakePictureButtonPressed() {
    takePicture().then((XFile? file) {
      if (mounted) {
        imageFile.add(file!);
        setState(() {});
      }
    });
  }

  ///改变闪光灯模式
  void onSetFlashModeButtonPressed(FlashMode mode) {
    if(!controller!.value.isInitialized){
      showToast("摄像机未初始化");
      return;
    }
    setFlashMode(mode).then((_) {
      if (mounted) setState(() {});
      showToast('闪光灯切换为 ${mode.toString().split('.').last}');
    });
  }

  ///提示信息
  void showToast(String message) {
    Fluttertoast.showToast(
        msg: message,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0);
  }

  ///保存图片
  Future<XFile?> takePicture() async {
    final CameraController? cameraController = controller;
    if (cameraController == null || !cameraController.value.isInitialized) {
      showToast('先选择一个摄像头');
      return null;
    }

    if (cameraController.value.isTakingPicture) {
      return null;
    }

    try {
      XFile file = await cameraController.takePicture();
      return file;
    } on CameraException catch (e) {
      logger.e(e.description, e);
      return null;
    }
  }

  ///改变闪光灯模式
  Future<void> setFlashMode(FlashMode mode) async {
    if (controller == null) {
      return;
    }
    try {
      await controller!.setFlashMode(mode);
    } on CameraException catch (e) {
      logger.e(e.description, e);
      showToast(e.description.toString());
      rethrow;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = controller;

    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }
    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      onNewCameraSelected(cameraController.description);
    }
  }

  @override
  void dispose() {
    _flashModeControlRowAnimationController.dispose();
    super.dispose();
  }

  ImageWidget() {
    if( imageFile.length > 0 ){
    return  GestureDetector(
      onTap: (){
        Navigator.of(context).push(MaterialPageRoute(builder: (context) => ImageList(files: imageFile,),));
      },
      child: Container(
          constraints: BoxConstraints(
            maxWidth: 70,maxHeight: 100,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            image: DecorationImage(
               image: Image.file(File(imageFile.last.path)).image,
              fit: BoxFit.fitHeight
            )
          ),
        ),
    );
    }else{
      return Icon(Icons.photo,color: Colors.white,);
    }
  }
}



