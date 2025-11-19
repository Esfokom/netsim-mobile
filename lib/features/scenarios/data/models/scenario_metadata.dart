// class Metadata {
//   final String createdBy;
//   final DateTime createdAt;
//   final String description;
//
//   Metadata({
//     required this.createdBy,
//     required this.createdAt,
//     required this.description,
//   });
//
//   static DateTime _parseDate(dynamic value) {
//     if (value is DateTime) return value;
//     if (value is int) {
//       return DateTime.fromMillisecondsSinceEpoch(value, isUtc: true).toLocal();
//     }
//     if (value is String) {
//       final parsed = DateTime.tryParse(value);
//       if (parsed != null) return parsed;
//       final asInt = int.tryParse(value);
//       if (asInt != null) {
//         return DateTime.fromMillisecondsSinceEpoch(
//           asInt,
//           isUtc: true,
//         ).toLocal();
//       }
//     }
//     return DateTime.now();
//   }
//
//   factory Metadata.fromJson(Map<String, dynamic> json) => Metadata(
//     createdBy: json['createdBy'] as String,
//     createdAt: _parseDate(json['createdAt']),
//     description: json['description'] as String,
//   );
//
//   Map<String, dynamic> toJson() => {
//     'createdBy': createdBy,
//     'createdAt': createdAt.toIso8601String(),
//     'description': description,
//   };
//
//   Metadata copyWith({
//     String? createdBy,
//     DateTime? createdAt,
//     String? description,
//   }) => Metadata(
//     createdBy: createdBy ?? this.createdBy,
//     createdAt: createdAt ?? this.createdAt,
//     description: description ?? this.description,
//   );
// }
