import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

/// Converts Firestore [Timestamp], epoch milliseconds, or ISO-8601 [String] to [DateTime].
class FirestoreDateTimeConverter implements JsonConverter<DateTime, Object?> {
  const FirestoreDateTimeConverter();

  @override
  DateTime fromJson(Object? json) {
    if (json is Timestamp) {
      return json.toDate();
    }
    if (json is String) {
      return DateTime.tryParse(json) ?? DateTime.fromMillisecondsSinceEpoch(0);
    }
    if (json is int) {
      return DateTime.fromMillisecondsSinceEpoch(json);
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  @override
  Object toJson(DateTime object) => Timestamp.fromDate(object);
}

/// Nullable variant of [FirestoreDateTimeConverter] for `deletedAt` and optional dates.
class NullableFirestoreDateTimeConverter
    implements JsonConverter<DateTime?, Object?> {
  const NullableFirestoreDateTimeConverter();

  @override
  DateTime? fromJson(Object? json) {
    if (json == null) return null;
    if (json is Timestamp) return json.toDate();
    if (json is String) return DateTime.tryParse(json);
    if (json is int) return DateTime.fromMillisecondsSinceEpoch(json);
    return null;
  }

  @override
  Object? toJson(DateTime? object) =>
      object == null ? null : Timestamp.fromDate(object);
}

