import 'package:flutter/material.dart';
import 'package:so_thu_chi/core/l10n/l10n_ext.dart';
import 'package:so_thu_chi/core/widgets/app_data_loading_view.dart';

/// Initial launch splash screen.
///
/// Displayed on cold start while security credentials, initial local databases,
/// and authentication sessions are resolving.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppDataLoadingView(
      message: l10n.loadingData,
      subtitle: l10n.appTagline,
      showScaffold: true,
    );
  }
}
