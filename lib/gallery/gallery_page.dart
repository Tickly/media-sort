import 'dart:async';

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

import 'media_grid.dart';
import '../viewer/media_viewer_page.dart';

enum DateSortOrder { desc, asc }

class GalleryPage extends StatefulWidget {
  const GalleryPage({super.key});

  @override
  State<GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> {
  static const int _pageSize = 120;

  PermissionState? _permissionState;
  AssetPathEntity? _path;
  final List<AssetEntity> _items = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _page = 0;
  Object? _lastError;

  DateSortOrder _dateSortOrder = DateSortOrder.desc;

  final ScrollController _scrollController = ScrollController();
  void Function(dynamic)? _changeCallback;

  FilterOptionGroup _buildFilter() {
    final group = FilterOptionGroup();
    group.addOrderOption(
      OrderOption(
        type: OrderOptionType.createDate,
        asc: _dateSortOrder == DateSortOrder.asc,
      ),
    );
    return group;
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    unawaited(_init());
  }

  @override
  void dispose() {
    if (_changeCallback != null) {
      PhotoManager.removeChangeCallback(_changeCallback!);
      PhotoManager.stopChangeNotify();
    }
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  Future<void> _init() async {
    await _requestPermission();
    if (!mounted) return;
    if (_permissionState?.isAuth != true) return;

    await _loadPath();
    if (!mounted) return;
    await _refresh();

    _changeCallback = (method) {
      // 媒体库变化时轻量刷新；首版先直接刷新列表
      if (mounted) {
        unawaited(_refresh());
      }
    };
    PhotoManager.addChangeCallback(_changeCallback!);
    PhotoManager.startChangeNotify();
  }

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

  Future<void> _loadPath() async {
    final filter = _buildFilter();
    final List<AssetPathEntity> paths = await PhotoManager.getAssetPathList(
      type: RequestType.common,
      hasAll: true,
      onlyAll: true,
      filterOption: filter,
    );

    if (!mounted) return;
    setState(() {
      _path = paths.isEmpty ? null : paths.first;
    });
  }

  Future<void> _refresh() async {
    if (_path == null) return;
    try {
      final refreshed = await _path!.fetchPathProperties(
        filterOptionGroup: _buildFilter(),
      );
      if (!mounted) return;
      if (refreshed != null) {
        setState(() {
          _path = refreshed;
        });
      }
    } catch (_) {
      // ignore; fall back to existing path
    }
    setState(() {
      _items.clear();
      _page = 0;
      _hasMore = true;
      _lastError = null;
    });
    await _loadMore();
  }

  Future<void> _loadMore() async {
    if (_isLoading || !_hasMore || _path == null) return;

    setState(() {
      _isLoading = true;
      _lastError = null;
    });

    try {
      final List<AssetEntity> pageItems = await _path!.getAssetListPaged(
        page: _page,
        size: _pageSize,
      );

      if (!mounted) return;
      setState(() {
        _items.addAll(pageItems);
        _page += 1;
        _hasMore = pageItems.length == _pageSize;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _lastError = e;
        _hasMore = false;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 1200) {
      unawaited(_loadMore());
    }
  }

  @override
  Widget build(BuildContext context) {
    final ps = _permissionState;

    return Scaffold(
      appBar: AppBar(
        title: const Text('相册'),
        actions: [
          IconButton(
            tooltip: _dateSortOrder == DateSortOrder.desc ? '日期倒序（最新在前）' : '日期正序（最旧在前）',
            icon: Icon(
              _dateSortOrder == DateSortOrder.desc ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
            ),
            onPressed: () {
              setState(() {
                _dateSortOrder =
                    _dateSortOrder == DateSortOrder.desc ? DateSortOrder.asc : DateSortOrder.desc;
              });
              unawaited(_refresh());
              if (_scrollController.hasClients) {
                _scrollController.jumpTo(0);
              }
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
              return _PermissionGate(
                permissionState: ps,
                onRetry: _requestPermission,
              );
            }

            if (_path == null) {
              return const Center(child: Text('未找到媒体资源'));
            }

            return RefreshIndicator(
              onRefresh: _refresh,
              child: MediaGrid(
                controller: _scrollController,
                items: _items,
                isLoadingMore: _isLoading,
                hasMore: _hasMore,
                lastError: _lastError,
                onLoadMore: _loadMore,
                onTap: (index) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => MediaViewerPage(
                        items: _items,
                        initialIndex: index,
                      ),
                    ),
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

class _PermissionGate extends StatelessWidget {
  const _PermissionGate({
    required this.permissionState,
    required this.onRetry,
  });

  final PermissionState permissionState;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final String subtitle = switch (permissionState) {
      PermissionState.denied => '未授予权限。请允许访问照片与视频以展示本地相册。',
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

