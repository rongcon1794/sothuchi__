// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'app_user.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AppUser {

 String get uid; String get email; String? get displayName; String? get photoUrl; String get defaultCurrency; String get locale; bool get isDemoUser; String? get themeMode; int? get accentColorIndex; String? get defaultWalletId; bool? get oledMode; bool? get hideBalance; bool? get initialSetupCompleted; DateTime get createdAt; DateTime get updatedAt; DateTime? get deletedAt;
/// Create a copy of AppUser
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AppUserCopyWith<AppUser> get copyWith => _$AppUserCopyWithImpl<AppUser>(this as AppUser, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as AppUser;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AppUser&&(identical(other.uid, _this.uid) || other.uid == _this.uid)&&(identical(other.email, _this.email) || other.email == _this.email)&&(identical(other.displayName, _this.displayName) || other.displayName == _this.displayName)&&(identical(other.photoUrl, _this.photoUrl) || other.photoUrl == _this.photoUrl)&&(identical(other.defaultCurrency, _this.defaultCurrency) || other.defaultCurrency == _this.defaultCurrency)&&(identical(other.locale, _this.locale) || other.locale == _this.locale)&&(identical(other.isDemoUser, _this.isDemoUser) || other.isDemoUser == _this.isDemoUser)&&(identical(other.themeMode, _this.themeMode) || other.themeMode == _this.themeMode)&&(identical(other.accentColorIndex, _this.accentColorIndex) || other.accentColorIndex == _this.accentColorIndex)&&(identical(other.defaultWalletId, _this.defaultWalletId) || other.defaultWalletId == _this.defaultWalletId)&&(identical(other.oledMode, _this.oledMode) || other.oledMode == _this.oledMode)&&(identical(other.hideBalance, _this.hideBalance) || other.hideBalance == _this.hideBalance)&&(identical(other.initialSetupCompleted, _this.initialSetupCompleted) || other.initialSetupCompleted == _this.initialSetupCompleted)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt)&&(identical(other.updatedAt, _this.updatedAt) || other.updatedAt == _this.updatedAt)&&(identical(other.deletedAt, _this.deletedAt) || other.deletedAt == _this.deletedAt));
}


@override
int get hashCode {
  final _this = this as AppUser;
  return Object.hash(runtimeType,_this.uid,_this.email,_this.displayName,_this.photoUrl,_this.defaultCurrency,_this.locale,_this.isDemoUser,_this.themeMode,_this.accentColorIndex,_this.defaultWalletId,_this.oledMode,_this.hideBalance,_this.initialSetupCompleted,_this.createdAt,_this.updatedAt,_this.deletedAt);
}

@override
String toString() {
  final _this = this as AppUser;
  return 'AppUser(uid: ${_this.uid}, email: ${_this.email}, displayName: ${_this.displayName}, photoUrl: ${_this.photoUrl}, defaultCurrency: ${_this.defaultCurrency}, locale: ${_this.locale}, isDemoUser: ${_this.isDemoUser}, themeMode: ${_this.themeMode}, accentColorIndex: ${_this.accentColorIndex}, defaultWalletId: ${_this.defaultWalletId}, oledMode: ${_this.oledMode}, hideBalance: ${_this.hideBalance}, initialSetupCompleted: ${_this.initialSetupCompleted}, createdAt: ${_this.createdAt}, updatedAt: ${_this.updatedAt}, deletedAt: ${_this.deletedAt})';
}


}

/// @nodoc
abstract mixin class $AppUserCopyWith<$Res>  {
  factory $AppUserCopyWith(AppUser value, $Res Function(AppUser) _then) = _$AppUserCopyWithImpl;
@useResult
$Res call({
 String uid, String email, String? displayName, String? photoUrl, String defaultCurrency, String locale, bool isDemoUser, String? themeMode, int? accentColorIndex, String? defaultWalletId, bool? oledMode, bool? hideBalance, bool? initialSetupCompleted, DateTime createdAt, DateTime updatedAt, DateTime? deletedAt
});




}
/// @nodoc
class _$AppUserCopyWithImpl<$Res>
    implements $AppUserCopyWith<$Res> {
  _$AppUserCopyWithImpl(this._self, this._then);

  final AppUser _self;
  final $Res Function(AppUser) _then;

/// Create a copy of AppUser
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? uid = null,Object? email = null,Object? displayName = freezed,Object? photoUrl = freezed,Object? defaultCurrency = null,Object? locale = null,Object? isDemoUser = null,Object? themeMode = freezed,Object? accentColorIndex = freezed,Object? defaultWalletId = freezed,Object? oledMode = freezed,Object? hideBalance = freezed,Object? initialSetupCompleted = freezed,Object? createdAt = null,Object? updatedAt = null,Object? deletedAt = freezed,}) {
  return _then(AppUser(
uid: null == uid ? _self.uid : uid // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,displayName: freezed == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String?,photoUrl: freezed == photoUrl ? _self.photoUrl : photoUrl // ignore: cast_nullable_to_non_nullable
as String?,defaultCurrency: null == defaultCurrency ? _self.defaultCurrency : defaultCurrency // ignore: cast_nullable_to_non_nullable
as String,locale: null == locale ? _self.locale : locale // ignore: cast_nullable_to_non_nullable
as String,isDemoUser: null == isDemoUser ? _self.isDemoUser : isDemoUser // ignore: cast_nullable_to_non_nullable
as bool,themeMode: freezed == themeMode ? _self.themeMode : themeMode // ignore: cast_nullable_to_non_nullable
as String?,accentColorIndex: freezed == accentColorIndex ? _self.accentColorIndex : accentColorIndex // ignore: cast_nullable_to_non_nullable
as int?,defaultWalletId: freezed == defaultWalletId ? _self.defaultWalletId : defaultWalletId // ignore: cast_nullable_to_non_nullable
as String?,oledMode: freezed == oledMode ? _self.oledMode : oledMode // ignore: cast_nullable_to_non_nullable
as bool?,hideBalance: freezed == hideBalance ? _self.hideBalance : hideBalance // ignore: cast_nullable_to_non_nullable
as bool?,initialSetupCompleted: freezed == initialSetupCompleted ? _self.initialSetupCompleted : initialSetupCompleted // ignore: cast_nullable_to_non_nullable
as bool?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,deletedAt: freezed == deletedAt ? _self.deletedAt : deletedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [AppUser].
extension AppUserPatterns on AppUser {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AppUser value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AppUser() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AppUser value)  $default,){
final _that = this;
switch (_that) {
case _AppUser():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AppUser value)?  $default,){
final _that = this;
switch (_that) {
case _AppUser() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String uid,  String email,  String? displayName,  String? photoUrl,  String defaultCurrency,  String locale,  bool isDemoUser,  String? themeMode,  int? accentColorIndex,  String? defaultWalletId,  bool? oledMode,  bool? hideBalance,  bool? initialSetupCompleted,  DateTime createdAt,  DateTime updatedAt,  DateTime? deletedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AppUser() when $default != null:
return $default(_that.uid,_that.email,_that.displayName,_that.photoUrl,_that.defaultCurrency,_that.locale,_that.isDemoUser,_that.themeMode,_that.accentColorIndex,_that.defaultWalletId,_that.oledMode,_that.hideBalance,_that.initialSetupCompleted,_that.createdAt,_that.updatedAt,_that.deletedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String uid,  String email,  String? displayName,  String? photoUrl,  String defaultCurrency,  String locale,  bool isDemoUser,  String? themeMode,  int? accentColorIndex,  String? defaultWalletId,  bool? oledMode,  bool? hideBalance,  bool? initialSetupCompleted,  DateTime createdAt,  DateTime updatedAt,  DateTime? deletedAt)  $default,) {final _that = this;
switch (_that) {
case _AppUser():
return $default(_that.uid,_that.email,_that.displayName,_that.photoUrl,_that.defaultCurrency,_that.locale,_that.isDemoUser,_that.themeMode,_that.accentColorIndex,_that.defaultWalletId,_that.oledMode,_that.hideBalance,_that.initialSetupCompleted,_that.createdAt,_that.updatedAt,_that.deletedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String uid,  String email,  String? displayName,  String? photoUrl,  String defaultCurrency,  String locale,  bool isDemoUser,  String? themeMode,  int? accentColorIndex,  String? defaultWalletId,  bool? oledMode,  bool? hideBalance,  bool? initialSetupCompleted,  DateTime createdAt,  DateTime updatedAt,  DateTime? deletedAt)?  $default,) {final _that = this;
switch (_that) {
case _AppUser() when $default != null:
return $default(_that.uid,_that.email,_that.displayName,_that.photoUrl,_that.defaultCurrency,_that.locale,_that.isDemoUser,_that.themeMode,_that.accentColorIndex,_that.defaultWalletId,_that.oledMode,_that.hideBalance,_that.initialSetupCompleted,_that.createdAt,_that.updatedAt,_that.deletedAt);case _:
  return null;

}
}

}

/// @nodoc


class _AppUser implements AppUser {
  const _AppUser({required this.uid, required this.email, this.displayName, this.photoUrl, this.defaultCurrency = AppCurrencies.defaultCode, this.locale = 'vi', this.isDemoUser = false, this.themeMode, this.accentColorIndex, this.defaultWalletId, this.oledMode, this.hideBalance, this.initialSetupCompleted, required this.createdAt, required this.updatedAt, this.deletedAt});
  

@override final  String uid;
@override final  String email;
@override final  String? displayName;
@override final  String? photoUrl;
@override@JsonKey() final  String defaultCurrency;
@override@JsonKey() final  String locale;
@override@JsonKey() final  bool isDemoUser;
@override final  String? themeMode;
@override final  int? accentColorIndex;
@override final  String? defaultWalletId;
@override final  bool? oledMode;
@override final  bool? hideBalance;
@override final  bool? initialSetupCompleted;
@override final  DateTime createdAt;
@override final  DateTime updatedAt;
@override final  DateTime? deletedAt;

/// Create a copy of AppUser
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AppUserCopyWith<_AppUser> get copyWith => __$AppUserCopyWithImpl<_AppUser>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _AppUser&&(identical(other.uid, uid) || other.uid == uid)&&(identical(other.email, email) || other.email == email)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.photoUrl, photoUrl) || other.photoUrl == photoUrl)&&(identical(other.defaultCurrency, defaultCurrency) || other.defaultCurrency == defaultCurrency)&&(identical(other.locale, locale) || other.locale == locale)&&(identical(other.isDemoUser, isDemoUser) || other.isDemoUser == isDemoUser)&&(identical(other.themeMode, themeMode) || other.themeMode == themeMode)&&(identical(other.accentColorIndex, accentColorIndex) || other.accentColorIndex == accentColorIndex)&&(identical(other.defaultWalletId, defaultWalletId) || other.defaultWalletId == defaultWalletId)&&(identical(other.oledMode, oledMode) || other.oledMode == oledMode)&&(identical(other.hideBalance, hideBalance) || other.hideBalance == hideBalance)&&(identical(other.initialSetupCompleted, initialSetupCompleted) || other.initialSetupCompleted == initialSetupCompleted)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.deletedAt, deletedAt) || other.deletedAt == deletedAt));
}


@override
int get hashCode {
    return Object.hash(runtimeType,uid,email,displayName,photoUrl,defaultCurrency,locale,isDemoUser,themeMode,accentColorIndex,defaultWalletId,oledMode,hideBalance,initialSetupCompleted,createdAt,updatedAt,deletedAt);
}

@override
String toString() {
    return 'AppUser(uid: $uid, email: $email, displayName: $displayName, photoUrl: $photoUrl, defaultCurrency: $defaultCurrency, locale: $locale, isDemoUser: $isDemoUser, themeMode: $themeMode, accentColorIndex: $accentColorIndex, defaultWalletId: $defaultWalletId, oledMode: $oledMode, hideBalance: $hideBalance, initialSetupCompleted: $initialSetupCompleted, createdAt: $createdAt, updatedAt: $updatedAt, deletedAt: $deletedAt)';
}


}

/// @nodoc
abstract mixin class _$AppUserCopyWith<$Res> implements $AppUserCopyWith<$Res> {
  factory _$AppUserCopyWith(_AppUser value, $Res Function(_AppUser) _then) = __$AppUserCopyWithImpl;
@override @useResult
$Res call({
 String uid, String email, String? displayName, String? photoUrl, String defaultCurrency, String locale, bool isDemoUser, String? themeMode, int? accentColorIndex, String? defaultWalletId, bool? oledMode, bool? hideBalance, bool? initialSetupCompleted, DateTime createdAt, DateTime updatedAt, DateTime? deletedAt
});




}
/// @nodoc
class __$AppUserCopyWithImpl<$Res>
    implements _$AppUserCopyWith<$Res> {
  __$AppUserCopyWithImpl(this._self, this._then);

  final _AppUser _self;
  final $Res Function(_AppUser) _then;

/// Create a copy of AppUser
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? uid = null,Object? email = null,Object? displayName = freezed,Object? photoUrl = freezed,Object? defaultCurrency = null,Object? locale = null,Object? isDemoUser = null,Object? themeMode = freezed,Object? accentColorIndex = freezed,Object? defaultWalletId = freezed,Object? oledMode = freezed,Object? hideBalance = freezed,Object? initialSetupCompleted = freezed,Object? createdAt = null,Object? updatedAt = null,Object? deletedAt = freezed,}) {
  return _then(_AppUser(
uid: null == uid ? _self.uid : uid // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,displayName: freezed == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String?,photoUrl: freezed == photoUrl ? _self.photoUrl : photoUrl // ignore: cast_nullable_to_non_nullable
as String?,defaultCurrency: null == defaultCurrency ? _self.defaultCurrency : defaultCurrency // ignore: cast_nullable_to_non_nullable
as String,locale: null == locale ? _self.locale : locale // ignore: cast_nullable_to_non_nullable
as String,isDemoUser: null == isDemoUser ? _self.isDemoUser : isDemoUser // ignore: cast_nullable_to_non_nullable
as bool,themeMode: freezed == themeMode ? _self.themeMode : themeMode // ignore: cast_nullable_to_non_nullable
as String?,accentColorIndex: freezed == accentColorIndex ? _self.accentColorIndex : accentColorIndex // ignore: cast_nullable_to_non_nullable
as int?,defaultWalletId: freezed == defaultWalletId ? _self.defaultWalletId : defaultWalletId // ignore: cast_nullable_to_non_nullable
as String?,oledMode: freezed == oledMode ? _self.oledMode : oledMode // ignore: cast_nullable_to_non_nullable
as bool?,hideBalance: freezed == hideBalance ? _self.hideBalance : hideBalance // ignore: cast_nullable_to_non_nullable
as bool?,initialSetupCompleted: freezed == initialSetupCompleted ? _self.initialSetupCompleted : initialSetupCompleted // ignore: cast_nullable_to_non_nullable
as bool?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,deletedAt: freezed == deletedAt ? _self.deletedAt : deletedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
