import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:so_thu_chi/core/l10n/l10n_ext.dart';
import 'package:so_thu_chi/core/theme/apple_theme_tokens.dart';
import 'package:so_thu_chi/core/widgets/apple_kit.dart';
import 'package:so_thu_chi/features/transactions/presentation/controllers/transactions_controller.dart';

/// Smart Tag Section with chip pills, interactive inline input, and dynamic frequently used tags.
class TransactionSmartTagsSection extends ConsumerWidget {
  const TransactionSmartTagsSection({
    super.key,
    required this.selectedTags,
    required this.tagInputController,
    required this.onAddTag,
    required this.onRemoveTag,
    required this.isDark,
  });

  final List<String> selectedTags;
  final TextEditingController tagInputController;
  final ValueChanged<String> onAddTag;
  final ValueChanged<String> onRemoveTag;
  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final allTxs = ref.watch(transactionsStreamProvider).value ?? const [];

    // Calculate frequent tags
    final Map<String, int> tagCounts = {};
    for (final tx in allTxs) {
      for (final tag in tx.tags) {
        final clean = tag.trim().replaceAll('#', '');
        if (clean.isNotEmpty) {
          tagCounts[clean] = (tagCounts[clean] ?? 0) + 1;
        }
      }
    }

    // Default suggestions fallback
    const defaultTags = [
      'thiết yếu',
      'cố định',
      'gia đình',
      'công việc',
      'bạn bè',
      'phát sinh'
    ];
    for (final dt in defaultTags) {
      tagCounts.putIfAbsent(dt, () => 0);
    }

    final sortedFrequentTags = tagCounts.keys.toList()
      ..sort((a, b) => (tagCounts[b] ?? 0).compareTo(tagCounts[a] ?? 0));

    final availableFrequent = sortedFrequentTags
        .where((t) => !selectedTags.contains(t))
        .take(8)
        .toList();

    final theme = Theme.of(context);
    final tagColor = theme.colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              AppleSquircleBadge(
                icon: CupertinoIcons.tag,
                backgroundColor: tagColor,
                size: 36,
                iconSize: 18,
                radius: 10,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Active tags chips wrap
                    if (selectedTags.isNotEmpty) ...[
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final tag in selectedTags)
                            Container(
                              padding: const EdgeInsets.fromLTRB(10, 4, 6, 4),
                              decoration: BoxDecoration(
                                color: tagColor.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(
                                  AppleTokens.radiusPill,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '#$tag',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: tagColor,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  GestureDetector(
                                    onTap: () => onRemoveTag(tag),
                                    child: Icon(
                                      CupertinoIcons.xmark_circle_fill,
                                      size: 15,
                                      color: tagColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                    ],

                    // Tag Input Field with + Add button
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: tagInputController,
                            textCapitalization: TextCapitalization.sentences,
                            inputFormatters: const [
                              FirstLetterCapitalizationFormatter(),
                            ],
                            textInputAction: TextInputAction.done,
                            scrollPadding:
                                const EdgeInsets.fromLTRB(20, 20, 20, 360),
                            onFieldSubmitted: (val) {
                              if (val.trim().isNotEmpty) {
                                onAddTag(val.trim());
                              }
                            },
                            onChanged: (val) {
                              if (val.endsWith(',') || val.endsWith(' ')) {
                                final clean = val.replaceAll(',', '').trim();
                                if (clean.isNotEmpty) {
                                  onAddTag(clean);
                                }
                              }
                            },
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              filled: false,
                              fillColor: Colors.transparent,
                              isDense: true,
                              contentPadding:
                                  const EdgeInsets.symmetric(vertical: 6),
                              hintText: selectedTags.isEmpty
                                  ? l10n.tagsHint
                                  : l10n.addTagHint,
                              hintStyle: TextStyle(
                                fontSize: 13.5,
                                color: isDark
                                    ? const Color(0xFF6C6C70)
                                    : const Color(0xFF8E8E93),
                              ),
                            ),
                          ),
                        ),
                        ListenableBuilder(
                          listenable: tagInputController,
                          builder: (context, _) {
                            if (tagInputController.text.trim().isEmpty) {
                              return const SizedBox.shrink();
                            }
                            return ApplePressable(
                              scaleDown: 0.92,
                              onTap: () {
                                final text = tagInputController.text.trim();
                                if (text.isNotEmpty) {
                                  onAddTag(text);
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: tagColor,
                                  borderRadius: BorderRadius.circular(
                                    AppleTokens.radiusPill,
                                  ),
                                ),
                                child: Text(
                                  l10n.addTag,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Frequent Tags Suggestion Bar
          if (availableFrequent.isNotEmpty) ...[
            const SizedBox(height: 6),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final tag in availableFrequent)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ApplePressable(
                        scaleDown: 0.93,
                        onTap: () => onAddTag(tag),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppleTokens.bgDarkSecondary
                                : AppleTokens.bgLightSecondary,
                            borderRadius:
                                BorderRadius.circular(AppleTokens.radiusPill),
                          ),
                          child: Text(
                            '#$tag',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: isDark
                                  ? const Color(0xFFE5E5EA)
                                  : const Color(0xFF3A3A3C),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
