import 'package:photo_manager/photo_manager.dart';

class DaySection {
  const DaySection({
    required this.day,
    required this.indices,
  });

  /// Local date (year/month/day, time stripped)
  final DateTime day;

  /// Indices into the original flat list (so viewer paging stays consistent).
  final List<int> indices;
}

List<DaySection> groupAssetIndicesByDay(List<AssetEntity> items) {
  final List<DaySection> sections = [];
  final Map<int, int> keyToSectionIndex = {};

  for (var i = 0; i < items.length; i++) {
    final entity = items[i];
    final dt = entity.createDateTime.toLocal();
    final day = DateTime(dt.year, dt.month, dt.day);
    final key = day.millisecondsSinceEpoch;

    final existing = keyToSectionIndex[key];
    if (existing == null) {
      keyToSectionIndex[key] = sections.length;
      sections.add(DaySection(day: day, indices: [i]));
    } else {
      sections[existing].indices.add(i);
    }
  }

  return sections;
}

String formatYyyyMmDd(DateTime day) {
  final y = day.year.toString().padLeft(4, '0');
  final m = day.month.toString().padLeft(2, '0');
  final d = day.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

