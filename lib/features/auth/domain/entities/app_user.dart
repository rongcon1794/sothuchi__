import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:so_thu_chi/core/constants/currency_constants.dart';

part 'app_user.freezed.dart';

@freezed
abstract class AppUser with _$AppUser {
  const factory AppUser({
    required String uid,
    required String email,
    String? displayName,
    String? photoUrl,
    @Default(AppCurrencies.defaultCode) String defaultCurrency,
    @Default('vi') String locale,
    @Default(false) bool isDemoUser,
    String? themeMode,
    int? accentColorIndex,
    String? defaultWalletId,
    bool? oledMode,
    bool? hideBalance,
    bool? initialSetupCompleted,
    required DateTime createdAt,
    required DateTime updatedAt,
    DateTime? deletedAt,
  }) = _AppUser;
}

