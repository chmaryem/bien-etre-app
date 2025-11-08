class Goal {
  final int? id;
  final String title;
  final String type;
  final double targetValue;
  final double currentValue;
  final String startDate;
  final String endDate;

  Goal({
    this.id,
    required this.title,
    required this.type,
    required this.targetValue,
    required this.currentValue,
    required this.startDate,
    required this.endDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'type': type,
      'targetValue': targetValue,
      'currentValue': currentValue,
      'startDate': startDate,
      'endDate': endDate,
    };
  }
}
