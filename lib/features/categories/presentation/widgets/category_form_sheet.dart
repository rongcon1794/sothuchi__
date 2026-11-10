import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:so_thu_chi/core/constants/icon_catalog.dart';
import 'package:so_thu_chi/core/l10n/l10n_ext.dart';
import 'package:so_thu_chi/core/theme/app_theme.dart';
import 'package:so_thu_chi/core/theme/apple_theme_tokens.dart';
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
    final isDefault = widget.existing?.isDefault ?? false;
    final trimmedName = _nameController.text.trim();
    final displayName = trimmedName.isEmpty
        ? (isIncome ? 'Khoản thu mới' : 'Khoản chi mới')
        : trimmedName;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 8),
          child: Row(
            children: [
              Icon(
                Icons.remove_red_eye_outlined,
                size: 14,
                color: AppleTokens.systemGray,
              ),
              SizedBox(width: 6),
              Text(
                'BẢN XEM TRƯỚC DANH MỤC TRÊN DANH SÁCH',
                style: TextStyle(
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
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
          child: Row(
            children: [
              // Squircle Badge with glowing border and subtle shadow
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: activeColor.withValues(alpha: isDark ? 0.22 : 0.14),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: activeColor.withValues(alpha: isDark ? 0.40 : 0.28),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: activeColor.withValues(alpha: isDark ? 0.22 : 0.14),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  AppIconCatalog.resolve(_icon),
                  color: activeColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),

              // Middle Column: Title & Metadata Badges
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      displayName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 15.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        // Default or Custom badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6.5, vertical: 2),
                          decoration: BoxDecoration(
                            color: isDefault
                                ? AppleTokens.systemBlue.withValues(alpha: 0.12)
                                : AppleTokens.systemPurple.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
                          ),
                          child: Text(
                            isDefault ? 'Mặc định' : 'Tùy chỉnh',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: isDefault
                                  ? AppleTokens.systemBlue
                                  : AppleTokens.systemPurple,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        // Transaction count indicator
                        const Flexible(
                          child: Text(
                            'Chưa dùng',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              fontFeatures: AppTheme.tabularFigures,
                              color: AppleTokens.systemGray,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Right Column: Month Spend & Actions
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '0 ₫',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white24 : Colors.black26,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    width: 26,
                    height: 26,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.black.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
                    ),
                    child: const Icon(
                      Icons.more_horiz_rounded,
                      size: 18,
                      color: AppleTokens.systemGray,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
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
                            style: const TextStyle(
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
