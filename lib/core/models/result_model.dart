class ResultResponse {
  final int status;
  final String message;
  final String url;
  final ResultData data;

  ResultResponse({
    required this.status,
    required this.message,
    required this.url,
    required this.data,
  });

  factory ResultResponse.fromJson(Map<String, dynamic> json) {
    return ResultResponse(
      status: json['status'] ?? 0,
      message: json['message'] ?? '',
      url: json['url'] ?? '',
      data: ResultData.fromJson(json['data'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'message': message,
      'url': url,
      'data': data.toJson(),
    };
  }
}

class ResultData {
  final bool ok;
  final StudentInfo student;
  final ClassPosition classPosition;
  final List<SubjectResult> results;

  ResultData({
    required this.ok,
    required this.student,
    required this.classPosition,
    required this.results,
  });

  factory ResultData.fromJson(Map<String, dynamic> json) {
    return ResultData(
      ok: json['ok'] ?? true,
      student: StudentInfo.fromJson(json['student'] ?? {}),
      classPosition: ClassPosition.fromJson(json['classPosition'] ?? {}),
      results: (json['results'] as List?)
          ?.map((result) => SubjectResult.fromJson(result))
          .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ok': ok,
      'student': student.toJson(),
      'classPosition': classPosition.toJson(),
      'results': results.map((r) => r.toJson()).toList(),
    };
  }
}

class StudentInfo {
  final int id;
  final String regno;
  final String firstname;
  final String lastname;
  final String? othername;
  final int session;
  final int term;
  final int classm;
  final int classArm;

  StudentInfo({
    required this.id,
    required this.regno,
    required this.firstname,
    required this.lastname,
    this.othername,
    required this.session,
    required this.term,
    required this.classm,
    required this.classArm,
  });

  String get fullName => '$firstname $lastname'.trim();

  factory StudentInfo.fromJson(Map<String, dynamic> json) {
    return StudentInfo(
      id: json['id'] ?? 0,
      regno: json['regno'] ?? '',
      firstname: json['firstname'] ?? '',
      lastname: json['lastname'] ?? '',
      othername: json['othername'],
      session: json['session'] ?? 0,
      term: json['term'] ?? 0,
      classm: json['classm'] ?? 0,
      classArm: json['class_arm'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'regno': regno,
      'firstname': firstname,
      'lastname': lastname,
      'othername': othername,
      'session': session,
      'term': term,
      'classm': classm,
      'class_arm': classArm,
    };
  }
}

class ClassPosition {
  final int position;
  final int totalStudents;
  final double classAverage;

  ClassPosition({
    required this.position,
    required this.totalStudents,
    required this.classAverage,
  });

  factory ClassPosition.fromJson(Map<String, dynamic> json) {
    return ClassPosition(
      position: int.tryParse(json['class_position']?.toString() ?? '0') ?? 0,
      totalStudents: int.tryParse(json['total_student']?.toString() ?? '0') ?? 0,
      classAverage:
      double.tryParse(json['avg_student']?.toString() ?? '0.0') ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'class_position': position.toString(),
      'total_student': totalStudents.toString(),
      'avg_student': classAverage.toString(),
    };
  }
}

class SubjectResult {
  final int subjectId;
  final String subjectName;
  final int ca;
  final int exam;
  final int total;
  final String grade;

  SubjectResult({
    required this.subjectId,
    required this.subjectName,
    required this.ca,
    required this.exam,
    required this.total,
    required this.grade,
  });

  String get displayName => subjectName.trim();

  // Helper method to determine grade color
  String getGradeColor() {
    switch (grade.toUpperCase()) {
      case 'A':
        return '#10B981'; // Green
      case 'B':
        return '#3B82F6'; // Blue
      case 'C':
        return '#F59E0B'; // Amber
      case 'D':
        return '#EF4444'; // Red
      case 'E':
        return '#DC2626'; // Dark Red
      case 'F':
      case 'P':
        return '#991B1B'; // Very Dark Red
      default:
        return '#6B7280'; // Gray
    }
  }

  factory SubjectResult.fromJson(Map<String, dynamic> json) {
    return SubjectResult(
      subjectId: int.tryParse(json['subject_id']?.toString() ?? '0') ?? 0,
      subjectName: json['subject_name'] ?? '',
      ca: int.tryParse(json['ca']?.toString() ?? '0') ?? 0,
      exam: int.tryParse(json['exam']?.toString() ?? '0') ?? 0,
      total: int.tryParse(json['total']?.toString() ?? '0') ?? 0,
      grade: json['grade'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'subject_id': subjectId.toString(),
      'subject_name': subjectName,
      'ca': ca.toString(),
      'exam': exam.toString(),
      'total': total.toString(),
      'grade': grade,
    };
  }

  SubjectResult copyWith({
    int? subjectId,
    String? subjectName,
    int? ca,
    int? exam,
    int? total,
    String? grade,
  }) {
    return SubjectResult(
      subjectId: subjectId ?? this.subjectId,
      subjectName: subjectName ?? this.subjectName,
      ca: ca ?? this.ca,
      exam: exam ?? this.exam,
      total: total ?? this.total,
      grade: grade ?? this.grade,
    );
  }
}