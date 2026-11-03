import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:so_thu_chi/core/constants/currency_constants.dart';
import 'package:so_thu_chi/core/constants/icon_catalog.dart';
import 'package:so_thu_chi/core/contracts/transaction_draft_contract.dart';
import 'package:so_thu_chi/core/l10n/l10n_ext.dart';
import 'package:so_thu_chi/core/router/app_routes.dart';
import 'package:so_thu_chi/core/theme/apple_theme_tokens.dart';
import 'package:so_thu_chi/core/utils/money.dart';
import 'package:so_thu_chi/core/widgets/apple_kit.dart';
import 'package:so_thu_chi/features/accounts/presentation/controllers/accounts_controller.dart';
import 'package:so_thu_chi/features/ai/domain/vietnamese_finance_nlp_parser.dart';
import 'package:so_thu_chi/features/categories/presentation/controllers/categories_controller.dart';
import 'package:so_thu_chi/features/transactions/domain/entities/transaction_entity.dart';
import 'package:so_thu_chi/features/transactions/presentation/controllers/transactions_controller.dart';

/// Apple-styled AI Vietnamese Quick Entry Card with live natural language parser.
class AiQuickEntryCard extends ConsumerStatefulWidget {
  const AiQuickEntryCard({super.key});

  @override
  ConsumerState<AiQuickEntryCard> createState() => _AiQuickEntryCardState();
}

class _AiQuickEntryCardState extends ConsumerState<AiQuickEntryCard> {
  final TextEditingController _textController = TextEditingController();
  final VietnameseFinanceNlpParser _parser = const VietnameseFinanceNlpParser();
  TransactionDraft? _currentDraft;
  bool _isAdding = false;
  bool _isExpanded = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _onTextChanged(String text) async {
    if (text.trim().isEmpty) {
      setState(() => _currentDraft = null);
      return;
    }
    final draft = await _parser.parseInput(text);
    if (!mounted) return;
    setState(() => _currentDraft = draft);
  }

  void _applySuggestion(String suggestion) {
    HapticFeedback.lightImpact();
    _textController.text = suggestion;
    _onTextChanged(suggestion);
    setState(() => _isExpanded = true);
  }

  Future<void> _quickAddNow() async {
    final draft = _currentDraft;
    if (draft == null || draft.amountMinorUnits == null || draft.amountMinorUnits! <= 0) return;

    final activeWallets = ref.read(activeAccountsProvider);
    if (activeWallets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng tạo ít nhất một ví tài khoản trước')),
      );
      return;
    }

    final targetAccountId = draft.accountId ?? activeWallets.first.id;
    final targetCategoryId = draft.categoryId ?? 'default_other_expense';
    final targetType = switch (draft.kind) {
      TransactionDraftKind.income => TransactionType.income,
      TransactionDraftKind.expense => TransactionType.expense,
      TransactionDraftKind.transfer => TransactionType.transfer,
    };

    setState(() => _isAdding = true);
    await HapticFeedback.mediumImpact();

    try {
      final res = await ref.read(transactionsActionControllerProvider.notifier).add(
        amount: draft.amountMinorUnits!,
        currency: draft.currencyCode ?? AppCurrencies.defaultCode,
        type: targetType,
        accountId: targetAccountId,
        categoryId: targetCategoryId,
        note: draft.note ?? '',
        date: draft.date ?? DateTime.now(),
        tags: draft.tags,
      );

      if (!mounted) return;
      res.fold(
        onSuccess: (tx) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Đã thêm: ${tx.money.format(locale: 'vi')} — ${tx.note.isNotEmpty ? tx.note : 'Giao dịch mới'}',
                    ),
                  ),
                ],
              ),
              backgroundColor: AppleTokens.jadeDark,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppleTokens.radiusCard)),
            ),
          );
          _textController.clear();
          setState(() {
            _currentDraft = null;
            _isExpanded = false;
          });
        },
        onFailure: (err) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.localizeError(err))),
          );
        },
      );
    } finally {
      if (mounted) setState(() => _isAdding = false);
    }
  }

  void _openFullForm() {
    final draft = _currentDraft;
    if (draft != null) {
      context.push(AppRoutes.transactionNew, extra: draft);
    } else {
      context.push(AppRoutes.transactionNew);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final categoriesMap = ref.watch(categoriesMapProvider);
    final activeWallets = ref.watch(activeAccountsProvider);

    final draft = _currentDraft;
    final category = draft?.categoryId != null ? categoriesMap[draft!.categoryId!] : null;
    final wallet = activeWallets.isNotEmpty ? activeWallets.first : null;

    final suggestions = [
      'Ăn trưa 45k',
      'Đổ xăng 70k ví tiền mặt',
      'Lương 20tr về Techcombank',
    ];

    return AppleGlassCard(
      blurSigma: 0,
      padding: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(AppleTokens.radiusHero),
      borderColor: isDark
          ? AppleTokens.jadePrimary.withValues(alpha: 0.35)
          : AppleTokens.jadePrimary.withValues(alpha: 0.25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF5CE0B8), Color(0xFF0D7C66)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(CupertinoIcons.sparkles, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Nhập Nhanh Bằng Tiếng Việt',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                    Text(
                      'Nhập câu tự nhiên: ăn uống, đổ xăng, tiền điện, lương...',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Search / Prompt Field
          TextField(
            controller: _textController,
            onChanged: _onTextChanged,
            onTap: () => setState(() => _isExpanded = true),
            decoration: InputDecoration(
              hintText: "Ví dụ: 'Ăn bún chả 50k', 'Đổ xăng 80k'...",
              hintStyle: TextStyle(
                fontSize: 13,
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              filled: true,
              fillColor: isDark
                  ? AppleTokens.bgDarkSecondary
                  : AppleTokens.bgLightSecondary.withValues(alpha: 0.6),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppleTokens.radiusControl),
                borderSide: BorderSide.none,
              ),
              suffixIcon: _textController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(CupertinoIcons.clear_thick_circled, size: 16),
                      onPressed: () {
                        _textController.clear();
                        _onTextChanged('');
                      },
                    )
                  : null,
            ),
          ),

          // Suggestion Chips when not typing
          if (!_isExpanded && draft == null) ...[
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final s in suggestions)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ApplePressable(
                        borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
                        onTap: () => _applySuggestion(s),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppleTokens.bgDarkSecondary
                                : AppleTokens.bgLightSecondary.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
                          ),
                          child: Text(
                            s,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 11.5,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],

          // Parsed Live Preview Tags
          if (draft != null && draft.amountMinorUnits != null && draft.amountMinorUnits! > 0) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? AppleTokens.bgDarkSecondary.withValues(alpha: 0.7)
                    : Colors.white,
                borderRadius: BorderRadius.circular(AppleTokens.radiusControl),
                border: Border.all(
                  color: AppleTokens.jadePrimary.withValues(alpha: 0.3),
                  width: AppleTokens.hairline,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Amount Tag
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppleTokens.jadePrimary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
                        ),
                        child: Text(
                          Money(
                            minorUnits: draft.amountMinorUnits!,
                            currencyCode: draft.currencyCode ?? 'VND',
                          ).format(locale: 'vi'),
                          style: const TextStyle(
                            color: AppleTokens.jadePrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Category Tag
                      if (category != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Color(category.color).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                AppIconCatalog.resolve(category.icon),
                                size: 13,
                                color: Color(category.color),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                category.name,
                                style: TextStyle(
                                  color: Color(category.color),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Wallet Tag
                      if (draft.accountId != null || wallet != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppleTokens.systemIndigo.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                CupertinoIcons.creditcard,
                                size: 12,
                                color: AppleTokens.systemIndigo,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                activeWallets.where((w) => w.id == draft.accountId).firstOrNull?.name ??
                                    wallet?.name ??
                                    '',
                                style: const TextStyle(
                                  color: AppleTokens.systemIndigo,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 11.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (draft.note != null && draft.note!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Ghi chú: ${draft.note}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Action Buttons: Quick Add vs Details
            Row(
              children: [
                Expanded(
                  child: ApplePressable(
                    borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
                    onTap: _isAdding ? null : _quickAddNow,
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppleTokens.jadePrimary,
                        borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
                      ),
                      alignment: Alignment.center,
                      child: _isAdding
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.flash_on_rounded, size: 16, color: Colors.white),
                                SizedBox(width: 6),
                                Text(
                                  'Thêm ngay',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ApplePressable(
                  borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
                  onTap: _openFullForm,
                  child: Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: isDark ? AppleTokens.bgDarkSecondary : AppleTokens.bgLightSecondary,
                      borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
                      border: Border.all(
                        color: isDark ? Colors.white12 : Colors.black12,
                        width: AppleTokens.hairline,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Chi tiết',
                      style: TextStyle(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
