/// A delivery-note file attached to a Master PO.
///
/// Two lifecycle states:
/// - [DeliveryNoteStatus.template] — empty template uploaded by an
///   employee from the dashboard, waiting to be filled in.
/// - [DeliveryNoteStatus.completed] — filled-in version uploaded by
///   the representative from mobile.
enum DeliveryNoteStatus { template, completed }

extension DeliveryNoteStatusX on DeliveryNoteStatus {
  static DeliveryNoteStatus parse(String? value) {
    return switch (value?.toUpperCase()) {
      'TEMPLATE' => DeliveryNoteStatus.template,
      'COMPLETED' => DeliveryNoteStatus.completed,
      _ => DeliveryNoteStatus.template,
    };
  }

  bool get isCompleted => this == DeliveryNoteStatus.completed;
  bool get isTemplate => this == DeliveryNoteStatus.template;
}

class DeliveryNote {
  final String fileName;
  final String mimeType;
  final int fileSize;
  final DeliveryNoteStatus status;
  final DateTime updatedAt;

  /// Server-relative path (e.g. `/api/delivery/mobile/master-pos/uuid/delivery-note`).
  /// The UI should call [DeliveryApi.resolveFileUrl] before using it.
  final String downloadUrl;

  const DeliveryNote({
    required this.fileName,
    required this.mimeType,
    required this.fileSize,
    required this.status,
    required this.updatedAt,
    required this.downloadUrl,
  });

  /// "12 KB" / "1.4 MB" — matches the style used for Attachment.prettySize.
  String get prettySize {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) return '${(fileSize / 1024).toStringAsFixed(0)} KB';
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// Lowercased extension (`pdf`, `xlsx`, …) parsed from [fileName] or [mimeType].
  String get extension {
    final dot = fileName.lastIndexOf('.');
    if (dot >= 0 && dot < fileName.length - 1) {
      return fileName.substring(dot + 1).toLowerCase();
    }
    return mimeType.split('/').last.toLowerCase();
  }

  factory DeliveryNote.fromJson(Map<String, dynamic> json) {
    int asInt(dynamic v) =>
        v is int ? v : (v is String ? int.tryParse(v) ?? 0 : (v as num?)?.toInt() ?? 0);
    DateTime date(dynamic v) =>
        v == null ? DateTime.now() : DateTime.tryParse(v.toString()) ?? DateTime.now();

    return DeliveryNote(
      fileName: (json['file_name'] as String?) ?? 'delivery-note',
      mimeType: (json['mime_type'] as String?) ?? 'application/octet-stream',
      fileSize: asInt(json['file_size']),
      status: DeliveryNoteStatusX.parse(json['status'] as String?),
      updatedAt: date(json['updated_at']),
      downloadUrl: (json['download_url'] as String?) ?? '',
    );
  }
}
