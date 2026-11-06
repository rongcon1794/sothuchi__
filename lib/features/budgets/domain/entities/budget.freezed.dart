// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'budget.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Budget {

 String get id;/// `null` means Overall Monthly Budget; non-null targets a specific expense category.
 String? get categoryId; int get amount; String get currency; String get period; DateTime get startDate;/// Percentage (1..100) at which an alert is triggered (default 80%).
 int get alertThreshold; String get ledgerId; DateTime get createdAt; DateTime get updatedAt; DateTime? get deletedAt;
/// Create a copy of Budget
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BudgetCopyWith<Budget> get copyWith => _$BudgetCopyWithImpl<Budget>(this as Budget, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as Budget;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Budget&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.categoryId, _this.categoryId) || other.categoryId == _this.categoryId)&&(identical(other.amount, _this.amount) || other.amount == _this.amount)&&(identical(other.currency, _this.currency) || other.currency == _this.currency)&&(identical(other.period, _this.period) || other.period == _this.period)&&(identical(other.startDate, _this.startDate) || other.startDate == _this.startDate)&&(identical(other.alertThreshold, _this.alertThreshold) || other.alertThreshold == _this.alertThreshold)&&(identical(other.ledgerId, _this.ledgerId) || other.ledgerId == _this.ledgerId)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt)&&(identical(other.updatedAt, _this.updatedAt) || other.updatedAt == _this.updatedAt)&&(identical(other.deletedAt, _this.deletedAt) || other.deletedAt == _this.deletedAt));
}


@override
int get hashCode {
  final _this = this as Budget;
  return Object.hash(runtimeType,_this.id,_this.categoryId,_this.amount,_this.currency,_this.period,_this.startDate,_this.alertThreshold,_this.ledgerId,_this.createdAt,_this.updatedAt,_this.deletedAt);
}

@override
String toString() {
  final _this = this as Budget;
  return 'Budget(id: ${_this.id}, categoryId: ${_this.categoryId}, amount: ${_this.amount}, currency: ${_this.currency}, period: ${_this.period}, startDate: ${_this.startDate}, alertThreshold: ${_this.alertThreshold}, ledgerId: ${_this.ledgerId}, createdAt: ${_this.createdAt}, updatedAt: ${_this.updatedAt}, deletedAt: ${_this.deletedAt})';
}


}

/// @nodoc
abstract mixin class $BudgetCopyWith<$Res>  {
  factory $BudgetCopyWith(Budget value, $Res Function(Budget) _then) = _$BudgetCopyWithImpl;
@useResult
$Res call({
 String id, String? categoryId, int amount, String currency, String period, DateTime startDate, int alertThreshold, String ledgerId, DateTime createdAt, DateTime updatedAt, DateTime? deletedAt
});




}
/// @nodoc
class _$BudgetCopyWithImpl<$Res>
    implements $BudgetCopyWith<$Res> {
  _$BudgetCopyWithImpl(this._self, this._then);

  final Budget _self;
  final $Res Function(Budget) _then;

/// Create a copy of Budget
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? categoryId = freezed,Object? amount = null,Object? currency = null,Object? period = null,Object? startDate = null,Object? alertThreshold = null,Object? ledgerId = null,Object? createdAt = null,Object? updatedAt = null,Object? deletedAt = freezed,}) {
  return _then(Budget(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,categoryId: freezed == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String?,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as int,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,period: null == period ? _self.period : period // ignore: cast_nullable_to_non_nullable
as String,startDate: null == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime,alertThreshold: null == alertThreshold ? _self.alertThreshold : alertThreshold // ignore: cast_nullable_to_non_nullable
as int,ledgerId: null == ledgerId ? _self.ledgerId : ledgerId // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,deletedAt: freezed == deletedAt ? _self.deletedAt : deletedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [Budget].
extension BudgetPatterns on Budget {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Budget value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Budget() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Budget value)  $default,){
final _that = this;
switch (_that) {
case _Budget():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Budget value)?  $default,){
final _that = this;
switch (_that) {
case _Budget() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String? categoryId,  int amount,  String currency,  String period,  DateTime startDate,  int alertThreshold,  String ledgerId,  DateTime createdAt,  DateTime updatedAt,  DateTime? deletedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Budget() when $default != null:
return $default(_that.id,_that.categoryId,_that.amount,_that.currency,_that.period,_that.startDate,_that.alertThreshold,_that.ledgerId,_that.createdAt,_that.updatedAt,_that.deletedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String? categoryId,  int amount,  String currency,  String period,  DateTime startDate,  int alertThreshold,  String ledgerId,  DateTime createdAt,  DateTime updatedAt,  DateTime? deletedAt)  $default,) {final _that = this;
switch (_that) {
case _Budget():
return $default(_that.id,_that.categoryId,_that.amount,_that.currency,_that.period,_that.startDate,_that.alertThreshold,_that.ledgerId,_that.createdAt,_that.updatedAt,_that.deletedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String? categoryId,  int amount,  String currency,  String period,  DateTime startDate,  int alertThreshold,  String ledgerId,  DateTime createdAt,  DateTime updatedAt,  DateTime? deletedAt)?  $default,) {final _that = this;
switch (_that) {
case _Budget() when $default != null:
return $default(_that.id,_that.categoryId,_that.amount,_that.currency,_that.period,_that.startDate,_that.alertThreshold,_that.ledgerId,_that.createdAt,_that.updatedAt,_that.deletedAt);case _:
  return null;

}
}

}

/// @nodoc


class _Budget extends Budget {
  const _Budget({required this.id, this.categoryId, required this.amount, this.currency = AppCurrencies.defaultCode, this.period = 'month', required this.startDate, this.alertThreshold = 80, this.ledgerId = LedgerBook.defaultPersonalId, required this.createdAt, required this.updatedAt, this.deletedAt}): super._();
  

@override final  String id;
/// `null` means Overall Monthly Budget; non-null targets a specific expense category.
@override final  String? categoryId;
@override final  int amount;
@override@JsonKey() final  String currency;
@override@JsonKey() final  String period;
@override final  DateTime startDate;
/// Percentage (1..100) at which an alert is triggered (default 80%).
@override@JsonKey() final  int alertThreshold;
@override@JsonKey() final  String ledgerId;
@override final  DateTime createdAt;
@override final  DateTime updatedAt;
@override final  DateTime? deletedAt;

/// Create a copy of Budget
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BudgetCopyWith<_Budget> get copyWith => __$BudgetCopyWithImpl<_Budget>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Budget&&(identical(other.id, id) || other.id == id)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.period, period) || other.period == period)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.alertThreshold, alertThreshold) || other.alertThreshold == alertThreshold)&&(identical(other.ledgerId, ledgerId) || other.ledgerId == ledgerId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.deletedAt, deletedAt) || other.deletedAt == deletedAt));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,categoryId,amount,currency,period,startDate,alertThreshold,ledgerId,createdAt,updatedAt,deletedAt);
}

@override
String toString() {
    return 'Budget(id: $id, categoryId: $categoryId, amount: $amount, currency: $currency, period: $period, startDate: $startDate, alertThreshold: $alertThreshold, ledgerId: $ledgerId, createdAt: $createdAt, updatedAt: $updatedAt, deletedAt: $deletedAt)';
}


}

/// @nodoc
abstract mixin class _$BudgetCopyWith<$Res> implements $BudgetCopyWith<$Res> {
  factory _$BudgetCopyWith(_Budget value, $Res Function(_Budget) _then) = __$BudgetCopyWithImpl;
@override @useResult
$Res call({
 String id, String? categoryId, int amount, String currency, String period, DateTime startDate, int alertThreshold, String ledgerId, DateTime createdAt, DateTime updatedAt, DateTime? deletedAt
});




}
/// @nodoc
class __$BudgetCopyWithImpl<$Res>
    implements _$BudgetCopyWith<$Res> {
  __$BudgetCopyWithImpl(this._self, this._then);

  final _Budget _self;
  final $Res Function(_Budget) _then;

/// Create a copy of Budget
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? categoryId = freezed,Object? amount = null,Object? currency = null,Object? period = null,Object? startDate = null,Object? alertThreshold = null,Object? ledgerId = null,Object? createdAt = null,Object? updatedAt = null,Object? deletedAt = freezed,}) {
  return _then(_Budget(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,categoryId: freezed == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String?,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as int,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,period: null == period ? _self.period : period // ignore: cast_nullable_to_non_nullable
as String,startDate: null == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime,alertThreshold: null == alertThreshold ? _self.alertThreshold : alertThreshold // ignore: cast_nullable_to_non_nullable
as int,ledgerId: null == ledgerId ? _self.ledgerId : ledgerId // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,deletedAt: freezed == deletedAt ? _self.deletedAt : deletedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
