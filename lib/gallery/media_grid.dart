import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

import 'media_thumbnail.dart';

class MediaGrid extends StatelessWidget {
  const MediaGrid({
    super.key,
    required this.controller,
    required this.items,
    required this.onTap,
    required this.onLoadMore,
    required this.isLoadingMore,
    required this.hasMore,
    required this.lastError,
  });

  final ScrollController controller;
  final List<AssetEntity> items;
  final void Function(int index) onTap;
  final Future<void> Function() onLoadMore;
  final bool isLoadingMore;
  final bool hasMore;
  final Object? lastError;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      controller: controller,
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(2),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 2,
              mainAxisSpacing: 2,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final entity = items[index];
                return GestureDetector(
                  onTap: () => onTap(index),
                  child: MediaThumbnail(entity: entity),
                );
              },
              childCount: items.length,
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: _Footer(
            isLoadingMore: isLoadingMore,
            hasMore: hasMore,
            lastError: lastError,
            onRetry: onLoadMore,
          ),
        ),
      ],
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({
    required this.isLoadingMore,
    required this.hasMore,
    required this.lastError,
    required this.onRetry,
  });

  final bool isLoadingMore;
  final bool hasMore;
  final Object? lastError;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    if (isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (lastError != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        child: Center(
          child: Column(
            children: [
              Text(
                '加载失败：$lastError',
                textAlign: TextAlign.center,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: () async {
                  await onRetry();
                },
                child: const Text('重试'),
              ),
            ],
          ),
        ),
      );
    }

    if (!hasMore) {
      return const SizedBox(height: 24);
    }

    return const SizedBox(height: 24);
  }
}

