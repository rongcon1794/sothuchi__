import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:so_thu_chi/core/constants/currency_constants.dart';
import 'package:so_thu_chi/core/constants/icon_catalog.dart';
import 'package:so_thu_chi/core/l10n/l10n_ext.dart';
import 'package:so_thu_chi/core/router/app_routes.dart';
import 'package:so_thu_chi/core/theme/apple_theme_tokens.dart';
import 'package:so_thu_chi/core/utils/money.dart';
import 'package:so_thu_chi/core/widgets/apple_kit.dart';
import 'package:so_thu_chi/features/accounts/domain/entities/account.dart';
import 'package:so_thu_chi/features/auth/presentation/controllers/auth_controller.dart';
import 'package:so_thu_chi/features/auth/presentation/controllers/initial_setup_controller.dart';

class _WalletQuickTemplate {
  const _WalletQuickTemplate({
    required this.name,
    required this.type,
    required this.icon,
    required this.color,
  });

  final String name;
  final AccountType type;
  final String icon;
  final int color;
}

class InitialSetupScreen extends ConsumerStatefulWidget {
  const InitialSetupScreen({super.key});

  @override
  ConsumerState<InitialSetupScreen> createState() => _InitialSetupScreenState();
}

class _InitialSetupScreenState extends ConsumerState<InitialSetupScreen> {
  static const List<_WalletQuickTemplate> _quickTemplates = [
    _WalletQuickTemplate(
      name: 'Tiền mặt',
      type: AccountType.cash,
      icon: 'cash',
      color: 0xFF00A86B,
    ),
    _WalletQuickTemplate(
      name: 'Techcombank',
      type: AccountType.bank,
      icon: 'bank',
      color: 0xFFE50914,
    ),
    _WalletQuickTemplate(
      name: 'Vietcombank',
      type: AccountType.bank,
      icon: 'bank',
      color: 0xFF008848,
    ),
    _WalletQuickTemplate(
      name: 'MB Bank',
      type: AccountType.bank,
      icon: 'bank',
      color: 0xFF1428A0,
    ),
    _WalletQuickTemplate(
      name: 'Ví MoMo',
      type: AccountType.ewallet,
      icon: 'ewallet',
      color: 0xFFA259FF,
    ),
    _WalletQuickTemplate(
      name: 'ZaloPay',
      type: AccountType.ewallet,
      icon: 'ewallet',
      color: 0xFF008FE5,
    ),
  ];

  static const List<int> _paletteColors = [
    0xFF00A86B, // Emerald Green
    0xFF007AFF, // Apple Blue
    0xFF8E44AD, // Royal Purple
    0xFFFF9500, // Amber Orange
    0xFFFF3B30, // Coral Red
    0xFF00C7BE, // Teal
  ];

  late final PageController _pageController;
  int _currentStep = 0; // 0 = Tạo ví, 1 = Thiết lập ngân sách
  bool _isCheckingExistingData = true;
  bool _isSaving = false;

  // Step 1: Wallet Fields
  late final TextEditingController _walletNameController;
  late final TextEditingController _walletBalanceController;
  AccountType _walletType = AccountType.cash;
  int _walletBalance = 500000;
  String _walletIcon = 'cash';
  int _walletColor = 0xFF00A86B;
  final String _selectedCurrency = AppCurrencies.defaultCode;

  // Step 2: Budget Fields
  late final TextEditingController _budgetController;
  int _budgetAmount = 5000000;
  int _budgetAlertThreshold = 80;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _walletNameController = TextEditingController(text: 'Tiền mặt');
    _walletBalanceController = TextEditingController(text: '500.000');
    _budgetController = TextEditingController(text: '5.000.000');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndRestoreIfExisting();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _walletNameController.dispose();
    _walletBalanceController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  Future<void> _checkAndRestoreIfExisting() async {
    final user = ref.read(currentUserProvider);
    if (user != null) {
      final restored = await ref
          .read(initialSetupControllerProvider.notifier)
          .checkAndRestoreIfExisting(user.uid);
      if (restored && mounted) {
        try {
          context.go(AppRoutes.home);
        } catch (_) {}
        return;
      }
    }
    if (mounted) {
      setState(() => _isCheckingExistingData = false);
    }
  }

  void _onTemplateSelected(_WalletQuickTemplate template) {
    unawaited(HapticFeedback.selectionClick());
    setState(() {
      _walletNameController.text = template.name;
      _walletType = template.type;
      _walletIcon = template.icon;
      _walletColor = template.color;
    });
  }

  void _setInitialBalancePreset(int amount) {
    unawaited(HapticFeedback.selectionClick());
    setState(() {
      _walletBalance = amount;
      _walletBalanceController.text = Money(
        minorUnits: amount,
        currencyCode: _selectedCurrency,
      ).toInputString();
    });
  }

  void _setBudgetPreset(int amount) {
    unawaited(HapticFeedback.selectionClick());
    setState(() {
      _budgetAmount = amount;
      _budgetController.text = Money(
        minorUnits: amount,
        currencyCode: _selectedCurrency,
      ).toInputString();
    });
  }

  void _goToStep2() {
    unawaited(HapticFeedback.lightImpact());
    if (_walletNameController.text.trim().isEmpty) {
      final isVi = Localizations.localeOf(context).languageCode == 'vi';
      _walletNameController.text = isVi ? 'Tiền mặt' : 'Cash';
    }
    setState(() => _currentStep = 1);
    _pageController.animateToPage(
      1,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeInOutCubic,
    );
  }

  void _goBackToStep1() {
    unawaited(HapticFeedback.lightImpact());
    setState(() => _currentStep = 0);
    _pageController.animateToPage(
      0,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeInOutCubic,
    );
  }

  Future<void> _completeSetup({bool includeBudget = true}) async {
    if (_isSaving) return;
    unawaited(HapticFeedback.mediumImpact());
    setState(() => _isSaving = true);

    final isVi = Localizations.localeOf(context).languageCode == 'vi';
    try {
      final user = ref.read(currentUserProvider);
      final walletName = _walletNameController.text.trim().isEmpty
          ? (isVi ? 'Tiền mặt' : 'Cash')
          : _walletNameController.text.trim();
      final effectiveWalletBalance = Money.tryParse(
            _walletBalanceController.text,
            currencyCode: _selectedCurrency,
          )?.minorUnits ??
          _walletBalance;
      final effectiveBudgetAmount = Money.tryParse(
            _budgetController.text,
            currencyCode: _selectedCurrency,
          )?.minorUnits ??
          _budgetAmount;

      final res = await ref
          .read(initialSetupControllerProvider.notifier)
          .completeInitialOnboarding(
            walletName: walletName,
            walletType: _walletType,
            initialBalance: effectiveWalletBalance,
            icon: _walletIcon,
            color: _walletColor,
            currency: _selectedCurrency,
            monthlyBudgetAmount: includeBudget && effectiveBudgetAmount > 0
                ? effectiveBudgetAmount
                : null,
            budgetAlertThreshold: _budgetAlertThreshold,
            uid: user?.uid,
          );

      if (!mounted) return;
      if (res.isSuccess) {
        try {
          context.go(AppRoutes.home);
        } catch (_) {}
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.localizeError(res.errorOrNull!))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isVi ? 'Lỗi thiết lập: $e' : 'Setup error: $e',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _skipAndUseDefaults() async {
    if (_isSaving) return;
    unawaited(HapticFeedback.mediumImpact());
    setState(() => _isSaving = true);
    final user = ref.read(currentUserProvider);
    final res = await ref
        .read(initialSetupControllerProvider.notifier)
        .applyQuickDefaults(uid: user?.uid);
    if (!mounted) return;
    if (res.isSuccess) {
      try {
        context.go(AppRoutes.home);
      } catch (_) {}
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.localizeError(res.errorOrNull!))),
      );
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isVi = Localizations.localeOf(context).languageCode == 'vi';

    if (_isCheckingExistingData) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CupertinoActivityIndicator(radius: 14),
              const SizedBox(height: 16),
              Text(
                isVi
                    ? 'Đang kiểm tra dữ liệu tài khoản...'
                    : 'Checking account data...',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return PopScope(
      canPop: _currentStep == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _currentStep == 1 && !_isSaving) {
          _goBackToStep1();
        }
      },
      child: AppleEdgeSwipeToDismiss(
        edgeWidth: 44.0,
        threshold: 72.0,
        onDismiss: () {
          if (_currentStep == 1 && !_isSaving) {
            _goBackToStep1();
          }
        },
        child: Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: _currentStep == 1
                ? IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                    onPressed: _isSaving ? null : _goBackToStep1,
                    tooltip: isVi ? 'Quay lại ví' : 'Back to wallet',
                  )
                : null,
            title: _buildStepIndicator(),
            centerTitle: true,
            actions: [
              if (_currentStep == 0)
                TextButton(
                  onPressed: _isSaving ? null : _skipAndUseDefaults,
                  child: Text(
                    isVi ? 'Bỏ qua' : 'Skip',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              const SizedBox(width: 8),
            ],
          ),
          body: SafeArea(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildStep1WalletView(),
                _buildStep2BudgetView(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildStepSegment(isActive: true, isCurrent: _currentStep == 0),
        const SizedBox(width: 6),
        _buildStepSegment(
          isActive: _currentStep >= 1,
          isCurrent: _currentStep == 1,
        ),
      ],
    );
  }

  Widget _buildStepSegment({
    required bool isActive,
    required bool isCurrent,
  }) {
    final primary = Theme.of(context).colorScheme.primary;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: isCurrent ? 28 : 16,
      height: 4,
      decoration: BoxDecoration(
        color: isActive
            ? primary
            : Theme.of(context).dividerColor.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  // -------------------------------------------------------------
  // STEP 1: TẠO VÍ TIỀN ĐẦU TIÊN
  // -------------------------------------------------------------
  Widget _buildStep1WalletView() {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step Badge & Title
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
            ),
            child: Text(
              Localizations.localeOf(context).languageCode == 'vi'
                  ? 'Bước 1 / 2 • Tạo ví tiền đầu tiên'
                  : 'Step 1 / 2 • Create your first wallet',
              style: TextStyle(
                color: scheme.primary,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            Localizations.localeOf(context).languageCode == 'vi'
                ? 'Tạo ví tiền đầu tiên'
                : 'Create your first wallet',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            Localizations.localeOf(context).languageCode == 'vi'
                ? 'Bắt đầu ghi chép chi tiêu bằng cách thêm ví hoặc tài khoản chính bạn đang sử dụng.'
                : 'Start tracking your finances by adding your main wallet or bank account.',
            style: TextStyle(
              fontSize: 13.5,
              color: scheme.onSurface.withValues(alpha: 0.65),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),

          // Live Wallet Preview Card
          _buildWalletPreviewCard(isDark),
          const SizedBox(height: 20),

          // Quick templates
          Text(
            Localizations.localeOf(context).languageCode == 'vi'
                ? 'Gợi ý nhanh'
                : 'Quick suggestions',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: scheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _quickTemplates.map((template) {
                final isSelected =
                    _walletNameController.text == template.name &&
                    _walletType == template.type;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(template.name),
                    selected: isSelected,
                    onSelected: (_) => _onTemplateSelected(template),
                    avatar: Icon(
                      AppIconCatalog.resolve(template.icon),
                      size: 16,
                      color: Color(template.color),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),

          // Wallet Name
          AppleTextField(
            controller: _walletNameController,
            label: Localizations.localeOf(context).languageCode == 'vi'
                ? 'Tên ví'
                : 'Wallet name',
            placeholder: Localizations.localeOf(context).languageCode == 'vi'
                ? 'Ví dụ: Tiền mặt, Techcombank, MoMo...'
                : 'e.g. Cash, Bank, E-Wallet...',
            clearable: true,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 14),

          // Wallet Type
          Text(
            Localizations.localeOf(context).languageCode == 'vi'
                ? 'Loại ví'
                : 'Wallet type',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: scheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildTypeChip(
                Localizations.localeOf(context).languageCode == 'vi'
                    ? 'Tiền mặt'
                    : 'Cash',
                AccountType.cash,
                'cash',
              ),
              const SizedBox(width: 8),
              _buildTypeChip(
                Localizations.localeOf(context).languageCode == 'vi'
                    ? 'Ngân hàng'
                    : 'Bank',
                AccountType.bank,
                'bank',
              ),
              const SizedBox(width: 8),
              _buildTypeChip(
                Localizations.localeOf(context).languageCode == 'vi'
                    ? 'Ví điện tử'
                    : 'E-Wallet',
                AccountType.ewallet,
                'ewallet',
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Initial Balance
          AppleTextField(
            controller: _walletBalanceController,
            label: Localizations.localeOf(context).languageCode == 'vi'
                ? 'Số dư ban đầu'
                : 'Initial balance',
            placeholder: '0',
            keyboardType: TextInputType.number,
            inputFormatters: [
              MoneyInputFormatter(
                currencyCode: _selectedCurrency,
                locale: Localizations.localeOf(context).languageCode,
              ),
            ],
            suffix: Text(
              AppCurrencies.byCode(_selectedCurrency).symbol,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            onChanged: (text) {
              final parsed = Money.tryParse(
                text,
                currencyCode: _selectedCurrency,
              );
              setState(() {
                _walletBalance = parsed?.minorUnits ?? 0;
              });
            },
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildBalancePresetChip(0, '0 ₫'),
                _buildBalancePresetChip(500000, '500.000 ₫'),
                _buildBalancePresetChip(1000000, '1.000.000 ₫'),
                _buildBalancePresetChip(2000000, '2.000.000 ₫'),
                _buildBalancePresetChip(5000000, '5.000.000 ₫'),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Color & Icon Picker
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      Localizations.localeOf(context).languageCode == 'vi'
                          ? 'Màu sắc'
                          : 'Color',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: _paletteColors.map((c) {
                        final isSelected = _walletColor == c;
                        return GestureDetector(
                          onTap: () {
                            unawaited(HapticFeedback.selectionClick());
                            setState(() => _walletColor = c);
                          },
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: Color(c),
                              shape: BoxShape.circle,
                              border: isSelected
                                  ? Border.all(
                                      color: scheme.onSurface,
                                      width: 2.5,
                                    )
                                  : null,
                            ),
                            child: isSelected
                                ? const Icon(
                                    Icons.check_rounded,
                                    size: 16,
                                    color: Colors.white,
                                  )
                                : null,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      Localizations.localeOf(context).languageCode == 'vi'
                          ? 'Biểu tượng'
                          : 'Icon',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 8),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: EdgeInsets.zero,
                      itemCount: AppIconCatalog.walletKeys.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 5,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        childAspectRatio: 1.0,
                      ),
                      itemBuilder: (context, index) {
                        final iconKey = AppIconCatalog.walletKeys[index];
                        final isSelected = _walletIcon == iconKey;
                        return GestureDetector(
                          onTap: () {
                            unawaited(HapticFeedback.selectionClick());
                            setState(() => _walletIcon = iconKey);
                          },
                          child: Container(
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? scheme.primary.withValues(alpha: 0.2)
                                  : scheme.surfaceContainerHighest
                                      .withValues(alpha: 0.5),
                              borderRadius:
                                  BorderRadius.circular(AppleTokens.radiusPill),
                              border: isSelected
                                  ? Border.all(
                                      color: scheme.primary,
                                      width: 1.5,
                                    )
                                  : null,
                            ),
                            child: Icon(
                              AppIconCatalog.resolve(iconKey),
                              size: 18,
                              color:
                                  isSelected ? scheme.primary : scheme.onSurface,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // Continue Button to Step 2
          AppleButton.primary(
            label: Localizations.localeOf(context).languageCode == 'vi'
                ? 'Tiếp tục: Thiết lập ngân sách'
                : 'Continue: Set up budget',
            icon: const Icon(Icons.arrow_forward_rounded, size: 20),
            onPressed: _goToStep2,
          ),
          const SizedBox(height: 10),
          Center(
            child: TextButton(
              onPressed: _isSaving ? null : _skipAndUseDefaults,
              child: Text(
                Localizations.localeOf(context).languageCode == 'vi'
                    ? 'Bỏ qua & Sử dụng cấu hình cơ bản'
                    : 'Skip & Use default setup',
                style: TextStyle(
                  fontSize: 13,
                  color: scheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildWalletPreviewCard(bool isDark) {
    final isVi = Localizations.localeOf(context).languageCode == 'vi';
    final currencyInfo = AppCurrencies.byCode(_selectedCurrency);
    final walletName = _walletNameController.text.trim().isEmpty
        ? (isVi ? 'Tên ví' : 'Wallet name')
        : _walletNameController.text.trim();
    final balanceText = Money(
      minorUnits: _walletBalance,
      currencyCode: _selectedCurrency,
    ).format(locale: Localizations.localeOf(context).languageCode);

    final typeLabel = switch (_walletType) {
      AccountType.cash => isVi ? 'Tiền mặt' : 'Cash',
      AccountType.bank => isVi ? 'Tài khoản Ngân hàng' : 'Bank Account',
      AccountType.ewallet => isVi ? 'Ví điện tử' : 'E-Wallet',
      _ => isVi ? 'Tài khoản' : 'Account',
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(_walletColor),
            Color(_walletColor).withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
        boxShadow: [
          BoxShadow(
            color: Color(_walletColor).withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  AppIconCatalog.resolve(_walletIcon),
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
                ),
                child: Text(
                  typeLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            walletName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                balanceText,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                currencyInfo.code,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.75),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTypeChip(String label, AccountType type, String iconKey) {
    final isSelected = _walletType == type;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          unawaited(HapticFeedback.selectionClick());
          setState(() {
            _walletType = type;
            _walletIcon = iconKey;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected
                ? scheme.primary
                : scheme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
            border: Border.all(
              color: isSelected
                  ? scheme.primary
                  : theme.dividerColor.withValues(alpha: 0.15),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : scheme.onSurface,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              fontSize: 12.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBalancePresetChip(int amount, String label) {
    final isSelected = _walletBalance == amount;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ActionChip(
        label: Text(label),
        onPressed: () => _setInitialBalancePreset(amount),
        backgroundColor: isSelected
            ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.15)
            : null,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // STEP 2: THIẾT LẬP NGÂN SÁCH
  // -------------------------------------------------------------
  Widget _buildStep2BudgetView() {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step Badge & Title
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: LucianTokens.resolveMint(isDark).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
            ),
            child: Text(
              Localizations.localeOf(context).languageCode == 'vi'
                  ? 'Bước 2 / 2 • Thiết lập ngân sách'
                  : 'Step 2 / 2 • Set up budget',
              style: TextStyle(
                color: LucianTokens.resolveMint(isDark),
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            Localizations.localeOf(context).languageCode == 'vi'
                ? 'Thiết lập ngân sách tháng'
                : 'Set monthly budget',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            Localizations.localeOf(context).languageCode == 'vi'
                ? 'Đặt hạn mức chi tiêu hàng tháng để ứng dụng nhắc nhở và giữ nhịp chi an toàn mỗi ngày.'
                : 'Set a monthly spending limit so the app can remind you and keep a safe daily pace.',
            style: TextStyle(
              fontSize: 13.5,
              color: scheme.onSurface.withValues(alpha: 0.65),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),

          // Educational Value Card
          AppleGlassCard(
            padding: const EdgeInsets.all(16),
            borderColor: LucianTokens.resolveMint(isDark).withValues(alpha: 0.4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: LucianTokens.resolveMint(isDark).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.insights_rounded,
                    color: LucianTokens.resolveMint(isDark),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        Localizations.localeOf(context).languageCode == 'vi'
                            ? 'Kiểm soát chi tiêu thông minh'
                            : 'Smart spending control',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        Localizations.localeOf(context).languageCode == 'vi'
                            ? '• Tính toán số tiền an toàn bạn có thể tiêu mỗi ngày\n'
                                '• Cảnh báo tức thì khi chi tiêu chạm $_budgetAlertThreshold% hạn mức\n'
                                '• Tránh tình trạng thâm hụt trước khi hết tháng'
                            : '• Calculate a safe daily spending allowance\n'
                                '• Instant alert when spending hits $_budgetAlertThreshold% of limit\n'
                                '• Avoid running into deficit before month end',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: scheme.onSurface.withValues(alpha: 0.75),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Monthly Limit Input
          AppleTextField(
            controller: _budgetController,
            label: Localizations.localeOf(context).languageCode == 'vi'
                ? 'Hạn mức chi tiêu tháng này'
                : 'This month\'s spending limit',
            placeholder: '5.000.000',
            keyboardType: TextInputType.number,
            inputFormatters: [
              MoneyInputFormatter(
                currencyCode: _selectedCurrency,
                locale: Localizations.localeOf(context).languageCode,
              ),
            ],
            suffix: Text(
              AppCurrencies.byCode(_selectedCurrency).symbol,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            onChanged: (text) {
              final parsed = Money.tryParse(
                text,
                currencyCode: _selectedCurrency,
              );
              setState(() {
                _budgetAmount = parsed?.minorUnits ?? 0;
              });
            },
          ),
          const SizedBox(height: 8),

          // Quick Presets
          Text(
            Localizations.localeOf(context).languageCode == 'vi'
                ? 'Mức ngân sách phổ biến'
                : 'Popular budget presets',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: scheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildBudgetPresetChip(
                  3000000,
                  Localizations.localeOf(context).languageCode == 'vi'
                      ? '3 triệu (Tiết kiệm)'
                      : '3M (Saver)',
                ),
                _buildBudgetPresetChip(
                  5000000,
                  Localizations.localeOf(context).languageCode == 'vi'
                      ? '5 triệu (Cơ bản)'
                      : '5M (Basic)',
                ),
                _buildBudgetPresetChip(
                  10000000,
                  Localizations.localeOf(context).languageCode == 'vi'
                      ? '10 triệu (Tiêu chuẩn)'
                      : '10M (Standard)',
                ),
                _buildBudgetPresetChip(
                  15000000,
                  Localizations.localeOf(context).languageCode == 'vi'
                      ? '15 triệu (Thoải mái)'
                      : '15M (Comfort)',
                ),
                _buildBudgetPresetChip(
                  20000000,
                  Localizations.localeOf(context).languageCode == 'vi'
                      ? '20 triệu'
                      : '20M',
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Alert Threshold
          Text(
            Localizations.localeOf(context).languageCode == 'vi'
                ? 'Ngưỡng phát tín hiệu cảnh báo'
                : 'Alert threshold',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: scheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildThresholdChip(70, '70%'),
              const SizedBox(width: 8),
              _buildThresholdChip(
                80,
                Localizations.localeOf(context).languageCode == 'vi'
                    ? '80% (Khuyên dùng)'
                    : '80% (Recommended)',
              ),
              const SizedBox(width: 8),
              _buildThresholdChip(90, '90%'),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            Localizations.localeOf(context).languageCode == 'vi'
                ? 'Ứng dụng sẽ đổi màu cảnh báo trên biểu đồ khi tổng chi tiêu trong tháng chạm $_budgetAlertThreshold% ngân sách.'
                : 'Charts will highlight a warning color when monthly spending reaches $_budgetAlertThreshold% of your budget.',
            style: TextStyle(
              fontSize: 12,
              color: scheme.onSurface.withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(height: 32),

          // Action: Complete with Budget
          AppleButton.primary(
            label: Localizations.localeOf(context).languageCode == 'vi'
                ? 'Hoàn tất & Bắt đầu sử dụng'
                : 'Complete & Start using',
            icon: const Icon(Icons.check_circle_rounded, size: 20),
            isLoading: _isSaving,
            onPressed: () => _completeSetup(includeBudget: true),
          ),
          const SizedBox(height: 10),

          // Action: Skip Budget
          Center(
            child: TextButton(
              onPressed: _isSaving ? null : () => _completeSetup(includeBudget: false),
              child: Text(
                Localizations.localeOf(context).languageCode == 'vi'
                    ? 'Để sau (Bỏ qua bước này)'
                    : 'Maybe later (Skip this step)',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurface.withValues(alpha: 0.65),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildBudgetPresetChip(int amount, String label) {
    final isSelected = _budgetAmount == amount;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ActionChip(
        label: Text(label),
        onPressed: () => _setBudgetPreset(amount),
        backgroundColor: isSelected
            ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.15)
            : null,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
        ),
      ),
    );
  }

  Widget _buildThresholdChip(int threshold, String label) {
    final isSelected = _budgetAlertThreshold == threshold;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          unawaited(HapticFeedback.selectionClick());
          setState(() => _budgetAlertThreshold = threshold);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected
                ? scheme.primary
                : scheme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
            border: Border.all(
              color: isSelected
                  ? scheme.primary
                  : theme.dividerColor.withValues(alpha: 0.15),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : scheme.onSurface,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}
