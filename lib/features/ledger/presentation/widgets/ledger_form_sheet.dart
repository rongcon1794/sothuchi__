import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:so_thu_chi/core/constants/currency_constants.dart';
import 'package:so_thu_chi/core/l10n/l10n_ext.dart';
import 'package:so_thu_chi/core/theme/apple_theme_tokens.dart';
import 'package:so_thu_chi/core/widgets/apple_kit.dart';
import 'package:so_thu_chi/features/ledger/domain/entities/ledger_book.dart';
import 'package:so_thu_chi/features/ledger/presentation/controllers/ledgers_controller.dart';

class LedgerFormSheet extends ConsumerStatefulWidget {
  const LedgerFormSheet({super.key, this.existing});

  final LedgerBook? existing;

  static Future<void> show(BuildContext context, {LedgerBook? existing}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
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

  static const _availableIcons = [
    ('person', CupertinoIcons.person_crop_circle_fill, 'Cá nhân'),
    ('family', CupertinoIcons.person_3_fill, 'Gia đình'),
    ('briefcase', CupertinoIcons.briefcase_fill, 'Công việc'),
    ('wallet', CupertinoIcons.creditcard_fill, 'Quỹ riêng'),
    ('star', CupertinoIcons.star_fill, 'Đặc biệt'),
  ];

  static const _availableColors = [
    0xFF00A86B, // Jade Green
    0xFF007AFF, // iOS Blue
    0xFF5856D6, // Indigo
    0xFFFF9500, // Orange
    0xFFFFCC00, // Amber
    0xFAF55050, // Ruby / Red
    0xFFAF52DE, // Purple
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
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = context.l10n;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppleTokens.bgDarkCard : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppleTokens.radiusSheet)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 16, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _isEditing ? l10n.ledgerEditTitle : l10n.ledgerNewTitle,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    IconButton(
                      icon: const Icon(CupertinoIcons.xmark_circle_fill, color: AppleTokens.systemGray),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),

              Flexible(
                child: Form(
                  key: _formKey,
                  child: ListView(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: [
                      // Name input
                      AppleTextField(
                        controller: _nameController,
                        label: l10n.ledgerName,
                        placeholder: l10n.ledgerNameHint,
                        prefixIcon: const Icon(CupertinoIcons.book, size: 18),
                        validator: (v) => (v == null || v.trim().isEmpty) ? l10n.ledgerNameRequired : null,
                      ),
                      const SizedBox(height: 16),

                      // Type selector
                      DropdownButtonFormField<LedgerType>(
                        initialValue: _type,
                        decoration: InputDecoration(
                          labelText: l10n.ledgerType,
                          prefixIcon: const Icon(CupertinoIcons.tag),
                        ),
                        items: [
                          DropdownMenuItem(value: LedgerType.personal, child: Text(l10n.ledgerPersonal)),
                          DropdownMenuItem(value: LedgerType.family, child: Text(l10n.ledgerFamily)),
                          DropdownMenuItem(value: LedgerType.business, child: Text(l10n.ledgerBusiness)),
                          DropdownMenuItem(value: LedgerType.custom, child: Text(l10n.ledgerCustom)),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _type = val);
                        },
                      ),
                      const SizedBox(height: 16),

                      // Icon selector
                      Text(l10n.ledgerIcon, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppleTokens.systemGray)),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 52,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _availableIcons.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 10),
                          itemBuilder: (context, index) {
                            final item = _availableIcons[index];
                            final isSelected = _selectedIcon == item.$1;
                            return GestureDetector(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setState(() => _selectedIcon = item.$1);
                              },
                              child: Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: isSelected ? Color(_selectedColor) : (isDark ? AppleTokens.bgDarkSecondary : AppleTokens.bgLightSecondary),
                                  borderRadius: BorderRadius.circular(AppleTokens.radiusControl),
                                  border: isSelected ? Border.all(color: Colors.white, width: 2) : null,
                                ),
                                child: Icon(
                                  item.$2,
                                  color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                                  size: 22,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Color selector
                      Text(l10n.ledgerColor, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppleTokens.systemGray)),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 44,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _availableColors.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 10),
                          itemBuilder: (context, index) {
                            final colorVal = _availableColors[index];
                            final isSelected = _selectedColor == colorVal;
                            return GestureDetector(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setState(() => _selectedColor = colorVal);
                              },
                              child: Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: Color(colorVal),
                                  shape: BoxShape.circle,
                                  border: isSelected
                                      ? Border.all(color: isDark ? Colors.white : Colors.black, width: 3)
                                      : null,
                                ),
                                child: isSelected
                                    ? const Icon(CupertinoIcons.checkmark, color: Colors.white, size: 20)
                                    : null,
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Submit button
                      AppleButton.primary(
                        color: Color(_selectedColor),
                        label: _isEditing ? l10n.ledgerConfirmUpdate : l10n.ledgerConfirmCreate,
                        onPressed: _submit,
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

