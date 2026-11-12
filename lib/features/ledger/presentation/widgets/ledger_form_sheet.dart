import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:so_thu_chi/core/constants/currency_constants.dart';
import 'package:so_thu_chi/core/constants/icon_catalog.dart';
import 'package:so_thu_chi/core/l10n/l10n_ext.dart';
import 'package:so_thu_chi/core/theme/apple_theme_tokens.dart';
import 'package:so_thu_chi/core/widgets/apple_kit.dart';
import 'package:so_thu_chi/features/ledger/domain/entities/ledger_book.dart';
import 'package:so_thu_chi/features/ledger/presentation/controllers/ledgers_controller.dart';
import 'package:so_thu_chi/l10n/app_localizations.dart';

class _LedgerTemplate {
  const _LedgerTemplate({
    required this.name,
    required this.type,
    required this.icon,
    required this.color,
    required this.subtitle,
  });

  final String name;
  final LedgerType type;
  final String icon;
  final int color;
  final String subtitle;
}

const _kLedgerTemplatesVi = [
  _LedgerTemplate(
    name: 'Sổ Gia Đình',
    type: LedgerType.family,
    icon: 'family',
    color: 0xFF007AFF,
    subtitle: 'Sinh hoạt chung & con cái',
  ),
  _LedgerTemplate(
    name: 'Kinh Doanh & Dự Án',
    type: LedgerType.business,
    icon: 'briefcase',
    color: 0xFF5856D6,
    subtitle: 'Bán hàng, dòng tiền dự án',
  ),
  _LedgerTemplate(
    name: 'Quỹ Du Lịch & Nghỉ Dưỡng',
    type: LedgerType.custom,
    icon: 'airplane',
    color: 0xFFFF9500,
    subtitle: 'Đi chơi, du lịch, dã ngoại',
  ),
  _LedgerTemplate(
    name: 'Đầu Tư & Tích Lũy',
    type: LedgerType.custom,
    icon: 'chart',
    color: 0xFF00A86B,
    subtitle: 'Chứng khoán, vàng, tài sản',
  ),
  _LedgerTemplate(
    name: 'Học Tập & Con Cái',
    type: LedgerType.family,
    icon: 'school',
    color: 0xFF30B0C7,
    subtitle: 'Học phí, sách vở, khóa học',
  ),
  _LedgerTemplate(
    name: 'Xây Sửa & Mua Sắm Nhà',
    type: LedgerType.custom,
    icon: 'home',
    color: 0xFFFA5050,
    subtitle: 'Sửa nhà, mua sắm nội thất',
  ),
];

const _kLedgerTemplatesEn = [
  _LedgerTemplate(
    name: 'Family Ledger',
    type: LedgerType.family,
    icon: 'family',
    color: 0xFF007AFF,
    subtitle: 'Household & kids expenses',
  ),
  _LedgerTemplate(
    name: 'Business & Projects',
    type: LedgerType.business,
    icon: 'briefcase',
    color: 0xFF5856D6,
    subtitle: 'Sales & project cashflow',
  ),
  _LedgerTemplate(
    name: 'Travel & Vacation Fund',
    type: LedgerType.custom,
    icon: 'airplane',
    color: 0xFFFF9500,
    subtitle: 'Trips, flights & hotels',
  ),
  _LedgerTemplate(
    name: 'Investments & Savings',
    type: LedgerType.custom,
    icon: 'chart',
    color: 0xFF00A86B,
    subtitle: 'Stocks, gold & assets',
  ),
  _LedgerTemplate(
    name: 'Education & Kids',
    type: LedgerType.family,
    icon: 'school',
    color: 0xFF30B0C7,
    subtitle: 'Tuition, books & courses',
  ),
  _LedgerTemplate(
    name: 'Home Renovation',
    type: LedgerType.custom,
    icon: 'home',
    color: 0xFFFA5050,
    subtitle: 'Repairs & furniture',
  ),
];

class LedgerFormSheet extends ConsumerStatefulWidget {
  const LedgerFormSheet({super.key, this.existing});

  final LedgerBook? existing;

  static Future<void> show(BuildContext context, {LedgerBook? existing}) {
    return AppleModalSheetLayout.show<void>(
      context: context,
      builder: (_) => LedgerFormSheet(existing: existing),
    );
  }

  @override
  ConsumerState<LedgerFormSheet> createState() => _LedgerFormSheetState();
}

class _LedgerFormSheetState extends ConsumerState<LedgerFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  LedgerType _type = LedgerType.personal;
  String _selectedIcon = 'person';
  int _selectedColor = 0xFF00A86B;

  bool get _isEditing => widget.existing != null;

  static const _availableColors = [
    0xFF00A86B, // Jade Green
    0xFF007AFF, // iOS Blue
    0xFF5856D6, // Indigo
    0xFFAF52DE, // Purple
    0xFFFF9500, // Orange
    0xFFFFCC00, // Amber / Gold
    0xFFFA5050, // Ruby Red
    0xFF30B0C7, // Teal
    0xFF34C759, // Mint
    0xFFFF2D55, // Rose Pink
  ];

  @override
  void initState() {
    super.initState();
    final item = widget.existing;
    if (item != null) {
      _nameController.text = item.name;
      _type = item.type;
      _selectedIcon = item.icon;
      _selectedColor = item.color;
    }
    _lastNameText = _nameController.text;
    _nameController.addListener(_onNameChanged);
  }

  String _lastNameText = '';

  void _onNameChanged() {
    final current = _nameController.text;
    if (current == _lastNameText) return;
    _lastNameText = current;
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _nameController.removeListener(_onNameChanged);
    _nameController.dispose();
    super.dispose();
  }

  IconData _resolveIcon(String iconKey) =>
      AppIconCatalog.resolveLedgerIcon(iconKey);

  String _typeLabel(LedgerType type, AppLocalizations l10n) {
    switch (type) {
      case LedgerType.personal:
        return l10n.ledgerPersonal;
      case LedgerType.family:
        return l10n.ledgerFamily;
      case LedgerType.business:
        return l10n.ledgerBusiness;
      case LedgerType.custom:
        return l10n.ledgerCustom;
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final entity = LedgerBook(
      id: widget.existing?.id ?? '',
      name: _nameController.text.trim(),
      type: _type,
      icon: _selectedIcon,
      color: _selectedColor,
      currency: widget.existing?.currency ?? AppCurrencies.defaultCode,
      isDefault: widget.existing?.isDefault ?? false,
      createdAt: widget.existing?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    unawaited(HapticFeedback.mediumImpact());
    final actionNotifier = ref.read(ledgersActionControllerProvider.notifier);
    final res = _isEditing
        ? await actionNotifier.updateLedger(entity)
        : await actionNotifier.createLedger(entity);

    if (!mounted) return;
    res.fold(
      onSuccess: (_) {
        unawaited(HapticFeedback.lightImpact());
        Navigator.of(context).pop();
      },
      onFailure: (err) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.localizeError(err))),
        );
      },
    );
  }

  Future<void> _delete() async {
    final l10n = context.l10n;
    final confirmed = await showCupertinoModalPopup<bool>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: Text(l10n.ledgerDeleteConfirmTitle(widget.existing!.name)),
        message: Text(l10n.ledgerDeleteConfirmBody),
        actions: [
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.delete),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(l10n.cancel),
        ),
      ),
    );

    if (confirmed == true && mounted) {
      unawaited(HapticFeedback.mediumImpact());
      final res = await ref
          .read(ledgersActionControllerProvider.notifier)
          .deleteLedger(widget.existing!.id);
      if (!mounted) return;
      res.fold(
        onSuccess: (_) {
          unawaited(HapticFeedback.lightImpact());
          Navigator.of(context).pop();
        },
        onFailure: (err) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.localizeError(err))),
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = context.l10n;
    final accentColor = Color(_selectedColor);

    return AppleModalSheetLayout(
      title: _isEditing ? l10n.ledgerEditTitle : l10n.ledgerNewTitle,
      bottomAction: AppleButton.primary(
        color: accentColor,
        label: _isEditing ? l10n.ledgerConfirmUpdate : l10n.ledgerConfirmCreate,
        onPressed: _submit,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 1. Interactive Apple Ledger Book Live Preview Card
            _buildLivePreviewCard(
              isDark: isDark,
              accentColor: accentColor,
              l10n: l10n,
            ),
            const SizedBox(height: 18),

            // 2. Popular Templates Carousel (only in create mode)
            if (!_isEditing) ...[
              _buildSectionHeader(
                icon: CupertinoIcons.sparkles,
                title: Localizations.localeOf(context).languageCode == 'vi'
                    ? 'Mẫu sổ thu chi phổ biến'
                    : 'Popular ledger templates',
                accentColor: accentColor,
              ),
              _buildTemplatesCarousel(isDark: isDark),
              const SizedBox(height: 18),
            ],

            // 3. Visual Ledger Type Selector
            _buildSectionHeader(
              icon: CupertinoIcons.tag_fill,
              title: l10n.ledgerType,
              accentColor: accentColor,
            ),
            _buildTypeSelector(
              isDark: isDark,
              l10n: l10n,
              accentColor: accentColor,
            ),
            const SizedBox(height: 18),

            // 4. Ledger Name Input
            _buildSectionHeader(
              icon: CupertinoIcons.pencil,
              title: l10n.ledgerName,
              accentColor: accentColor,
            ),
            AppleTextField(
              controller: _nameController,
              label: l10n.ledgerName,
              placeholder: l10n.ledgerNameHint,
              prefixIcon: Icon(CupertinoIcons.book, size: 18, color: accentColor),
              clearable: true,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? l10n.ledgerNameRequired : null,
            ),
            const SizedBox(height: 18),

            // 5. Curated Icon Collection
            _buildSectionHeader(
              icon: CupertinoIcons.app_badge_fill,
              title: l10n.ledgerIcon,
              accentColor: accentColor,
            ),
            _buildIconSelector(
              isDark: isDark,
              accentColor: accentColor,
            ),
            const SizedBox(height: 18),

            // 6. Curated Color Palette
            _buildSectionHeader(
              icon: CupertinoIcons.paintbrush_fill,
              title: l10n.ledgerColor,
              accentColor: accentColor,
            ),
            _buildColorSelector(isDark: isDark),
            const SizedBox(height: 20),

            // 7. Delete Button (if editing non-default)
            if (_isEditing &&
                !widget.existing!.isDefault &&
                widget.existing!.id != LedgerBook.defaultPersonalId) ...[
              AppleButton.destructive(
                label: l10n.ledgerDelete,
                icon: const Icon(CupertinoIcons.trash, size: 18),
                onPressed: _delete,
              ),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    String? subtitle,
    Color? accentColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: 13,
            color: accentColor ?? AppleTokens.systemGray,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: accentColor ?? AppleTokens.systemGray,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 10.5,
                      color: AppleTokens.systemGray,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLivePreviewCard({
    required bool isDark,
    required Color accentColor,
    required AppLocalizations l10n,
  }) {
    final title = _nameController.text.trim().isNotEmpty
        ? _nameController.text.trim()
        : l10n.ledgerNameHint;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Row(
            children: [
              const Icon(
                Icons.remove_red_eye_outlined,
                size: 14,
                color: AppleTokens.systemGray,
              ),
              const SizedBox(width: 6),
              Text(
                Localizations.localeOf(context).languageCode == 'vi'
                    ? 'BẢN XEM TRƯỚC SỔ TRÊN DANH SÁCH'
                    : 'LEDGER LIST PREVIEW',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: AppleTokens.systemGray,
                ),
              ),
            ],
          ),
        ),
        AppleGlassCard(
          padding: EdgeInsets.zero,
          borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
          borderColor: accentColor.withValues(alpha: isDark ? 0.35 : 0.22),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
            child: Stack(
              children: [
                // Colored Left Spine Strip
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: 6,
                  child: Container(color: accentColor),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 14, 12, 14),
                  child: Row(
                    children: [
                      // Squircle Badge
                      AppleSquircleBadge(
                        icon: _resolveIcon(_selectedIcon),
                        backgroundColor: accentColor,
                        size: 46,
                        iconSize: 24,
                      ),
                      const SizedBox(width: 14),
                      // Name & Tags
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (widget.existing?.isDefault == true) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? Colors.white12
                                          : Colors.black.withValues(alpha: 0.06),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      Localizations.localeOf(context).languageCode == 'vi'
                                          ? 'Mặc định'
                                          : 'Default',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: AppleTokens.systemGray,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              _typeLabel(_type, l10n),
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppleTokens.systemGray,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // 3-dots preview button
                      Container(
                        width: 28,
                        height: 28,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : Colors.black.withValues(alpha: 0.04),
                          borderRadius:
                              BorderRadius.circular(AppleTokens.radiusPill),
                        ),
                        child: const Icon(
                          CupertinoIcons.ellipsis,
                          size: 16,
                          color: AppleTokens.systemGray,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTemplatesCarousel({required bool isDark}) {
    final isVi = Localizations.localeOf(context).languageCode == 'vi';
    final templates = isVi ? _kLedgerTemplatesVi : _kLedgerTemplatesEn;
    return SizedBox(
      height: 72,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: templates.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final tpl = templates[index];
          final tplColor = Color(tpl.color);
          return ApplePressable(
            onTap: () {
              unawaited(HapticFeedback.mediumImpact());
              setState(() {
                _nameController.text = tpl.name;
                _type = tpl.type;
                _selectedIcon = tpl.icon;
                _selectedColor = tpl.color;
              });
            },
            borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isDark
                    ? AppleTokens.bgDarkSecondary
                    : AppleTokens.bgLightSecondary,
                borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
                border: Border.all(
                  color: tplColor.withValues(alpha: 0.35),
                  width: 1.0,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: tplColor.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(AppleTokens.radiusControl),
                    ),
                    child: Icon(
                      _resolveIcon(tpl.icon),
                      color: tplColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        tpl.name,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        tpl.subtitle,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white54 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTypeSelector({
    required bool isDark,
    required AppLocalizations l10n,
    required Color accentColor,
  }) {
    final isVi = Localizations.localeOf(context).languageCode == 'vi';
    final types = [
      (
        type: LedgerType.personal,
        title: l10n.ledgerPersonal,
        desc: isVi ? 'Thu chi cá nhân' : 'Personal finances',
        icon: CupertinoIcons.person_crop_circle_fill,
      ),
      (
        type: LedgerType.family,
        title: l10n.ledgerFamily,
        desc: isVi ? 'Sinh hoạt chung' : 'Shared household',
        icon: CupertinoIcons.person_3_fill,
      ),
      (
        type: LedgerType.business,
        title: l10n.ledgerBusiness,
        desc: isVi ? 'Kinh doanh & dự án' : 'Business & projects',
        icon: CupertinoIcons.briefcase_fill,
      ),
      (
        type: LedgerType.custom,
        title: l10n.ledgerCustom,
        desc: isVi ? 'Quỹ riêng & sự kiện' : 'Funds & events',
        icon: CupertinoIcons.star_fill,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth - 10) / 2;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: types.map((item) {
            final isSelected = _type == item.type;
            return SizedBox(
              width: cardWidth,
              child: ApplePressable(
                onTap: () {
                  unawaited(HapticFeedback.selectionClick());
                  setState(() => _type = item.type);
                },
                borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? accentColor.withValues(alpha: isDark ? 0.22 : 0.12)
                        : (isDark
                            ? AppleTokens.bgDarkSecondary
                            : AppleTokens.bgLightSecondary),
                    borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
                    border: Border.all(
                      color: isSelected
                          ? accentColor
                          : (isDark
                              ? AppleTokens.separatorDark
                              : AppleTokens.separatorLight),
                      width: isSelected ? 1.5 : 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? accentColor
                              : (isDark ? Colors.white12 : Colors.black12),
                          borderRadius:
                              BorderRadius.circular(AppleTokens.radiusControl),
                        ),
                        child: Icon(
                          item.icon,
                          size: 16,
                          color: isSelected
                              ? Colors.white
                              : (isDark ? Colors.white70 : Colors.black87),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              item.title,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w600,
                                color: isSelected
                                    ? (isDark ? Colors.white : accentColor)
                                    : (isDark ? Colors.white : Colors.black87),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              item.desc,
                              style: TextStyle(
                                fontSize: 10.5,
                                color: isDark ? Colors.white54 : Colors.black54,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildIconSelector({
    required bool isDark,
    required Color accentColor,
  }) {
    const items = AppIconCatalog.ledgerIcons;
    return LayoutBuilder(
      builder: (context, constraints) {
        final cols = constraints.maxWidth >= 420 ? 6 : 4;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            mainAxisSpacing: 10,
            crossAxisSpacing: 8,
            childAspectRatio: 0.92,
          ),
          itemBuilder: (context, index) {
            final item = items[index];
            final isSelected = _selectedIcon == item.$1;
            return ApplePressable(
              onTap: () {
                unawaited(HapticFeedback.selectionClick());
                setState(() => _selectedIcon = item.$1);
              },
              borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? accentColor
                          : (isDark
                              ? AppleTokens.bgDarkSecondary
                              : AppleTokens.bgLightSecondary),
                      borderRadius:
                          BorderRadius.circular(AppleTokens.radiusCard),
                      border: Border.all(
                        color: isSelected
                            ? Colors.white
                            : (isDark
                                ? AppleTokens.separatorDark
                                : AppleTokens.separatorLight),
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: accentColor.withValues(alpha: 0.4),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Icon(
                      item.$2,
                      color: isSelected
                          ? Colors.white
                          : (isDark ? Colors.white70 : Colors.black87),
                      size: 21,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.$3,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected
                          ? (isDark ? Colors.white : accentColor)
                          : (isDark ? Colors.white60 : Colors.black54),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildColorSelector({required bool isDark}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cols = constraints.maxWidth >= 480 ? 10 : 5;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: _availableColors.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1.0,
          ),
          itemBuilder: (context, index) {
            final colorVal = _availableColors[index];
            final isSelected = _selectedColor == colorVal;
            final color = Color(colorVal);
            return ApplePressable(
              onTap: () {
                unawaited(HapticFeedback.selectionClick());
                setState(() => _selectedColor = colorVal);
              },
              borderRadius: BorderRadius.circular(22),
              child: Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: isSelected ? 36 : 30,
                  height: isSelected ? 36 : 30,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? (isDark ? Colors.white : Colors.black87)
                          : Colors.transparent,
                      width: 2.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color:
                            color.withValues(alpha: isSelected ? 0.45 : 0.2),
                        blurRadius: isSelected ? 8 : 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: isSelected
                      ? const Icon(
                          CupertinoIcons.checkmark,
                          color: Colors.white,
                          size: 17,
                        )
                      : null,
                ),
              ),
            );
          },
        );
      },
    );
  }
}
