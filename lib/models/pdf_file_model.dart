class PdfFileModel {
  final String id;
  final String name;
  final String path;
  final int sizeBytes;
  final String formattedSize;
  final DateTime createdAt;
  final String? thumbnailPath;

  PdfFileModel({
    required this.id,
    required this.name,
    required this.path,
    required this.sizeBytes,
    required this.formattedSize,
    required this.createdAt,
    this.thumbnailPath,
  });
}
