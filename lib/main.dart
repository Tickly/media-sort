import 'package:flutter/material.dart';
import 'package:media_sort/gallery/gallery_page.dart';

void main() {
  runApp(const MediaSortApp());
}

class MediaSortApp extends StatelessWidget {
  const MediaSortApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '媒体整理',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const GalleryPage(),
    );
  }
}
