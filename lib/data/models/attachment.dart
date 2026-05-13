class Attachment {
  final String id;
  final String fileName;
  final String mimeType;
  final int fileSize;
  final String fileUrl;

  const Attachment({
    required this.id,
    required this.fileName,
    required this.mimeType,
    required this.fileSize,
    required this.fileUrl,
  });

  String get prettySize {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) return '${(fileSize / 1024).toStringAsFixed(0)} KB';
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  factory Attachment.fromJson(Map<String, dynamic> json) => Attachment(
        id: json['id'] as String,
        fileName: json['file_name'] as String,
        mimeType: json['mime_type'] as String? ?? 'image/jpeg',
        fileSize: (json['file_size'] as num?)?.toInt() ?? 0,
        fileUrl: json['file_url'] as String,
      );
}
