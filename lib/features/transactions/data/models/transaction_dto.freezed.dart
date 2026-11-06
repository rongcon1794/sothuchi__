// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'transaction_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TransactionDto {

 String get id; int get amount; String get currency; String get type; String get accountId; String? get toAccountId; String get categoryId; String get note;@FirestoreDateTimeConverter() DateTime get date; List<String> get tags; String get ledgerId;@FirestoreDateTimeConverter() DateTime get createdAt;@FirestoreDateTimeConverter() DateTime get updatedAt;@NullableFirestoreDateTimeConverter() DateTime? get deletedAt;
/// Create a copy of TransactionDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TransactionDtoCopyWith<TransactionDto> get copyWith => _$TransactionDtoCopyWithImpl<TransactionDto>(this as TransactionDto, _$identity);

  /// Serializes this TransactionDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as TransactionDto;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TransactionDto&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.amount, _this.amount) || other.amount == _this.amount)&&(identical(other.currency, _this.currency) || other.currency == _this.currency)&&(identical(other.type, _this.type) || other.type == _this.type)&&(identical(other.accountId, _this.accountId) || other.accountId == _this.accountId)&&(identical(other.toAccountId, _this.toAccountId) || other.toAccountId == _this.toAccountId)&&(identical(other.categoryId, _this.categoryId) || other.categoryId == _this.categoryId)&&(identical(other.note, _this.note) || other.note == _this.note)&&(identical(other.date, _this.date) || other.date == _this.date)&&const DeepCollectionEquality().equals(other.tags, _this.tags)&&(identical(other.ledgerId, _this.ledgerId) || other.ledgerId == _this.ledgerId)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt)&&(identical(other.updatedAt, _this.updatedAt) || other.updatedAt == _this.updatedAt)&&(identical(other.deletedAt, _this.deletedAt) || other.deletedAt == _this.deletedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as TransactionDto;
  return Object.hash(runtimeType,_this.id,_this.amount,_this.currency,_this.type,_this.accountId,_this.toAccountId,_this.categoryId,_this.note,_this.date,const DeepCollectionEquality().hash(_this.tags),_this.ledgerId,_this.createdAt,_this.updatedAt,_this.deletedAt);
}

@override
String toString() {
  final _this = this as TransactionDto;
  return 'TransactionDto(id: ${_this.id}, amount: ${_this.amount}, currency: ${_this.currency}, type: ${_this.type}, accountId: ${_this.accountId}, toAccountId: ${_this.toAccountId}, categoryId: ${_this.categoryId}, note: ${_this.note}, date: ${_this.date}, tags: ${_this.tags}, ledgerId: ${_this.ledgerId}, createdAt: ${_this.createdAt}, updatedAt: ${_this.updatedAt}, deletedAt: ${_this.deletedAt})';
}


}

/// @nodoc
abstract mixin class $TransactionDtoCopyWith<$Res>  {
  factory $TransactionDtoCopyWith(TransactionDto value, $Res Function(TransactionDto) _then) = _$TransactionDtoCopyWithImpl;
@useResult
$Res call({
 String id, int amount, String currency, String type, String accountId, String? toAccountId, String categoryId, String note,@FirestoreDateTimeConverter() DateTime date, List<String> tags, String ledgerId,@FirestoreDateTimeConverter() DateTime createdAt,@FirestoreDateTimeConverter() DateTime updatedAt,@NullableFirestoreDateTimeConverter() DateTime? deletedAt
});




}
/// @nodoc
class _$TransactionDtoCopyWithImpl<$Res>
    implements $TransactionDtoCopyWith<$Res> {
  _$TransactionDtoCopyWithImpl(this._self, this._then);

  final TransactionDto _self;
  final $Res Function(TransactionDto) _then;

/// Create a copy of TransactionDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? amount = null,Object? currency = null,Object? type = null,Object? accountId = null,Object? toAccountId = freezed,Object? categoryId = null,Object? note = null,Object? date = null,Object? tags = null,Object? ledgerId = null,Object? createdAt = null,Object? updatedAt = null,Object? deletedAt = freezed,}) {
  return _then(TransactionDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as int,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,accountId: null == accountId ? _self.accountId : accountId // ignore: cast_nullable_to_non_nullable
as String,toAccountId: freezed == toAccountId ? _self.toAccountId : toAccountId // ignore: cast_nullable_to_non_nullable
as String?,categoryId: null == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String,note: null == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,tags: null == tags ? _self.tags : tags // ignore: cast_nullable_to_non_nullable
as List<String>,ledgerId: null == ledgerId ? _self.ledgerId : ledgerId // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,deletedAt: freezed == deletedAt ? _self.deletedAt : deletedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [TransactionDto].
extension TransactionDtoPatterns on TransactionDto {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TransactionDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TransactionDto() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TransactionDto value)  $default,){
final _that = this;
switch (_that) {
case _TransactionDto():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TransactionDto value)?  $default,){
final _that = this;
switch (_that) {
case _TransactionDto() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  int amount,  String currency,  String type,  String accountId,  String? toAccountId,  String categoryId,  String note, @FirestoreDateTimeConverter()  DateTime date,  List<String> tags,  String ledgerId, @FirestoreDateTimeConverter()  DateTime createdAt, @FirestoreDateTimeConverter()  DateTime updatedAt, @NullableFirestoreDateTimeConverter()  DateTime? deletedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TransactionDto() when $default != null:
return $default(_that.id,_that.amount,_that.currency,_that.type,_that.accountId,_that.toAccountId,_that.categoryId,_that.note,_that.date,_that.tags,_that.ledgerId,_that.createdAt,_that.updatedAt,_that.deletedAt);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  int amount,  String currency,  String type,  String accountId,  String? toAccountId,  String categoryId,  String note, @FirestoreDateTimeConverter()  DateTime date,  List<String> tags,  String ledgerId, @FirestoreDateTimeConverter()  DateTime createdAt, @FirestoreDateTimeConverter()  DateTime updatedAt, @NullableFirestoreDateTimeConverter()  DateTime? deletedAt)  $default,) {final _that = this;
switch (_that) {
case _TransactionDto():
return $default(_that.id,_that.amount,_that.currency,_that.type,_that.accountId,_that.toAccountId,_that.categoryId,_that.note,_that.date,_that.tags,_that.ledgerId,_that.createdAt,_that.updatedAt,_that.deletedAt);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  int amount,  String currency,  String type,  String accountId,  String? toAccountId,  String categoryId,  String note, @FirestoreDateTimeConverter()  DateTime date,  List<String> tags,  String ledgerId, @FirestoreDateTimeConverter()  DateTime createdAt, @FirestoreDateTimeConverter()  DateTime updatedAt, @NullableFirestoreDateTimeConverter()  DateTime? deletedAt)?  $default,) {final _that = this;
switch (_that) {
case _TransactionDto() when $default != null:
return $default(_that.id,_that.amount,_that.currency,_that.type,_that.accountId,_that.toAccountId,_that.categoryId,_that.note,_that.date,_that.tags,_that.ledgerId,_that.createdAt,_that.updatedAt,_that.deletedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TransactionDto extends TransactionDto {
  const _TransactionDto({required this.id, required this.amount, this.currency = AppCurrencies.defaultCode, required this.type, required this.accountId, this.toAccountId, required this.categoryId, this.note = '', @FirestoreDateTimeConverter() required this.date,  List<String> tags = const <String>[], this.ledgerId = LedgerBook.defaultPersonalId, @FirestoreDateTimeConverter() required this.createdAt, @FirestoreDateTimeConverter() required this.updatedAt, @NullableFirestoreDateTimeConverter() this.deletedAt}): _tags = tags,super._();
  factory _TransactionDto.fromJson(Map<String, dynamic> json) => _$TransactionDtoFromJson(json);

@override final  String id;
@override final  int amount;
@override@JsonKey() final  String currency;
@override final  String type;
@override final  String accountId;
@override final  String? toAccountId;
@override final  String categoryId;
@override@JsonKey() final  String note;
@override@FirestoreDateTimeConverter() final  DateTime date;
 final  List<String> _tags;
@override@JsonKey() List<String> get tags {
  if (_tags is EqualUnmodifiableListView) return _tags;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_tags);
}

@override@JsonKey() final  String ledgerId;
@override@FirestoreDateTimeConverter() final  DateTime createdAt;
@override@FirestoreDateTimeConverter() final  DateTime updatedAt;
@override@NullableFirestoreDateTimeConverter() final  DateTime? deletedAt;

/// Create a copy of TransactionDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TransactionDtoCopyWith<_TransactionDto> get copyWith => __$TransactionDtoCopyWithImpl<_TransactionDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TransactionDtoToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _TransactionDto&&(identical(other.id, id) || other.id == id)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.type, type) || other.type == type)&&(identical(other.accountId, accountId) || other.accountId == accountId)&&(identical(other.toAccountId, toAccountId) || other.toAccountId == toAccountId)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.note, note) || other.note == note)&&(identical(other.date, date) || other.date == date)&&const DeepCollectionEquality().equals(other.tags, _tags)&&(identical(other.ledgerId, ledgerId) || other.ledgerId == ledgerId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.deletedAt, deletedAt) || other.deletedAt == deletedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,amount,currency,type,accountId,toAccountId,categoryId,note,date,const DeepCollectionEquality().hash(_tags),ledgerId,createdAt,updatedAt,deletedAt);
}

@override
String toString() {
    return 'TransactionDto(id: $id, amount: $amount, currency: $currency, type: $type, accountId: $accountId, toAccountId: $toAccountId, categoryId: $categoryId, note: $note, date: $date, tags: $tags, ledgerId: $ledgerId, createdAt: $createdAt, updatedAt: $updatedAt, deletedAt: $deletedAt)';
}


}

/// @nodoc
abstract mixin class _$TransactionDtoCopyWith<$Res> implements $TransactionDtoCopyWith<$Res> {
  factory _$TransactionDtoCopyWith(_TransactionDto value, $Res Function(_TransactionDto) _then) = __$TransactionDtoCopyWithImpl;
@override @useResult
$Res call({
 String id, int amount, String currency, String type, String accountId, String? toAccountId, String categoryId, String note,@FirestoreDateTimeConverter() DateTime date, List<String> tags, String ledgerId,@FirestoreDateTimeConverter() DateTime createdAt,@FirestoreDateTimeConverter() DateTime updatedAt,@NullableFirestoreDateTimeConverter() DateTime? deletedAt
});




}
/// @nodoc
class __$TransactionDtoCopyWithImpl<$Res>
    implements _$TransactionDtoCopyWith<$Res> {
  __$TransactionDtoCopyWithImpl(this._self, this._then);

  final _TransactionDto _self;
  final $Res Function(_TransactionDto) _then;

/// Create a copy of TransactionDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? amount = null,Object? currency = null,Object? type = null,Object? accountId = null,Object? toAccountId = freezed,Object? categoryId = null,Object? note = null,Object? date = null,Object? tags = null,Object? ledgerId = null,Object? createdAt = null,Object? updatedAt = null,Object? deletedAt = freezed,}) {
  return _then(_TransactionDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as int,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,accountId: null == accountId ? _self.accountId : accountId // ignore: cast_nullable_to_non_nullable
as String,toAccountId: freezed == toAccountId ? _self.toAccountId : toAccountId // ignore: cast_nullable_to_non_nullable
as String?,categoryId: null == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String,note: null == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,tags: null == tags ? _self._tags : tags // ignore: cast_nullable_to_non_nullable
as List<String>,ledgerId: null == ledgerId ? _self.ledgerId : ledgerId // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,deletedAt: freezed == deletedAt ? _self.deletedAt : deletedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
