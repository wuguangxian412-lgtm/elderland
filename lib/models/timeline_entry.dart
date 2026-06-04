/// 时间线条目数据模型
class TimelineEntry {
  final int id;
  final int year;
  final String season;
  final String title;
  final String content;

  const TimelineEntry({
    required this.id,
    required this.year,
    required this.season,
    required this.title,
    required this.content,
  });

  /// 从 JSON 解析 TimelineEntry
  factory TimelineEntry.fromJson(Map<String, dynamic> json) {
    return TimelineEntry(
      id: (json['id'] as num?)?.toInt() ?? 0,
      year: (json['year'] as num?)?.toInt() ?? 0,
      season: json['season'] as String? ?? '',
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
    );
  }
}
