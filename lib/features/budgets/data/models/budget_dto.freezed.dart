// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'budget_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BudgetDto {

 String get id; String? get categoryId; int get amount; String get currency; String get period;@FirestoreDateTimeConverter() DateTime get startDate; int get alertThreshold;@FirestoreDateTimeConverter() DateTime get createdAt;@FirestoreDateTimeConverter() DateTime get updatedAt;@NullableFirestoreDateTimeConverter() DateTime? get deletedAt;
/// Create a copy of BudgetDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BudgetDtoCopyWith<BudgetDto> get copyWith => _$BudgetDtoCopyWithImpl<BudgetDto>(this as BudgetDto, _$identity);

  /// Serializes this BudgetDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as BudgetDto;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BudgetDto&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.categoryId, _this.categoryId) || other.categoryId == _this.categoryId)&&(identical(other.amount, _this.amount) || other.amount == _this.amount)&&(identical(other.currency, _this.currency) || other.currency == _this.currency)&&(identical(other.period, _this.period) || other.period == _this.period)&&(identical(other.startDate, _this.startDate) || other.startDate == _this.startDate)&&(identical(other.alertThreshold, _this.alertThreshold) || other.alertThreshold == _this.alertThreshold)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt)&&(identical(other.updatedAt, _this.updatedAt) || other.updatedAt == _this.updatedAt)&&(identical(other.deletedAt, _this.deletedAt) || other.deletedAt == _this.deletedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as BudgetDto;
  return Object.hash(runtimeType,_this.id,_this.categoryId,_this.amount,_this.currency,_this.period,_this.startDate,_this.alertThreshold,_this.createdAt,_this.updatedAt,_this.deletedAt);
}

@override
String toString() {
  final _this = this as BudgetDto;
  return 'BudgetDto(id: ${_this.id}, categoryId: ${_this.categoryId}, amount: ${_this.amount}, currency: ${_this.currency}, period: ${_this.period}, startDate: ${_this.startDate}, alertThreshold: ${_this.alertThreshold}, createdAt: ${_this.createdAt}, updatedAt: ${_this.updatedAt}, deletedAt: ${_this.deletedAt})';
}


}

/// @nodoc
abstract mixin class $BudgetDtoCopyWith<$Res>  {
  factory $BudgetDtoCopyWith(BudgetDto value, $Res Function(BudgetDto) _then) = _$BudgetDtoCopyWithImpl;
@useResult
$Res call({
 String id, String? categoryId, int amount, String currency, String period,@FirestoreDateTimeConverter() DateTime startDate, int alertThreshold,@FirestoreDateTimeConverter() DateTime createdAt,@FirestoreDateTimeConverter() DateTime updatedAt,@NullableFirestoreDateTimeConverter() DateTime? deletedAt
});




}
/// @nodoc
class _$BudgetDtoCopyWithImpl<$Res>
    implements $BudgetDtoCopyWith<$Res> {
  _$BudgetDtoCopyWithImpl(this._self, this._then);

  final BudgetDto _self;
  final $Res Function(BudgetDto) _then;

/// Create a copy of BudgetDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? categoryId = freezed,Object? amount = null,Object? currency = null,Object? period = null,Object? startDate = null,Object? alertThreshold = null,Object? createdAt = null,Object? updatedAt = null,Object? deletedAt = freezed,}) {
  return _then(BudgetDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,categoryId: freezed == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String?,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as int,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,period: null == period ? _self.period : period // ignore: cast_nullable_to_non_nullable
as String,startDate: null == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime,alertThreshold: null == alertThreshold ? _self.alertThreshold : alertThreshold // ignore: cast_nullable_to_non_nullable
as int,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,deletedAt: freezed == deletedAt ? _self.deletedAt : deletedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [BudgetDto].
extension BudgetDtoPatterns on BudgetDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BudgetDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BudgetDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BudgetDto value)  $default,){
final _that = this;
switch (_that) {
case _BudgetDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BudgetDto value)?  $default,){
final _that = this;
switch (_that) {
case _BudgetDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String? categoryId,  int amount,  String currency,  String period, @FirestoreDateTimeConverter()  DateTime startDate,  int alertThreshold, @FirestoreDateTimeConverter()  DateTime createdAt, @FirestoreDateTimeConverter()  DateTime updatedAt, @NullableFirestoreDateTimeConverter()  DateTime? deletedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BudgetDto() when $default != null:
return $default(_that.id,_that.categoryId,_that.amount,_that.currency,_that.period,_that.startDate,_that.alertThreshold,_that.createdAt,_that.updatedAt,_that.deletedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String? categoryId,  int amount,  String currency,  String period, @FirestoreDateTimeConverter()  DateTime startDate,  int alertThreshold, @FirestoreDateTimeConverter()  DateTime createdAt, @FirestoreDateTimeConverter()  DateTime updatedAt, @NullableFirestoreDateTimeConverter()  DateTime? deletedAt)  $default,) {final _that = this;
switch (_that) {
case _BudgetDto():
return $default(_that.id,_that.categoryId,_that.amount,_that.currency,_that.period,_that.startDate,_that.alertThreshold,_that.createdAt,_that.updatedAt,_that.deletedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String? categoryId,  int amount,  String currency,  String period, @FirestoreDateTimeConverter()  DateTime startDate,  int alertThreshold, @FirestoreDateTimeConverter()  DateTime createdAt, @FirestoreDateTimeConverter()  DateTime updatedAt, @NullableFirestoreDateTimeConverter()  DateTime? deletedAt)?  $default,) {final _that = this;
switch (_that) {
case _BudgetDto() when $default != null:
return $default(_that.id,_that.categoryId,_that.amount,_that.currency,_that.period,_that.startDate,_that.alertThreshold,_that.createdAt,_that.updatedAt,_that.deletedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BudgetDto extends BudgetDto {
  const _BudgetDto({required this.id, this.categoryId, required this.amount, this.currency = AppCurrencies.defaultCode, this.period = 'month', @FirestoreDateTimeConverter() required this.startDate, this.alertThreshold = 80, @FirestoreDateTimeConverter() required this.createdAt, @FirestoreDateTimeConverter() required this.updatedAt, @NullableFirestoreDateTimeConverter() this.deletedAt}): super._();
  factory _BudgetDto.fromJson(Map<String, dynamic> json) => _$BudgetDtoFromJson(json);

@override final  String id;
@override final  String? categoryId;
@override final  int amount;
@override@JsonKey() final  String currency;
@override@JsonKey() final  String period;
@override@FirestoreDateTimeConverter() final  DateTime startDate;
@override@JsonKey() final  int alertThreshold;
@override@FirestoreDateTimeConverter() final  DateTime createdAt;
@override@FirestoreDateTimeConverter() final  DateTime updatedAt;
@override@NullableFirestoreDateTimeConverter() final  DateTime? deletedAt;

/// Create a copy of BudgetDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BudgetDtoCopyWith<_BudgetDto> get copyWith => __$BudgetDtoCopyWithImpl<_BudgetDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BudgetDtoToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BudgetDto&&(identical(other.id, id) || other.id == id)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.period, period) || other.period == period)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.alertThreshold, alertThreshold) || other.alertThreshold == alertThreshold)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.deletedAt, deletedAt) || other.deletedAt == deletedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,categoryId,amount,currency,period,startDate,alertThreshold,createdAt,updatedAt,deletedAt);
}

@override
String toString() {
    return 'BudgetDto(id: $id, categoryId: $categoryId, amount: $amount, currency: $currency, period: $period, startDate: $startDate, alertThreshold: $alertThreshold, createdAt: $createdAt, updatedAt: $updatedAt, deletedAt: $deletedAt)';
}


}

/// @nodoc
abstract mixin class _$BudgetDtoCopyWith<$Res> implements $BudgetDtoCopyWith<$Res> {
  factory _$BudgetDtoCopyWith(_BudgetDto value, $Res Function(_BudgetDto) _then) = __$BudgetDtoCopyWithImpl;
@override @useResult
$Res call({
 String id, String? categoryId, int amount, String currency, String period,@FirestoreDateTimeConverter() DateTime startDate, int alertThreshold,@FirestoreDateTimeConverter() DateTime createdAt,@FirestoreDateTimeConverter() DateTime updatedAt,@NullableFirestoreDateTimeConverter() DateTime? deletedAt
});




}
/// @nodoc
class __$BudgetDtoCopyWithImpl<$Res>
    implements _$BudgetDtoCopyWith<$Res> {
  __$BudgetDtoCopyWithImpl(this._self, this._then);

  final _BudgetDto _self;
  final $Res Function(_BudgetDto) _then;

/// Create a copy of BudgetDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? categoryId = freezed,Object? amount = null,Object? currency = null,Object? period = null,Object? startDate = null,Object? alertThreshold = null,Object? createdAt = null,Object? updatedAt = null,Object? deletedAt = freezed,}) {
  return _then(_BudgetDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,categoryId: freezed == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String?,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as int,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,period: null == period ? _self.period : period // ignore: cast_nullable_to_non_nullable
as String,startDate: null == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime,alertThreshold: null == alertThreshold ? _self.alertThreshold : alertThreshold // ignore: cast_nullable_to_non_nullable
as int,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,deletedAt: freezed == deletedAt ? _self.deletedAt : deletedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
