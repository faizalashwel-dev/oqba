import 'dart:convert';

/// Model representing a bundle of output files from a single operation.
///
/// A bundle groups related outputs (e.g., 20 extracted images) into a
/// logical unit displayed as a single card on the Home screen.
class BundleModel {
  final String id;
  final String name;
  final String type; // 'extracted_images', 'pdf_to_images', 'security', etc.
  final List<String> filePaths;
  final DateTime createdAt;
  final int totalSizeBytes;

  BundleModel({
    required this.id,
    required this.name,
    required this.type,
    required this.filePaths,
    required this.createdAt,
    this.totalSizeBytes = 0,
  });

  int get fileCount => filePaths.length;

  String get formattedSize {
    if (totalSizeBytes < 1024) return '$totalSizeBytes B';
    if (totalSizeBytes < 1024 * 1024) {
      return '${(totalSizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    if (totalSizeBytes < 1024 * 1024 * 1024) {
      return '${(totalSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(totalSizeBytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// Get the first file path for thumbnail preview.
  String? get thumbnailPath => filePaths.isNotEmpty ? filePaths.first : null;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type,
        'filePaths': filePaths,
        'createdAt': createdAt.toIso8601String(),
        'totalSizeBytes': totalSizeBytes,
      };

  factory BundleModel.fromJson(Map<String, dynamic> json) => BundleModel(
        id: json['id'] as String,
        name: json['name'] as String,
        type: json['type'] as String,
        filePaths: List<String>.from(json['filePaths'] as List),
        createdAt: DateTime.parse(json['createdAt'] as String),
        totalSizeBytes: json['totalSizeBytes'] as int? ?? 0,
      );

  String toJsonString() => jsonEncode(toJson());

  factory BundleModel.fromJsonString(String source) =>
      BundleModel.fromJson(jsonDecode(source) as Map<String, dynamic>);
}
