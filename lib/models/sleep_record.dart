class SleepRecord {
  final String id;
  final DateTime setAt;
  final DateTime wokeAt;

  SleepRecord({
    required this.id,
    required this.setAt,
    required this.wokeAt,
  });

  Duration get duration => wokeAt.difference(setAt);

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'setAt': setAt.toIso8601String(),
      'wokeAt': wokeAt.toIso8601String(),
    };
  }

  factory SleepRecord.fromJson(Map<String, dynamic> json) {
    return SleepRecord(
      id: json['id'] as String,
      setAt: DateTime.parse(json['setAt'] as String),
      wokeAt: DateTime.parse(json['wokeAt'] as String),
    );
  }
}