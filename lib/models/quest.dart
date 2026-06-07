class Quest {
  static const String statusActive = 'active';
  static const String statusCompleted = 'completed';
  static const String statusFailed = 'failed';

  final String id;
  final String title;
  final String description;
  final String issuerNpcId;
  final String issuerNpcName;
  final String locationId;
  final String buildingId;
  final String status;
  final int acceptedYear;
  final String acceptedSeason;
  final int acceptedDay;
  final String progressSummary;
  final String rewardSummary;
  final String createdAt;

  Quest({
    required String id,
    required String title,
    required String description,
    required String issuerNpcId,
    required String issuerNpcName,
    required String locationId,
    required String buildingId,
    String status = statusActive,
    required this.acceptedYear,
    required String acceptedSeason,
    required this.acceptedDay,
    String progressSummary = '',
    String rewardSummary = '',
    String? createdAt,
  }) : id = id.trim(),
       title = title.trim(),
       description = description.trim(),
       issuerNpcId = issuerNpcId.trim(),
       issuerNpcName = issuerNpcName.trim(),
       locationId = locationId.trim(),
       buildingId = buildingId.trim(),
       status = status.trim().isEmpty ? statusActive : status.trim(),
       acceptedSeason = acceptedSeason.trim(),
       progressSummary = progressSummary.trim(),
       rewardSummary = rewardSummary.trim(),
       createdAt = (createdAt == null || createdAt.trim().isEmpty)
           ? DateTime.now().toIso8601String()
           : createdAt.trim();

  factory Quest.fromJson(Map<String, dynamic> json) {
    return Quest(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      issuerNpcId: json['issuerNpcId'] as String? ?? '',
      issuerNpcName: json['issuerNpcName'] as String? ?? '',
      locationId: json['locationId'] as String? ?? '',
      buildingId: json['buildingId'] as String? ?? '',
      status: json['status'] as String? ?? statusActive,
      acceptedYear: (json['acceptedYear'] as num?)?.toInt() ?? 0,
      acceptedSeason: json['acceptedSeason'] as String? ?? '',
      acceptedDay: (json['acceptedDay'] as num?)?.toInt() ?? 0,
      progressSummary: json['progressSummary'] as String? ?? '',
      rewardSummary: json['rewardSummary'] as String? ?? '',
      createdAt: json['createdAt'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'issuerNpcId': issuerNpcId,
    'issuerNpcName': issuerNpcName,
    'locationId': locationId,
    'buildingId': buildingId,
    'status': status,
    'acceptedYear': acceptedYear,
    'acceptedSeason': acceptedSeason,
    'acceptedDay': acceptedDay,
    'progressSummary': progressSummary,
    'rewardSummary': rewardSummary,
    'createdAt': createdAt,
  };

  Quest copyWith({
    String? title,
    String? description,
    String? issuerNpcId,
    String? issuerNpcName,
    String? locationId,
    String? buildingId,
    String? status,
    int? acceptedYear,
    String? acceptedSeason,
    int? acceptedDay,
    String? progressSummary,
    String? rewardSummary,
    String? createdAt,
  }) {
    return Quest(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      issuerNpcId: issuerNpcId ?? this.issuerNpcId,
      issuerNpcName: issuerNpcName ?? this.issuerNpcName,
      locationId: locationId ?? this.locationId,
      buildingId: buildingId ?? this.buildingId,
      status: status ?? this.status,
      acceptedYear: acceptedYear ?? this.acceptedYear,
      acceptedSeason: acceptedSeason ?? this.acceptedSeason,
      acceptedDay: acceptedDay ?? this.acceptedDay,
      progressSummary: progressSummary ?? this.progressSummary,
      rewardSummary: rewardSummary ?? this.rewardSummary,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
