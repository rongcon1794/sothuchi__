import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:so_thu_chi/core/constants/icon_catalog.dart';
import 'package:so_thu_chi/core/l10n/l10n_ext.dart';
import 'package:so_thu_chi/core/theme/app_theme.dart';
import 'package:so_thu_chi/core/theme/apple_theme_tokens.dart';
import 'package:so_thu_chi/core/theme/lucian_theme_tokens.dart';
import 'package:so_thu_chi/core/widgets/apple_kit.dart';
import 'package:so_thu_chi/core/widgets/icon_and_color_picker.dart';
import 'package:so_thu_chi/features/categories/domain/entities/category.dart';
import 'package:so_thu_chi/features/categories/presentation/controllers/categories_controller.dart';

class _CategoryTemplate {
  const _CategoryTemplate({
    required this.name,
    required this.type,
    required this.icon,
    required this.color,
    required this.subtitle,
  });

  final String name;
  final CategoryType type;
  final String icon;
  final int color;
  final String subtitle;
}

const _kCategoryExpenseTemplates = [
  _CategoryTemplate(
    name: 'Cà phê & Đồ uống',
    type: CategoryType.expense,
    icon: 'coffee',
    color: 0xFFD97706, // Amber
    subtitle: 'Cà phê, trà, sinh tố',
  ),
  _CategoryTemplate(
    name: 'Xăng xe & Đi lại',
    type: CategoryType.expense,
    icon: 'transport',
    color: 0xFF1D5BD6, // Cobalt
    subtitle: 'Xăng, gửi xe, taxi',
  ),
  _CategoryTemplate(
    name: 'Tiền trọ & Tiện ích',
    type: CategoryType.expense,
    icon: 'housing',
    color: 0xFF0D7C66, // Jade
    subtitle: 'Thuê phòng, điện nước, mạng',
  ),
  _CategoryTemplate(
    name: 'Mua sắm & Quần áo',
    type: CategoryType.expense,
    icon: 'shopping',
    color: 0xFFDB2777, // Berry
    subtitle: 'Trang phục, mỹ phẩm',
  ),
  _CategoryTemplate(
    name: 'Ăn vặt & Tiệc tùng',
    type: CategoryType.expense,
    icon: 'food',
    color: 0xFFC0352B, // Vermilion
    subtitle: 'Liên hoan, hẹn hò',
  ),
  _CategoryTemplate(
    name: 'Xem phim & Giải trí',
    type: CategoryType.expense,
    icon: 'entertainment',
    color: 0xFF7C3AED, // Iris
    subtitle: 'Rạp chiếu phim, game, ca nhạc',
  ),
  _CategoryTemplate(
    name: 'Thuốc men & Sức khỏe',
    type: CategoryType.expense,
    icon: 'health',
    color: 0xFF0891B2, // Cyan
    subtitle: 'Hiệu thuốc, khám chữa bệnh',
  ),
  _CategoryTemplate(
    name: 'Sách vở & Khóa học',
    type: CategoryType.expense,
    icon: 'education',
    color: 0xFF4F46E5, // Indigo
    subtitle: 'Học tập, kỹ năng mới',
  ),
  _CategoryTemplate(
    name: 'Thú cưng & Thức ăn',
    type: CategoryType.expense,
    icon: 'pets',
    color: 0xFF15803D, // Forest
    subtitle: 'Hạt, cát, phụ kiện thú cưng',
  ),
  _CategoryTemplate(
    name: 'Quà tặng & Hiếu hỉ',
    type: CategoryType.expense,
    icon: 'gift',
    color: 0xFF9333EA, // Plum
    subtitle: 'Đám cưới, sinh nhật, thôi nôi',
  ),
  _CategoryTemplate(
    name: 'Gym & Thể thao',
    type: CategoryType.expense,
    icon: 'fitness',
    color: 0xFFB45309, // Terracotta
    subtitle: 'Phòng tập, chạy bộ, cầu lông',
  ),
  _CategoryTemplate(
    name: 'Du lịch & Nghỉ dưỡng',
    type: CategoryType.expense,
    icon: 'travel',
    color: 0xFF1D5BD6, // Cobalt
    subtitle: 'Vé máy bay, khách sạn, tour',
  ),
];

const _kCategoryIncomeTemplates = [
  _CategoryTemplate(
    name: 'Lương cố định',
    type: CategoryType.income,
    icon: 'salary',
    color: 0xFF15803D, // Forest
    subtitle: 'Lương hàng tháng chính thức',
  ),
  _CategoryTemplate(
    name: 'Thưởng & Hoa hồng',
    type: CategoryType.income,
    icon: 'bonus',
    color: 0xFFD97706, // Amber
    subtitle: 'Thưởng KPI, hoa hồng bán hàng',
  ),
  _CategoryTemplate(
    name: 'Lãi tiết kiệm & Đầu tư',
    type: CategoryType.income,
    icon: 'investment',
    color: 0xFF1D5BD6, // Cobalt
    subtitle: 'Lãi gửi góp, cổ tức, trái phiếu',
  ),
  _CategoryTemplate(
    name: 'Dự án Freelance',
    type: CategoryType.income,
    icon: 'salary',
    color: 0xFF4F46E5, // Indigo
    subtitle: 'Công việc nhận ngoài giờ',
  ),
  _CategoryTemplate(
    name: 'Lì xì & Được tặng',
    type: CategoryType.income,
    icon: 'gift',
    color: 0xFFC0352B, // Vermilion
    subtitle: 'Tiền biếu tặng, lì xì Tết',
  ),
  _CategoryTemplate(
    name: 'Thanh lý đồ cũ',
    type: CategoryType.income,
    icon: 'shopping',
    color: 0xFF0891B2, // Cyan
    subtitle: 'Bán đồ dùng, điện máy cũ',
  ),
];

/// Apple Human Interface Guidelines form sheet for creating or editing a category.
///
/// Features a real-time Live Category Preview Card, instant 1-tap popular templates,
/// tactile Apple theme controls, and full edge-swipe dismissal support.
class CategoryFormSheet extends ConsumerStatefulWidget {
  const CategoryFormSheet({
    super.key,
    required this.initialType,
    this.existing,
    this.initialName,
  });

  final CategoryType initialType;
  final Category? existing;
  final String? initialName;

  /// Convenience helper to show the sheet as a modal bottom sheet.
  static Future<Category?> show(
    BuildContext context, {
    required CategoryType initialType,
    Category? existing,
    String? initialName,
  }) {
    return AppleModalSheetLayout.show<Category>(
      context: context,
      useSafeArea: true,
      builder: (_) => CategoryFormSheet(
        initialType: initialType,
        existing: existing,
        initialName: initialName,
      ),
    );
  }

  @override
  ConsumerState<CategoryFormSheet> createState() => _CategoryFormSheetState();
}

class _CategoryFormSheetState extends ConsumerState<CategoryFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late CategoryType _type;
  late String _icon;
  late int _color;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _nameController = TextEditingController(
      text: existing?.name ?? widget.initialName ?? '',
    );
    _type = existing?.type ?? widget.initialType;
    _icon = existing?.icon ?? (_type == CategoryType.income ? 'salary' : 'food');
    _color = existing?.color ?? AppIconCatalog.palette.first;

    _nameController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _nameController.removeListener(_onTextChanged);
    _nameController.dispose();
    super.dispose();
  }

  void _applyTemplate(_CategoryTemplate template) {
    unawaited(HapticFeedback.selectionClick());
    setState(() {
      _nameController.text = template.name;
      _type = template.type;
      _icon = template.icon;
      _color = template.color;
    });
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    if (!(_formKey.currentState?.validate() ?? false)) {
      unawaited(HapticFeedback.mediumImpact());
      return;
    }

    setState(() => _isSubmitting = true);
    unawaited(HapticFeedback.mediumImpact());

    final ctrl = ref.read(categoriesActionControllerProvider.notifier);
    final existing = widget.existing;
    final name = _nameController.text.trim();

    final result = existing == null
        ? await ctrl.createCategory(
            name: name,
            type: _type,
            icon: _icon,
            color: _color,
          )
        : await ctrl.updateCategory(
            existing.copyWith(
              name: name,
              type: _type,
              icon: _icon,
              color: _color,
            ),
          );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    result.fold(
      onSuccess: (saved) {
        unawaited(HapticFeedback.lightImpact());
        Navigator.of(context).pop(saved);
      },
      onFailure: (err) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.localizeError(err)),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
    );
  }

  Widget _buildLivePreviewCard(ThemeData theme, bool isDark) {
    final activeColor = AppIconCatalog.contrastSafeColor(
      Color(_color),
      theme.brightness,
    );
    final isIncome = _type == CategoryType.income;
    final trimmedName = _nameController.text.trim();
    final displayName = trimmedName.isEmpty
        ? (isIncome ? 'Khoản thu mới' : 'Khoản chi mới')
        : trimmedName;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppleTokens.radiusHero),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  activeColor.withValues(alpha: 0.22),
                  Colors.black.withValues(alpha: 0.65),
                ]
              : [
                  activeColor.withValues(alpha: 0.12),
                  Colors.white,
                ],
        ),
        border: Border.all(
          color: activeColor.withValues(alpha: isDark ? 0.38 : 0.28),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: activeColor.withValues(alpha: isDark ? 0.16 : 0.10),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          // Squircle Icon Badge with halo
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: activeColor.withValues(alpha: isDark ? 0.28 : 0.18),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: activeColor.withValues(alpha: 0.5),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: activeColor.withValues(alpha: 0.28),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(
              AppIconCatalog.resolve(_icon),
              color: activeColor,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.auto_awesome_rounded,
                      size: 13,
                      color: AppleTokens.systemGray,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'XEM TRƯỚC HIỂN THỊ',
                      style: theme.textTheme.labelSmall?.copyWith(
                        letterSpacing: 0.6,
                        fontWeight: FontWeight.w700,
                        color: AppleTokens.systemGray,
                        fontSize: 10.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  displayName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: isIncome
                            ? AppleTokens.emeraldIncome.withValues(alpha: 0.15)
                            : AppleTokens.rubyExpense.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isIncome ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                            size: 12,
                            color: isIncome ? AppleTokens.emeraldIncome : AppleTokens.rubyExpense,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isIncome ? 'Khoản thu' : 'Khoản chi',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isIncome ? AppleTokens.emeraldIncome : AppleTokens.rubyExpense,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isIncome ? '+500.000 ₫' : '-50.000 ₫',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        fontFeatures: AppTheme.tabularFigures,
                        color: isIncome ? AppleTokens.emeraldIncome : AppleTokens.rubyExpense,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateSection(ThemeData theme, bool isDark) {
    final templates = _type == CategoryType.expense
        ? _kCategoryExpenseTemplates
        : _kCategoryIncomeTemplates;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'MẪU DANH MỤC GỢI Ý',
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
                color: AppleTokens.systemGray,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
              ),
              child: Text(
                '${templates.length}',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 64,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: templates.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final item = templates[index];
              final isMatching = _nameController.text.trim() == item.name &&
                  _icon == item.icon &&
                  _color == item.color;
              final itemColor = AppIconCatalog.contrastSafeColor(
                Color(item.color),
                theme.brightness,
              );

              return ApplePressable(
                borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
                onTap: () => _applyTemplate(item),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isMatching
                        ? itemColor.withValues(alpha: isDark ? 0.28 : 0.15)
                        : (isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.black.withValues(alpha: 0.04)),
                    borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
                    border: Border.all(
                      color: isMatching
                          ? itemColor
                          : (isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : Colors.black.withValues(alpha: 0.06)),
                      width: isMatching ? 1.5 : 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: itemColor.withValues(alpha: 0.20),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: itemColor.withValues(alpha: 0.35),
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          AppIconCatalog.resolve(item.icon),
                          size: 20,
                          color: itemColor,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            item.name,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isMatching ? FontWeight.w800 : FontWeight.w700,
                              color: isMatching
                                  ? (isDark ? Colors.white : itemColor)
                                  : theme.textTheme.bodyMedium?.color,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.subtitle,
                            style: TextStyle(
                              fontSize: 10.5,
                              color: AppleTokens.systemGray,
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
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AppleModalSheetLayout(
      title: widget.existing == null ? l10n.addCategory : l10n.editCategory,
      subtitle: widget.existing == null
          ? 'Tạo danh mục để theo dõi ngân sách và báo cáo chuẩn xác'
          : 'Cập nhật tên, biểu tượng hoặc màu sắc nhận diện',
      bottomAction: AppleButton.primary(
        onPressed: _isSubmitting ? null : _submit,
        label: _isSubmitting ? 'Đang lưu...' : l10n.save,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Live Preview Card
            _buildLivePreviewCard(theme, isDark),
            const SizedBox(height: 16),

            // Segmented Type Selector
            LucianSlidingPillTabs<CategoryType>(
              items: [
                LucianTabItem(
                  value: CategoryType.expense,
                  label: l10n.expense,
                  icon: Icons.trending_down_rounded,
                  activeColor: LucianTokens.resolveDanger(isDark),
                ),
                LucianTabItem(
                  value: CategoryType.income,
                  label: l10n.income,
                  icon: Icons.trending_up_rounded,
                  activeColor: LucianTokens.resolveMint(isDark),
                ),
              ],
              selected: _type,
              onChanged: widget.existing != null
                  ? (_) {}
                  : (val) {
                      unawaited(HapticFeedback.selectionClick());
                      setState(() {
                        _type = val;
                        // Choose a smart default icon when switching types if current icon doesn't fit
                        if (val == CategoryType.income && _icon == 'food') {
                          _icon = 'salary';
                        } else if (val == CategoryType.expense && _icon == 'salary') {
                          _icon = 'food';
                        }
                      });
                    },
            ),

            if (widget.existing != null) ...[
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Không thể thay đổi loại Thu / Chi khi đang sửa danh mục',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppleTokens.systemGray,
                    fontSize: 11,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Popular Templates Carousel (Only shown when adding new category)
            if (widget.existing == null) ...[
              _buildTemplateSection(theme, isDark),
              const SizedBox(height: 18),
            ],

            // Category Name Input Field
            AppleTextField(
              controller: _nameController,
              maxLength: 100,
              label: l10n.categoryName,
              placeholder: _type == CategoryType.expense
                  ? 'VD: Cà phê, Xăng xe, Tiền trọ...'
                  : 'VD: Lương, Thưởng, Bán hàng...',
              prefixIcon: const Icon(CupertinoIcons.tag, size: 20),
              suffixIcon: _nameController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(CupertinoIcons.clear_thick_circled, size: 18),
                      tooltip: 'Xóa tên',
                      onPressed: () {
                        unawaited(HapticFeedback.lightImpact());
                        _nameController.clear();
                      },
                    )
                  : null,
              validator: (v) {
                final trimmed = v?.trim() ?? '';
                if (trimmed.isEmpty) {
                  return 'Vui lòng nhập tên danh mục';
                }
                if (trimmed.length > 100) {
                  return l10n.errorValidation;
                }
                return null;
              },
            ),

            const SizedBox(height: 20),

            // Icon & Color Section inside AppleGlassCard
            AppleGlassCard(
              borderRadius: BorderRadius.circular(AppleTokens.radiusHero),
              padding: const EdgeInsets.all(16),
              child: IconAndColorPicker(
                selectedIcon: _icon,
                selectedColor: _color,
                onIconChanged: (v) {
                  unawaited(HapticFeedback.selectionClick());
                  setState(() => _icon = v);
                },
                onColorChanged: (v) {
                  unawaited(HapticFeedback.selectionClick());
                  setState(() => _color = v);
                },
                iconSectionLabel: l10n.selectIcon,
                colorSectionLabel: l10n.selectColor,
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
