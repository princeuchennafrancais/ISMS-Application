// newsletter_response_model.dart
class NewsletterResponseModel {
  final bool status;
  final List<Newsletter> data;

  NewsletterResponseModel({
    required this.status,
    required this.data,
  });

  factory NewsletterResponseModel.fromJson(Map<String, dynamic> json) {
    return NewsletterResponseModel(
      status: json['status'] ?? false,
      data: (json['data'] as List<dynamic>?)
          ?.map((item) => Newsletter.fromJson(item))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'data': data.map((newsletter) => newsletter.toJson()).toList(),
    };
  }
}

class Newsletter {
  final String id;
  final String caption;
  final String note;
  final String file;
  final String createdAt;
  final String status;

  Newsletter({
    required this.id,
    required this.caption,
    required this.note,
    required this.file,
    required this.createdAt,
    required this.status,
  });

  factory Newsletter.fromJson(Map<String, dynamic> json) {
    return Newsletter(
      id: json['id']?.toString() ?? '',
      caption: json['caption']?.toString() ?? '',
      note: json['note']?.toString() ?? '',
      file: json['file']?.toString() ?? '',
      createdAt: json['created_at']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'caption': caption,
      'note': note,
      'file': file,
      'created_at': createdAt,
      'status': status,
    };
  }

  // Helper method to get formatted date
  String get formattedDate {
    try {
      if (createdAt.length >= 8) {
        String year = createdAt.substring(0, 4);
        String month = createdAt.substring(4, 6);
        String day = createdAt.substring(6, 8);
        return '$day/$month/$year';
      }
      return createdAt;
    } catch (e) {
      return createdAt;
    }
  }

  // Helper method to get file name from URL
  String get fileName {
    try {
      Uri uri = Uri.parse(file);
      String fileName = uri.pathSegments.last;
      return fileName.isNotEmpty ? fileName : 'newsletter_$id.pdf';
    } catch (e) {
      return 'newsletter_$id.pdf';
    }
  }
}