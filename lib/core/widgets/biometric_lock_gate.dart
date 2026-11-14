import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:so_thu_chi/core/l10n/l10n_ext.dart';
import 'package:so_thu_chi/core/widgets/app_data_loading_view.dart';
import 'package:so_thu_chi/features/accounts/presentation/controllers/accounts_controller.dart';
import 'package:so_thu_chi/features/auth/presentation/controllers/auth_controller.dart';
import 'package:so_thu_chi/features/categories/presentation/controllers/categories_controller.dart';
import 'package:so_thu_chi/features/settings/presentation/controllers/settings_controller.dart';
import 'package:so_thu_chi/features/transactions/presentation/controllers/transactions_controller.dart';

/// Lifecycle-aware Biometric App Lock & Data Reload gate.
///
/// Handles:
/// 1. Cold start / initial launch data warmup: Displays [AppDataLoadingView]
///    with the app logo while settings, authentication, and secure keys resolve.
/// 2. Long idle resume: When the app is resumed after being idle in the background
///    for a significant period (e.g., > 2 minutes), displays a branded data reload
///    screen while refreshing essential data streams so the user never sees a frozen frame.
/// 3. Biometric App Lock: Locks the interface and prompts for biometrics whenever
///    the user is signed in and `biometricLockEnabled` is `true`.
class BiometricLockGate extends ConsumerStatefulWidget {
  const BiometricLockGate({
    required this.child,
    this.longIdleThreshold = const Duration(minutes: 2),
    super.key,
  });

  final Widget child;

  /// Duration after which returning to the app triggers a gentle data reload screen.
  final Duration longIdleThreshold;

  @override
  ConsumerState<BiometricLockGate> createState() => _BiometricLockGateState();
}

class _BiometricLockGateState extends ConsumerState<BiometricLockGate>
    with WidgetsBindingObserver {
  bool _unlockedForSession = false;
  bool _authenticating = false;
  bool _wasBackgrounded = false;
  bool _initialPromptChecked = false;
  bool _isReloadingOnResume = false;
  DateTime? _backgroundedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final enabled =
        ref.read(settingsControllerProvider).value?.biometricLockEnabled ??
        false;
    final hasUser = ref.read(currentUserProvider) != null;

    if (state == AppLifecycleState.paused ||
        (state == AppLifecycleState.inactive && !_authenticating)) {
      _backgroundedAt ??= DateTime.now();
      if (enabled && hasUser) {
        _wasBackgrounded = true;
        if (_unlockedForSession && mounted) {
          setState(() => _unlockedForSession = false);
        }
      }
    } else if (state == AppLifecycleState.resumed) {
      final pausedTime = _backgroundedAt;
      _backgroundedAt = null;

      final isLongIdle = pausedTime != null &&
          DateTime.now().difference(pausedTime) >= widget.longIdleThreshold;

      if (isLongIdle && hasUser) {
        _triggerLongIdleResumeReload();
      }

      if (enabled && hasUser && _wasBackgrounded) {
        _wasBackgrounded = false;
        if (!_unlockedForSession) {
          _triggerUnlock();
        }
      }
    }
  }

  /// Refreshes essential data streams and displays the branded loading screen
  /// for a smooth minimum duration when returning after long inactivity.
  Future<void> _triggerLongIdleResumeReload() async {
    if (_isReloadingOnResume || !mounted) return;
    setState(() => _isReloadingOnResume = true);

    // Invalidate cached data streams to pull fresh data from local DB / Cloud
    try {
      ref
        ..invalidate(rawAccountsStreamProvider)
        ..invalidate(rawTransactionsStreamProvider)
        ..invalidate(categoriesStreamProvider);
    } catch (_) {
      // Safe no-op if providers not active
    }

    // Smooth minimum 650ms display to give visual feedback and avoid frame stutter
    await Future<void>.delayed(const Duration(milliseconds: 650));
    if (mounted) {
      setState(() => _isReloadingOnResume = false);
    }
  }

  Future<void> _triggerUnlock() async {
    if (_authenticating || !mounted) return;
    setState(() => _authenticating = true);
    final reason = context.l10n.biometricPromptReason;
    final ok = await ref
        .read(settingsControllerProvider.notifier)
        .authenticateBiometric(localizedReason: reason);
    if (!mounted) return;
    setState(() {
      _authenticating = false;
      if (ok) {
        _unlockedForSession = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final (settingsLoading, lockEnabled) = ref.watch(
      settingsControllerProvider.select(
        (s) => (s.isLoading, s.value?.biometricLockEnabled ?? false),
      ),
    );
    final authAsync = ref.watch(authStateStreamProvider);
    final user = ref.watch(currentUserProvider);
    final l10n = context.l10n;

    // 1. Initial Launch / Cold Start: Show branded logo loading screen while
    // settings or authentication are loading, never a blank frozen screen.
    if (settingsLoading || (authAsync.isLoading && user == null)) {
      return AppDataLoadingView(
        message: l10n.loadingData,
        subtitle: l10n.syncingDataMessage,
        showScaffold: false,
      );
    }

    // 2. Warm Resume after long idle time: Show branded data reload screen.
    if (_isReloadingOnResume) {
      return AppDataLoadingView(
        message: l10n.appResumeSyncing,
        subtitle: l10n.syncingDataMessage,
        showScaffold: false,
      );
    }

    // 3. If biometric lock is disabled or user not signed in, render child directly.
    if (!lockEnabled || user == null) {
      _unlockedForSession = false;
      _initialPromptChecked = false;
      return widget.child;
    }

    if (!_initialPromptChecked && !_unlockedForSession) {
      _initialPromptChecked = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _triggerUnlock());
    }

    if (_unlockedForSession) {
      return widget.child;
    }

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Stack(
      children: [
        ExcludeFocus(
          child: ExcludeSemantics(
            child: IgnorePointer(
              child: Visibility(
                visible: false,
                maintainState: true,
                child: widget.child,
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: Material(
            color: scheme.surface,
            child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 84,
                        height: 84,
                        decoration: BoxDecoration(
                          color: scheme.primaryContainer,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.fingerprint_rounded,
                          size: 44,
                          color: scheme.primary,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Semantics(
                        header: true,
                        liveRegion: true,
                        child: Text(
                          l10n.appLockedTitle,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineSmall,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        l10n.appLockedSubtitle,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 28),
                      FilledButton.icon(
                        onPressed: _authenticating ? null : _triggerUnlock,
                        icon: const Icon(Icons.lock_open_rounded),
                        label: Text(l10n.unlockNow),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
