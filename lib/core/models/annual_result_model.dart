class AnnualResultResponse {
  final int status;
  final String message;
  final String url;
  final AnnualResultData data;

  AnnualResultResponse({
    required this.status,
    required this.message,
    required this.url,
    required this.data,
  });

  factory AnnualResultResponse.fromJson(Map<String, dynamic> json) {
    return AnnualResultResponse(
      status: json['status'] ?? 0,
      message: json['message'] ?? '',
      url: json['url'] ?? '',
      data: AnnualResultData.fromJson(json['data'] ?? {}),
    );
  }
}

class AnnualResultData {
  final String ok;
  final String session;
  final String student;
  final String classm;
  final String classarm;
  final AnnualOverall overall;
  final List<AnnualSubject> subjects;

  AnnualResultData({
    required this.ok,
    required this.session,
    required this.student,
    required this.classm,
    required this.classarm,
    required this.overall,
    required this.subjects,
  });

  factory AnnualResultData.fromJson(Map<String, dynamic> json) {
    var subjectsJson = json['subjects'] as List? ?? [];

    return AnnualResultData(
      ok: json['ok'].toString(),
      session: json['session']?.toString() ?? '',
      student: json['student']?.toString() ?? '',
      classm: json['classm']?.toString() ?? '',
      classarm: json['classarm']?.toString() ?? '',
      overall: AnnualOverall.fromJson(json['overall'] ?? {}),
      subjects: subjectsJson
          .map((s) => AnnualSubject.fromJson(s as Map<String, dynamic>))
          .toList(),
    );
  }
}

class AnnualOverall {
  final String classm;
  final String classarm;
  final double total;
  final double avgm;
  final String position;

  AnnualOverall({
    required this.classm,
    required this.classarm,
    required this.total,
    required this.avgm,
    required this.position,
  });

  factory AnnualOverall.fromJson(Map<String, dynamic> json) {
    return AnnualOverall(
      classm: json['classm']?.toString() ?? '',
      classarm: json['classarm']?.toString() ?? '',
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
      avgm: (json['avgm'] as num?)?.toDouble() ?? 0.0,
      position: json['position']?.toString() ?? '',
    );
  }
}

class AnnualSubject {
  final int id;
  final String name;
  final AnnualTermScore annual;
  final Map<String, AnnualTermScore> terms;

  AnnualSubject({
    required this.id,
    required this.name,
    required this.annual,
    required this.terms,
  });

  factory AnnualSubject.fromJson(Map<String, dynamic> json) {
    Map<String, AnnualTermScore> termsMap = {};

    if (json['terms'] is Map) {
      (json['terms'] as Map).forEach((key, value) {
        termsMap[key.toString()] = AnnualTermScore.fromJson(value);
      });
    }

    return AnnualSubject(
      id: json['id'] ?? 0,
      name: json['name']?.toString() ?? 'Unknown Subject',
      annual: AnnualTermScore.fromJson(json['annual'] ?? {}),
      terms: termsMap,
    );
  }
}

class AnnualTermScore {
  final int ca;
  final int exam;
  final int totalm;
  final String position;
  final String classm;
  final String classarm;

  AnnualTermScore({
    required this.ca,
    required this.exam,
    required this.totalm,
    required this.position,
    required this.classm,
    required this.classarm,
  });

  factory AnnualTermScore.fromJson(Map<String, dynamic> json) {
    return AnnualTermScore(
      ca: int.tryParse(json['ca']?.toString() ?? '0') ?? 0,
      exam: int.tryParse(json['exam']?.toString() ?? '0') ?? 0,
      totalm: int.tryParse(json['totalm']?.toString() ?? '0') ?? 0,
      position: json['position']?.toString() ?? '',
      classm: json['classm']?.toString() ?? '',
      classarm: json['classarm']?.toString() ?? '',
    );
  }
}