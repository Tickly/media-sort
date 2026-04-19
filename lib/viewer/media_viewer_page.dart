import 'dart:io';

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:video_player/video_player.dart';

class MediaViewerPage extends StatefulWidget {
  const MediaViewerPage({
    super.key,
    required this.items,
    required this.initialIndex,
  });

  final List<AssetEntity> items;
  final int initialIndex;

  @override
  State<MediaViewerPage> createState() => _MediaViewerPageState();
}

class _MediaViewerPageState extends State<MediaViewerPage> {
  late final PageController _controller = PageController(
    initialPage: widget.initialIndex,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text(''),
      ),
      body: PageView.builder(
        controller: _controller,
        itemCount: widget.items.length,
        itemBuilder: (context, index) {
          final entity = widget.items[index];
          return _MediaPage(entity: entity);
        },
      ),
    );
  }
}

class _MediaPage extends StatelessWidget {
  const _MediaPage({required this.entity});

  final AssetEntity entity;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<File?>(
      future: entity.file,
      builder: (context, snapshot) {
        final file = snapshot.data;
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (file == null) {
          return const Center(
            child: Text(
              '无法读取文件',
              style: TextStyle(color: Colors.white70),
            ),
          );
        }

        return switch (entity.type) {
          AssetType.video => _VideoPlayerView(file: file),
          _ => _ZoomableImage(file: file),
        };
      },
    );
  }
}

class _ZoomableImage extends StatelessWidget {
  const _ZoomableImage({required this.file});

  final File file;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: InteractiveViewer(
        minScale: 1,
        maxScale: 4,
        child: Image.file(file, fit: BoxFit.contain),
      ),
    );
  }
}

class _VideoPlayerView extends StatefulWidget {
  const _VideoPlayerView({required this.file});

  final File file;

  @override
  State<_VideoPlayerView> createState() => _VideoPlayerViewState();
}

class _VideoPlayerViewState extends State<_VideoPlayerView> {
  VideoPlayerController? _vp;
  Future<void>? _initFuture;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    final controller = VideoPlayerController.file(widget.file);
    _vp = controller;
    _initFuture = controller.initialize().then((_) {
      if (!mounted) return;
      setState(() {});
    });
  }

  @override
  void dispose() {
    _vp?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vp = _vp;
    if (vp == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return FutureBuilder<void>(
      future: _initFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }

        final size = vp.value.size;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () async {
            if (_isPlaying) {
              await vp.pause();
            } else {
              await vp.play();
            }
            if (!mounted) return;
            setState(() {
              _isPlaying = vp.value.isPlaying;
            });
          },
          child: Center(
            child: AspectRatio(
              aspectRatio: size.width == 0 ? 16 / 9 : vp.value.aspectRatio,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  VideoPlayer(vp),
                  if (!vp.value.isPlaying)
                    Container(
                      decoration: const BoxDecoration(
                        color: Colors.black38,
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(12),
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        size: 48,
                        color: Colors.white,
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

