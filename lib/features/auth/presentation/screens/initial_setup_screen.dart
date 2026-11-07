import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:so_thu_chi/core/constants/currency_constants.dart';
import 'package:so_thu_chi/core/theme/apple_theme_tokens.dart';
import 'package:so_thu_chi/core/utils/money.dart';
import 'package:so_thu_chi/core/widgets/apple_kit.dart';
import 'package:so_thu_chi/features/accounts/domain/entities/account.dart';
import 'package:so_thu_chi/features/accounts/presentation/controllers/accounts_controller.dart';
import 'package:so_thu_chi/features/auth/presentation/controllers/auth_controller.dart';
import 'package:so_thu_chi/features/auth/presentation/controllers/initial_setup_controller.dart';
import 'package:so_thu_chi/features/ledger/domain/entities/ledger_book.dart';
import 'package:so_thu_chi/features/ledger/presentation/controllers/ledgers_controller.dart';

class _LedgerPresetItem {
  const _LedgerPresetItem({
    required this.id,
    required this.name,
    required this.type,
    required this.icon,
    required this.color,
    required this.subtitle,
  });

  final String id;
  final String name;
  final LedgerType type;
  final String icon;
  final int color;
  final String subtitle;
}

class _WalletConfigItem {
  _WalletConfigItem({
    required this.key,
    required this.defaultName,
    required this.type,
    required this.icon,
    required this.color,
    this.enabled = true,
    int initialMinorUnits = 0,
    required this.nameController,
    required this.balanceController,
  }) : initialAmount = initialMinorUnits;

  final String key;
  final String defaultName;
  final AccountType type;
  final String icon;
  final int color;
  bool enabled;
  int initialAmount;
  final TextEditingController nameController;
  final TextEditingController balanceController;
}

class InitialSetupScreen extends ConsumerStatefulWidget {
  const InitialSetupScreen({super.key});

  @override
  ConsumerState<InitialSetupScreen> createState() => _InitialSetupScreenState();
}

class _InitialSetupScreenState extends ConsumerState<InitialSetupScreen> {
  static const List<_LedgerPresetItem> _ledgerPresets = [
    _LedgerPresetItem(
      id: LedgerBook.defaultPersonalId,
      name: 'Sổ Cá Nhân',
      type: LedgerType.personal,
      icon: 'person',
      color: 0xFF00A86B,
      subtitle: 'Chi tiêu sinh hoạt cá nhân hàng ngày',
    ),
    _LedgerPresetItem(
      id: 'default_family',
      name: 'Sổ Gia Đình',
      type: LedgerType.family,
      icon: 'family',
      color: 0xFF007AFF,
      subtitle: 'Quản lý sinh hoạt, chợ búa chung cho cả nhà',
    ),
    _LedgerPresetItem(
      id: 'default_business',
      name: 'Sổ Kinh Doanh',
      type: LedgerType.business,
      icon: 'business',
      color: 0xFF8E44AD,
      subtitle: 'Doanh thu, tiền hàng và chi phí bán hàng',
    ),
    _LedgerPresetItem(
      id: 'default_project',
      name: 'Sổ Du Lịch / Dự Án',
      type: LedgerType.custom,
      icon: 'flight',
      color: 0xFFFF9500,
      subtitle: 'Theo dõi chi phí theo chuyến đi hoặc dự án',
    ),
  ];

  late final TextEditingController _customLedgerNameController;
  late final List<_WalletConfigItem> _wallets;

  int _selectedLedgerPresetIndex = 0;
  String _selectedCurrency = AppCurrencies.defaultCode;
  String _defaultWalletKey = 'cash';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _customLedgerNameController = TextEditingController(
      text: _ledgerPresets[0].name,
    );

    _wallets = [
      _WalletConfigItem(
        key: 'cash',
        defaultName: 'Tiền mặt',
        type: AccountType.cash,
        icon: 'cash',
        color: 0xFF00A86B,
        enabled: true,
        initialMinorUnits: 500000,
        nameController: TextEditingController(text: 'Tiền mặt'),
        balanceController: TextEditingController(text: '500.000'),
      ),
      _WalletConfigItem(
        key: 'bank',
        defaultName: 'Tài khoản Ngân hàng',
        type: AccountType.bank,
        icon: 'bank',
        color: 0xFF007AFF,
        enabled: true,
        initialMinorUnits: 5000000,
        nameController: TextEditingController(text: 'Tài khoản Ngân hàng'),
        balanceController: TextEditingController(text: '5.000.000'),
      ),
      _WalletConfigItem(
        key: 'ewallet',
        defaultName: 'Ví MoMo',
        type: AccountType.ewallet,
        icon: 'ewallet',
        color: 0xFFA259FF,
        enabled: false,
        initialMinorUnits: 200000,
        nameController: TextEditingController(text: 'Ví MoMo'),
        balanceController: TextEditingController(text: '200.000'),
      ),
      _WalletConfigItem(
        key: 'savings',
        defaultName: 'Sổ Tiết kiệm',
        type: AccountType.bank,
        icon: 'savings',
        color: 0xFF10B981,
        enabled: false,
        initialMinorUnits: 10000000,
        nameController: TextEditingController(text: 'Sổ Tiết kiệm'),
        balanceController: TextEditingController(text: '10.000.000'),
      ),
    ];
  }

  @override
  void dispose() {
    _customLedgerNameController.dispose();
    for (final w in _wallets) {
      w.nameController.dispose();
      w.balanceController.dispose();
    }
    super.dispose();
  }

  Future<void> _applyQuickDefaults() async {
    unawaited(HapticFeedback.mediumImpact());
    setState(() => _isSaving = true);
    final user = ref.read(currentUserProvider);
    final res = await ref
        .read(initialSetupControllerProvider.notifier)
        .applyQuickDefaults(uid: user?.uid);
    if (!mounted) return;
    if (res.isFailure) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: ${res.errorOrNull}')),
      );
    }
    setState(() => _isSaving = false);
  }

  Future<void> _skipAndFinish() async {
    unawaited(HapticFeedback.selectionClick());
    setState(() => _isSaving = true);
    final user = ref.read(currentUserProvider);
    final res = await ref
        .read(initialSetupControllerProvider.notifier)
        .skipAndFinish(uid: user?.uid, currency: _selectedCurrency);
    if (!mounted) return;
    if (res.isFailure) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: ${res.errorOrNull}')),
      );
    }
    setState(() => _isSaving = false);
  }

  Future<void> _saveAndFinish() async {
    if (_isSaving) return;
    unawaited(HapticFeedback.mediumImpact());
    setState(() => _isSaving = true);

    try {
      final user = ref.read(currentUserProvider);
      final preset = _ledgerPresets[_selectedLedgerPresetIndex];
      final ledgerName = _customLedgerNameController.text.trim().isEmpty
          ? preset.name
          : _customLedgerNameController.text.trim();

      final primaryLedger = LedgerBook(
        id: preset.id,
        name: ledgerName,
        type: preset.type,
        icon: preset.icon,
        color: preset.color,
        currency: _selectedCurrency,
        isDefault: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final enabledWallets = <InitialSetupWalletDraft>[];
      for (final item in _wallets) {
        if (!item.enabled) continue;
        final parsedMoney = Money.tryParse(
          item.balanceController.text,
          currencyCode: _selectedCurrency,
        );
        final initialBal = parsedMoney?.minorUnits ?? 0;
        final walletName = item.nameController.text.trim().isEmpty
            ? item.defaultName
            : item.nameController.text.trim();

        enabledWallets.add(
          InitialSetupWalletDraft(
            key: item.key,
            name: walletName,
            type: item.type,
            initialBalance: initialBal,
            icon: item.icon,
            color: item.color,
          ),
        );
      }

      final res = await ref
          .read(initialSetupControllerProvider.notifier)
          .completeCustomSetup(
            primaryLedger: primaryLedger,
            enabledWallets: enabledWallets,
            defaultWalletKey: _defaultWalletKey,
            uid: user?.uid,
          );

      if (!mounted) return;
      if (res.isFailure) {
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final currencyInfo = AppCurrencies.byCode(_selectedCurrency);

    // Check if user already has cloud ledgers or accounts
    final cloudLedgers = ref.watch(ledgersStreamProvider).value ?? const [];
    final cloudAccounts = ref.watch(accountsStreamProvider).value ?? const [];
    final hasExistingData = cloudLedgers.length > 2 ||
        cloudAccounts.any((a) => !a.archived && a.balance != 0);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Thiết lập ban đầu',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _skipAndFinish,
            child: Text(
              'Bỏ qua',
              style: TextStyle(
                color: scheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero Section
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            LucianTokens.resolveMint(isDark),
                            scheme.primary,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
                        boxShadow: [
                          BoxShadow(
                            color: LucianTokens.resolveMint(isDark).withValues(alpha: 0.35),
                            blurRadius: 18,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet_rounded,
                        color: Colors.white,
                        size: 36,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Chào mừng bạn đến với Sổ Thu Chi!',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Tạo sổ thu chi đầu tiên và các ví tiền giao dịch để bắt đầu quản lý tài chính chuẩn xác.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13.5,
                        color: scheme.onSurface.withValues(alpha: 0.7),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Existing Data Notification Banner (if any)
              if (hasExistingData) ...[
                AppleGlassCard(
                  padding: const EdgeInsets.all(16),
                  borderColor: LucianTokens.resolveMint(isDark).withValues(alpha: 0.5),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: LucianTokens.resolveMint(isDark).withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.cloud_done_rounded,
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
                              'Đã tìm thấy dữ liệu trên đám mây',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Tài khoản của bạn đã có ${cloudAccounts.length} ví. Bạn có thể tiếp tục với dữ liệu cũ ngay.',
                              style: TextStyle(
                                fontSize: 12,
                                color: scheme.onSurface.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      AppleButton.secondary(
                        height: 36,
                        isFullWidth: false,
                        label: 'Dùng dữ liệu cũ',
                        onPressed: _skipAndFinish,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Quick Preset Card
              AppleGlassCard(
                padding: const EdgeInsets.all(16),
                borderColor: scheme.primary.withValues(alpha: 0.35),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: scheme.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
                          ),
                          child: Icon(
                            Icons.auto_awesome_rounded,
                            size: 16,
                            color: scheme.primary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Thiết lập đề xuất (1 chạm)',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tự động tạo Sổ Cá Nhân (mặc định), Ví Tiền mặt (500.000đ), Tài khoản Ngân hàng (5.000.000đ) và toàn bộ danh mục thu chi thông dụng.',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: scheme.onSurface.withValues(alpha: 0.7),
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 12),
                    AppleButton.primary(
                      height: 42,
                      label: 'Áp dụng đề xuất & Bắt đầu ngay',
                      icon: const Icon(Icons.flash_on_rounded, size: 18),
                      isLoading: _isSaving,
                      onPressed: _applyQuickDefaults,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Section 1: Ledger Setup
              _buildSectionHeader(
                step: '1',
                title: 'Sổ thu chi đầu tiên',
                description: 'Chọn loại sổ bạn muốn dùng để ghi nhận các khoản thu chi.',
              ),
              const SizedBox(height: 10),

              // Ledger Presets Grid
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1.45,
                ),
                itemCount: _ledgerPresets.length,
                itemBuilder: (context, index) {
                  final item = _ledgerPresets[index];
                  final isSelected = _selectedLedgerPresetIndex == index;
                  return ApplePressable(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _selectedLedgerPresetIndex = index;
                        _customLedgerNameController.text = item.name;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Color(item.color).withValues(alpha: isDark ? 0.25 : 0.12)
                            : (isDark
                                ? Colors.white.withValues(alpha: 0.05)
                                : Colors.black.withValues(alpha: 0.03)),
                        borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
                        border: Border.all(
                          color: isSelected
                              ? Color(item.color)
                              : (isDark
                                  ? Colors.white.withValues(alpha: 0.1)
                                  : Colors.black.withValues(alpha: 0.08)),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: Color(item.color),
                                  borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
                                ),
                                child: Icon(
                                  _getLedgerIcon(item.icon),
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                              if (isSelected)
                                Icon(
                                  Icons.check_circle_rounded,
                                  color: Color(item.color),
                                  size: 20,
                                ),
                            ],
                          ),
                          const Spacer(),
                          Text(
                            item.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10.5,
                              color: scheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),

              // Customize Ledger Name & Currency
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: AppleTextField(
                      controller: _customLedgerNameController,
                      label: 'Tên sổ thu chi',
                      placeholder: 'Nhập tên sổ mong muốn',
                      prefixIcon: const Icon(Icons.edit_note_rounded, size: 20),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedCurrency,
                      decoration: const InputDecoration(
                        labelText: 'Tiền tệ',
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      ),
                      items: AppCurrencies.supported.map((c) {
                        return DropdownMenuItem<String>(
                          value: c.code,
                          child: Text('${c.code} (${c.symbol})'),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedCurrency = val);
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Section 2: Initial Wallets Setup
              _buildSectionHeader(
                step: '2',
                title: 'Các ví giao dịch ban đầu',
                description: 'Bật các ví tiền bạn đang sử dụng và nhập số dư ban đầu.',
              ),
              const SizedBox(height: 12),

              // Wallets List
              Column(
                children: _wallets.map((wallet) {
                  final isDefault = wallet.key == _defaultWalletKey && wallet.enabled;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: wallet.enabled ? 0.08 : 0.03)
                          : Colors.black.withValues(alpha: wallet.enabled ? 0.04 : 0.015),
                      borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
                      border: Border.all(
                        color: wallet.enabled
                            ? (isDefault
                                ? scheme.primary
                                : (isDark
                                    ? Colors.white.withValues(alpha: 0.15)
                                    : Colors.black.withValues(alpha: 0.1)))
                            : Colors.transparent,
                        width: isDefault ? 2 : 1,
                      ),
                    ),
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Checkbox.adaptive(
                              value: wallet.enabled,
                              activeColor: Color(wallet.color),
                              onChanged: (val) {
                                setState(() {
                                  wallet.enabled = val ?? false;
                                  // If disabled default wallet, re-point to first enabled
                                  if (!wallet.enabled && _defaultWalletKey == wallet.key) {
                                    final firstActive = _wallets.where((w) => w.enabled).firstOrNull;
                                    _defaultWalletKey = firstActive?.key ?? 'cash';
                                  }
                                });
                              },
                            ),
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: Color(wallet.color),
                                borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
                              ),
                              child: Icon(
                                _getWalletIcon(wallet.icon),
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    wallet.defaultName,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      color: wallet.enabled
                                          ? null
                                          : scheme.onSurface.withValues(alpha: 0.4),
                                    ),
                                  ),
                                  if (isDefault) ...[
                                    const SizedBox(height: 2),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: scheme.primary.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
                                      ),
                                      child: Text(
                                        'Ví giao dịch mặc định',
                                        style: TextStyle(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w700,
                                          color: scheme.primary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            if (wallet.enabled && !isDefault)
                              TextButton(
                                onPressed: () {
                                  HapticFeedback.selectionClick();
                                  setState(() => _defaultWalletKey = wallet.key);
                                },
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  'Đặt làm mặc định',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: scheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        if (wallet.enabled) ...[
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: AppleTextField(
                                  controller: wallet.nameController,
                                  label: 'Tên ví',
                                  placeholder: wallet.defaultName,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                flex: 4,
                                child: AppleTextField(
                                  controller: wallet.balanceController,
                                  label: 'Số dư ban đầu',
                                  placeholder: '0',
                                  suffix: Text(
                                    currencyInfo.symbol,
                                    style: const TextStyle(fontWeight: FontWeight.w700),
                                  ),
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    MoneyInputFormatter(currencyCode: _selectedCurrency),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Bottom Actions
              AppleButton.primary(
                label: 'Hoàn tất & Bắt đầu sử dụng',
                icon: const Icon(Icons.arrow_forward_rounded, size: 20),
                isLoading: _isSaving,
                onPressed: _saveAndFinish,
              ),
              const SizedBox(height: 10),
              Center(
                child: TextButton(
                  onPressed: _isSaving ? null : _skipAndFinish,
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
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required String step,
    required String title,
    required String description,
  }) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 22,
              height: 22,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: scheme.primary,
                shape: BoxShape.circle,
              ),
              child: Text(
                step,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: TextStyle(
            fontSize: 12.5,
            color: scheme.onSurface.withValues(alpha: 0.65),
          ),
        ),
      ],
    );
  }

  IconData _getLedgerIcon(String iconKey) {
    return switch (iconKey) {
      'person' => Icons.person_rounded,
      'family' => Icons.people_rounded,
      'business' => Icons.storefront_rounded,
      'flight' => Icons.flight_takeoff_rounded,
      _ => Icons.book_rounded,
    };
  }

  IconData _getWalletIcon(String iconKey) {
    return switch (iconKey) {
      'cash' => Icons.payments_rounded,
      'bank' => Icons.account_balance_rounded,
      'ewallet' => Icons.phone_android_rounded,
      'savings' => Icons.savings_rounded,
      _ => Icons.wallet_rounded,
    };
  }
}
