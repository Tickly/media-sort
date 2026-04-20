import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

import '../gallery/album_name.dart';

class AlbumsPage extends StatefulWidget {
  const AlbumsPage({super.key});

  @override
  State<AlbumsPage> createState() => _AlbumsPageState();
}

class _AlbumsPageState extends State<AlbumsPage> {
  PermissionState? _permissionState;
  List<AssetPathEntity> _albums = const [];
  bool _isLoading = false;
  Object? _lastError;

  /// 用于缓存相册封面缩略图 bytes。
  final Map<String, Uint8List?> _coverBytesByAlbumId = <String, Uint8List?>{};

  /// 用于缓存相册数量（assetCount）。
  final Map<String, int> _countByAlbumId = <String, int>{};

  /// 用于缓存相册“目录提示”（从封面资源 `relativePath` 推导）。
  final Map<String, String> _dirHintByAlbumId = <String, String>{};

  /// 输入：无。
  /// 输出：无返回值；请求系统媒体库权限，并更新 `_permissionState`。
  Future<void> _requestPermission() async {
    setState(() {
      _lastError = null;
    });

    final PermissionState ps = await PhotoManager.requestPermissionExtend(
      requestOption: const PermissionRequestOption(
        androidPermission: AndroidPermission(
          type: RequestType.common,
          mediaLocation: false,
        ),
      ),
    );

    if (!mounted) return;
    setState(() {
      _permissionState = ps;
    });
  }

  /// 输入：无。
  /// 输出：无返回值；重新加载相册列表，并清空封面/目录提示缓存。
  Future<void> _loadAlbums() async {
    setState(() {
      _isLoading = true;
      _lastError = null;
      _coverBytesByAlbumId.clear();
      _countByAlbumId.clear();
      _dirHintByAlbumId.clear();
    });

    try {
      final List<AssetPathEntity> paths = await PhotoManager.getAssetPathList(
        type: RequestType.common,
        hasAll: false,
        onlyAll: false,
      );

      if (!mounted) return;
      setState(() {
        _albums = paths;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _lastError = e;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// 输入：`album` 相册实体。
  /// 输出：相册封面缩略图 bytes（可能为 null）；函数内部会按 `album.id` 进行缓存。
  Future<Uint8List?> _getCoverBytes(AssetPathEntity album) async {
    final existing = _coverBytesByAlbumId[album.id];
    if (_coverBytesByAlbumId.containsKey(album.id)) return existing;

    try {
      final List<AssetEntity> first = await album.getAssetListPaged(
        page: 0,
        size: 1,
      );
      if (first.isEmpty) {
        _coverBytesByAlbumId[album.id] = null;
        return null;
      }

      // 默认情况下相册通常按时间降序；这里取第一页第一张作为封面。
      final bytes = await first.first.thumbnailDataWithSize(
        const ThumbnailSize(200, 200),
        quality: 75,
      );
      _coverBytesByAlbumId[album.id] = bytes;

      // 顺便缓存“目录提示”（从封面资源 relativePath 推导）。
      final hint = albumNameFromRelativePath(first.first.relativePath, fallback: '未知目录');
      _dirHintByAlbumId[album.id] = hint;

      return bytes;
    } catch (_) {
      _coverBytesByAlbumId[album.id] = null;
      return null;
    }
  }

  /// 输入：`album` 相册实体。
  /// 输出：相册内资源数量；内部会按 `album.id` 缓存，失败时返回 0。
  Future<int> _getCount(AssetPathEntity album) async {
    final cached = _countByAlbumId[album.id];
    if (cached != null) return cached;
    try {
      final count = await album.assetCountAsync;
      _countByAlbumId[album.id] = count;
      return count;
    } catch (_) {
      _countByAlbumId[album.id] = 0;
      return 0;
    }
  }

  /// 输入：`album` 相册实体。
  /// 输出：目录提示字符串（可能为 null）；若缓存未命中且尚未取过封面，会触发一次封面加载来填充缓存。
  Future<String?> _getDirHint(AssetPathEntity album) async {
    final existing = _dirHintByAlbumId[album.id];
    if (existing != null) return existing;
    if (_dirHintByAlbumId.containsKey(album.id)) return null;

    // 通过加载封面来填充目录提示缓存。
    await _getCoverBytes(album);
    return _dirHintByAlbumId[album.id];
  }

  /// 输入：无。
  /// 输出：无返回值；按“进入页面”的逻辑初始化（权限 -> 加载相册）。
  Future<void> _init() async {
    await _requestPermission();
    if (!mounted) return;
    if (_permissionState?.isAuth != true) return;
    await _loadAlbums();
  }

  @override
  void initState() {
    super.initState();
    unawaited(_init());
  }

  @override
  Widget build(BuildContext context) {
    final ps = _permissionState;

    return Scaffold(
      appBar: AppBar(
        title: const Text('相册'),
        actions: [
          IconButton(
            tooltip: '重新加载相册列表',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              unawaited(_init());
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Builder(
          builder: (context) {
            if (ps == null) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!ps.isAuth) {
              return _AlbumsPermissionGate(
                permissionState: ps,
                onRetry: _requestPermission,
              );
            }

            if (_isLoading && _albums.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            if (_lastError != null && _albums.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '加载失败：$_lastError',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Theme.of(context).colorScheme.error),
                      ),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: () {
                          unawaited(_loadAlbums());
                        },
                        child: const Text('重试'),
                      ),
                    ],
                  ),
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: _loadAlbums,
              child: ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: _albums.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final album = _albums[index];

                  return ListTile(
                    leading: FutureBuilder<Uint8List?>(
                      future: _getCoverBytes(album),
                      builder: (context, snapshot) {
                        final bytes = snapshot.data;
                        final child = bytes == null
                            ? const Icon(Icons.photo_album_outlined)
                            : ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.memory(
                                  bytes,
                                  width: 52,
                                  height: 52,
                                  fit: BoxFit.cover,
                                  gaplessPlayback: true,
                                ),
                              );
                        return SizedBox(
                          width: 52,
                          height: 52,
                          child: Center(child: child),
                        );
                      },
                    ),
                    title: Text(
                      album.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: FutureBuilder<String?>(
                      future: _getDirHint(album),
                      builder: (context, snapshot) {
                        return FutureBuilder<int>(
                          future: _getCount(album),
                          builder: (context, countSnap) {
                            final hint = snapshot.data;
                            final count = countSnap.data ?? 0;
                            final parts = <String>['数量：$count'];
                            if (hint != null && hint.isNotEmpty) {
                              parts.add('目录：$hint');
                            }
                            return Text(
                              parts.join(' · '),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            );
                          },
                        );
                      },
                    ),
                    // 按你的要求：不做点击交互
                    onTap: null,
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

class _AlbumsPermissionGate extends StatelessWidget {
  const _AlbumsPermissionGate({
    required this.permissionState,
    required this.onRetry,
  });

  final PermissionState permissionState;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final String subtitle = switch (permissionState) {
      PermissionState.denied => '未授予权限。请允许访问照片与视频以展示相册列表。',
      PermissionState.restricted => '权限受限，无法访问媒体库。',
      PermissionState.limited => '已授予有限权限（部分媒体可见）。',
      PermissionState.authorized => '已授权。',
      _ => '无法获取权限状态。',
    };

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '需要访问媒体库权限',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).hintColor),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                FilledButton(
                  onPressed: () async {
                    await onRetry();
                  },
                  child: const Text('重新请求权限'),
                ),
                OutlinedButton(
                  onPressed: () {
                    PhotoManager.openSetting();
                  },
                  child: const Text('打开系统设置'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

