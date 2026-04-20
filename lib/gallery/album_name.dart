import 'package:photo_manager/photo_manager.dart';

/// 输入：`relativePath`（可能为 null、可能以 `/` 结尾、可能包含多级目录，例如 `DCIM/Camera/`）。
/// 输出：推导得到的“相册名”（通常为最后一级目录名）；若无法推导，返回 `fallback`。
String albumNameFromRelativePath(
  String? relativePath, {
  String fallback = '未知相册',
}) {
  if (relativePath == null) return fallback;
  final trimmed = relativePath.trim();
  if (trimmed.isEmpty) return fallback;

  // `relativePath` 常见形式：`DCIM/Camera/`、`Pictures/MyAlbum/`。
  // 这里用分段取最后一个非空目录名作为“相册名”。
  final parts = trimmed.split('/');
  for (var i = parts.length - 1; i >= 0; i--) {
    final p = parts[i].trim();
    if (p.isNotEmpty) return p;
  }
  return fallback;
}

/// 输入：`entity`（来自 `photo_manager` 的媒体实体）。
/// 输出：该媒体的“所属相册名”（基于 `entity.relativePath` 推导），必要时返回兜底值。
String albumNameForEntity(
  AssetEntity entity, {
  String fallback = '未知相册',
}) {
  return albumNameFromRelativePath(entity.relativePath, fallback: fallback);
}

/// 一个轻量的内存缓存，用于避免重复解析同一资源的相册名。
///
/// 输入：通过 [get] 传入 `AssetEntity`。
/// 输出：返回相册名字符串；内部会按 `assetId` 缓存解析结果。
class AlbumNameCache {
  AlbumNameCache({this.fallback = '未知相册'});

  final String fallback;
  final Map<String, String> _cache = <String, String>{};

  /// 输入：`entity`（媒体实体）。
  /// 输出：相册名；若缓存命中直接返回，否则解析后写入缓存再返回。
  String get(AssetEntity entity) {
    final id = entity.id;
    final existing = _cache[id];
    if (existing != null) return existing;
    final computed = albumNameForEntity(entity, fallback: fallback);
    _cache[id] = computed;
    return computed;
  }

  /// 输入：无。
  /// 输出：清空缓存（无返回值）。
  void clear() => _cache.clear();
}

