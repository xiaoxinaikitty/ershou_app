/// 状态分析模型
class StatusAnalysis {
  final int status;
  final String statusDesc;
  final int count;
  final double percentage;

  StatusAnalysis({
    required this.status,
    required this.statusDesc,
    required this.count,
    required this.percentage,
  });

  factory StatusAnalysis.fromJson(Map<String, dynamic> json) {
    return StatusAnalysis(
      status: json['status'] ?? 0,
      statusDesc: json['statusDesc'] ?? '',
      count: json['count'] ?? 0,
      percentage: (json['percentage'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'statusDesc': statusDesc,
      'count': count,
      'percentage': percentage,
    };
  }
} 