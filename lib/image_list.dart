import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

class ImageList extends StatefulWidget {
  ImageList({Key? key, required this.files}) : super(key: key);

  final List<XFile> files;

  @override
  State<StatefulWidget> createState() {
    return ImageListState();
  }
}

class ImageListState extends State<ImageList> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: Text("Images"),
        ),
        body: GridView(
          padding: EdgeInsets.all(8),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 3/4,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10
          ),
          children: widget.files.map((e) {
            return  GestureDetector(
              onTap: (){
                showGeneralDialog(
                  barrierDismissible: false,
                  barrierLabel: "1122",
                  context: context,
                  pageBuilder: (BuildContext context, Animation animation, Animation secondaryAnimation) {
                    return GestureDetector(
                      onTap: (){
                        Navigator.pop(context);
                      },
                      child: PhotoViewGallery.builder(
                        scrollPhysics: const BouncingScrollPhysics(),
                        builder: (BuildContext context, int index) {
                          return PhotoViewGalleryPageOptions(
                            imageProvider: Image.file(File(widget.files[index].path)).image,
                            initialScale: PhotoViewComputedScale.contained * 0.8,
                            heroAttributes: PhotoViewHeroAttributes(tag: widget.files[index].path),

                          );
                        },
                        itemCount: widget.files.length,
                        backgroundDecoration: BoxDecoration(
                          color: Colors.white
                        ),
                      ),
                    );
                  },transitionBuilder: (_, anim, __, child) {
                  return ScaleTransition(
                    scale: anim,
                    child: child,
                  );
                },
                );

              },
              child: Container(
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    image: DecorationImage(
                        image: Image.file(File(e.path)).image,
                        fit: BoxFit.fitWidth
                    )
                ),
              ),
            );
          }).toList(),
        )
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}