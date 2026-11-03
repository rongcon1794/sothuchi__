import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:so_thu_chi/core/router/app_router.dart';
import 'package:so_thu_chi/core/theme/app_theme.dart';
import 'package:so_thu_chi/core/widgets/biometric_lock_gate.dart';
import 'package:so_thu_chi/features/settings/domain/entities/app_settings.dart';
import 'package:so_thu_chi/features/settings/presentation/controllers/settings_controller.dart';
import 'package:so_thu_chi/l10n/app_localizations.dart';

/// Wrapper injected around the router content (Biometric App Lock gate by default).
final appRootWrapperProvider =
    Provider<Widget Function(BuildContext, Widget)>((ref) {
      return (_, child) => BiometricLockGate(child: child);
    });

class SoThuChiApp extends ConsumerWidget {
  const SoThuChiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsControllerProvider);
    final settings = settingsAsync.value ?? const AppSettings();
    final router = ref.watch(goRouterProvider);
    final rootWrapper = ref.watch(appRootWrapperProvider);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      onGenerateTitle: (ctx) => AppLocalizations.of(ctx).appTitle,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: settings.themeMode,
      locale: Locale(settings.localeCode),
      supportedLocales: const [
        Locale('vi'),
        Locale('en'),
      ],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: router,
      builder: (context, child) {
        return rootWrapper(context, child ?? const SizedBox.shrink());
      },
    );
  }
}

