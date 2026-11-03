import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:so_thu_chi/core/l10n/l10n_ext.dart';
import 'package:so_thu_chi/features/auth/presentation/controllers/auth_controller.dart';
import 'package:so_thu_chi/features/settings/presentation/controllers/settings_controller.dart';

/// Lifecycle-aware Biometric App Lock shield.
///
/// Locks the interface on cold start and immediately on app backgrounding
/// whenever the user is signed in and `biometricLockEnabled` is `true`.
class BiometricLockGate extends ConsumerStatefulWidget {
  const BiometricLockGate({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<BiometricLockGate> createState() => _BiometricLockGateState();
}

class _BiometricLockGateState extends ConsumerState<BiometricLockGate>
    with WidgetsBindingObserver {
  bool _unlockedForSession = false;
  bool _authenticating = false;
  bool _wasBackgrounded = false;
  bool _initialPromptChecked = false;

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
    if (!enabled || !hasUser) return;

    if (state == AppLifecycleState.paused ||
        (state == AppLifecycleState.inactive && !_authenticating)) {
      _wasBackgrounded = true;
      if (_unlockedForSession && mounted) {
        setState(() => _unlockedForSession = false);
      }
    } else if (state == AppLifecycleState.resumed && _wasBackgrounded) {
      _wasBackgrounded = false;
      if (!_unlockedForSession) {
        _triggerUnlock();
      }
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
    final settingsAsync = ref.watch(settingsControllerProvider);
    final authAsync = ref.watch(authStateStreamProvider);
    final user = ref.watch(currentUserProvider);

    // Never reveal or mark unlocked while secure storage / auth session is still loading.
    if (settingsAsync.isLoading || (authAsync.isLoading && user == null)) {
      return Material(
        color: Theme.of(context).colorScheme.surface,
        child: const SizedBox.expand(),
      );
    }

    final lockEnabled = settingsAsync.value?.biometricLockEnabled ?? false;

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

    final l10n = context.l10n;
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
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
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
      ],
    );
  }
}
