import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:so_thu_chi/core/constants/currency_constants.dart';
import 'package:so_thu_chi/data/firebase/firestore_timestamp_converter.dart';
import 'package:so_thu_chi/features/auth/domain/entities/app_user.dart';

part 'user_profile_dto.freezed.dart';
part 'user_profile_dto.g.dart';

@freezed
abstract class UserProfileDto with _$UserProfileDto {
  const UserProfileDto._();

  const factory UserProfileDto({
    required String uid,
    @Default('') String email,
    String? displayName,
    String? photoUrl,
    @Default(AppCurrencies.defaultCode) String defaultCurrency,
    @Default('vi') String locale,
    String? themeMode,
    int? accentColorIndex,
    String? defaultWalletId,
    bool? oledMode,
    bool? hideBalance,
    bool? initialSetupCompleted,
    @FirestoreDateTimeConverter() required DateTime createdAt,
    @FirestoreDateTimeConverter() required DateTime updatedAt,
    @NullableFirestoreDateTimeConverter() DateTime? deletedAt,
  }) = _UserProfileDto;

  factory UserProfileDto.fromJson(Map<String, dynamic> json) =>
      _$UserProfileDtoFromJson(json);

  AppUser toDomain({bool isDemoUser = false}) => AppUser(
    uid: uid,
    email: email,
    displayName: displayName,
    photoUrl: photoUrl,
    defaultCurrency: defaultCurrency,
    locale: locale,
    isDemoUser: isDemoUser,
    themeMode: themeMode,
    accentColorIndex: accentColorIndex,
    defaultWalletId: defaultWalletId,
    oledMode: oledMode,
    hideBalance: hideBalance,
    initialSetupCompleted: initialSetupCompleted,
    createdAt: createdAt,
    updatedAt: updatedAt,
    deletedAt: deletedAt,
  );
}

