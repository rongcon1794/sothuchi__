import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:so_thu_chi/core/constants/currency_constants.dart';
import 'package:so_thu_chi/core/constants/icon_catalog.dart';
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
      _walletNameController.text = 'Tiền mặt';
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

    try {
      final user = ref.read(currentUserProvider);
      final walletName = _walletNameController.text.trim().isEmpty
          ? 'Tiền mặt'
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
          SnackBar(content: Text('Lỗi: ${res.errorOrNull}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi thiết lập: $e')),
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
        SnackBar(content: Text('Lỗi: ${res.errorOrNull}')),
      );
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
                'Đang kiểm tra dữ liệu tài khoản...',
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
                    tooltip: 'Quay lại ví',
                  )
                : null,
            title: _buildStepIndicator(),
            centerTitle: true,
            actions: [
              if (_currentStep == 0)
                TextButton(
                  onPressed: _isSaving ? null : _skipAndUseDefaults,
                  child: Text(
                    'Bỏ qua',
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
              'Bước 1 / 2 • Tạo ví tiền đầu tiên',
              style: TextStyle(
                color: scheme.primary,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Tạo ví tiền đầu tiên',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Bắt đầu ghi chép chi tiêu bằng cách thêm ví hoặc tài khoản chính bạn đang sử dụng.',
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
            'Gợi ý nhanh',
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
            label: 'Tên ví',
            placeholder: 'Ví dụ: Tiền mặt, Techcombank, MoMo...',
            clearable: true,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 14),

          // Wallet Type
          Text(
            'Loại ví',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: scheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildTypeChip('Tiền mặt', AccountType.cash, 'cash'),
              const SizedBox(width: 8),
              _buildTypeChip('Ngân hàng', AccountType.bank, 'bank'),
              const SizedBox(width: 8),
              _buildTypeChip('Ví điện tử', AccountType.ewallet, 'ewallet'),
            ],
          ),
          const SizedBox(height: 14),

          // Initial Balance
          AppleTextField(
            controller: _walletBalanceController,
            label: 'Số dư ban đầu',
            placeholder: '0',
            keyboardType: TextInputType.number,
            inputFormatters: [
              MoneyInputFormatter(currencyCode: _selectedCurrency),
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
                      'Màu sắc',
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
                      'Biểu tượng',
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
            label: 'Tiếp tục: Thiết lập ngân sách',
            icon: const Icon(Icons.arrow_forward_rounded, size: 20),
            onPressed: _goToStep2,
          ),
          const SizedBox(height: 10),
          Center(
            child: TextButton(
              onPressed: _isSaving ? null : _skipAndUseDefaults,
              child: Text(
                'Bỏ qua & Sử dụng cấu hình cơ bản',
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
    final currencyInfo = AppCurrencies.byCode(_selectedCurrency);
    final walletName = _walletNameController.text.trim().isEmpty
        ? 'Tên ví'
        : _walletNameController.text.trim();
    final balanceText = Money(
      minorUnits: _walletBalance,
      currencyCode: _selectedCurrency,
    ).format();

    final typeLabel = switch (_walletType) {
      AccountType.cash => 'Tiền mặt',
      AccountType.bank => 'Tài khoản Ngân hàng',
      AccountType.ewallet => 'Ví điện tử',
      _ => 'Tài khoản',
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
              'Bước 2 / 2 • Thiết lập ngân sách',
              style: TextStyle(
                color: LucianTokens.resolveMint(isDark),
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Thiết lập ngân sách tháng',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Đặt hạn mức chi tiêu hàng tháng để ứng dụng nhắc nhở và giữ nhịp chi an toàn mỗi ngày.',
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
                      const Text(
                        'Kiểm soát chi tiêu thông minh',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '• Tính toán số tiền an toàn bạn có thể tiêu mỗi ngày\n'
                        '• Cảnh báo tức thì khi chi tiêu chạm $_budgetAlertThreshold% hạn mức\n'
                        '• Tránh tình trạng thâm hụt trước khi hết tháng',
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
            label: 'Hạn mức chi tiêu tháng này',
            placeholder: '5.000.000',
            keyboardType: TextInputType.number,
            inputFormatters: [
              MoneyInputFormatter(currencyCode: _selectedCurrency),
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
            'Mức ngân sách phổ biến',
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
                _buildBudgetPresetChip(3000000, '3 triệu (Tiết kiệm)'),
                _buildBudgetPresetChip(5000000, '5 triệu (Cơ bản)'),
                _buildBudgetPresetChip(10000000, '10 triệu (Tiêu chuẩn)'),
                _buildBudgetPresetChip(15000000, '15 triệu (Thoải mái)'),
                _buildBudgetPresetChip(20000000, '20 triệu'),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Alert Threshold
          Text(
            'Ngưỡng phát tín hiệu cảnh báo',
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
              _buildThresholdChip(80, '80% (Khuyên dùng)'),
              const SizedBox(width: 8),
              _buildThresholdChip(90, '90%'),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Ứng dụng sẽ đổi màu cảnh báo trên biểu đồ khi tổng chi tiêu trong tháng chạm $_budgetAlertThreshold% ngân sách.',
            style: TextStyle(
              fontSize: 12,
              color: scheme.onSurface.withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(height: 32),

          // Action: Complete with Budget
          AppleButton.primary(
            label: 'Hoàn tất & Bắt đầu sử dụng',
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
                'Để sau (Bỏ qua bước này)',
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
