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

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppleSquircleBadge(
                icon: CupertinoIcons.tag,
                backgroundColor: AppleTokens.systemPink,
                size: 38,
                iconSize: 18,
                radius: 10,
              ),
              const SizedBox(width: 14),
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
                                color: AppleTokens.systemPink
                                    .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(
                                    AppleTokens.radiusPill),
                                border: Border.all(
                                  color: AppleTokens.systemPink
                                      .withValues(alpha: 0.35),
                                  width: AppleTokens.hairline,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '#$tag',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppleTokens.systemPink,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  GestureDetector(
                                    onTap: () => onRemoveTag(tag),
                                    child: const Icon(
                                      CupertinoIcons.xmark_circle_fill,
                                      size: 15,
                                      color: AppleTokens.systemPink,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],

                    // Tag Input Field with + Add button
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: tagInputController,
                            textInputAction: TextInputAction.done,
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
                            style: const TextStyle(fontSize: 14),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding:
                                  const EdgeInsets.symmetric(vertical: 6),
                              hintText: selectedTags.isEmpty
                                  ? l10n.tagsHint
                                  : l10n.addTagHint,
                              hintStyle: TextStyle(
                                fontSize: 13,
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
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppleTokens.systemPink,
                                  borderRadius: BorderRadius.circular(
                                      AppleTokens.radiusPill),
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
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Row(
                      children: [
                        const Icon(CupertinoIcons.tag_circle,
                            size: 13, color: AppleTokens.systemPink),
                        const SizedBox(width: 4),
                        Text(
                          l10n.frequentTags,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? const Color(0xFF98989F)
                                : const Color(0xFF6E6E73),
                          ),
                        ),
                        const SizedBox(width: 4),
                      ],
                    ),
                  ),
                  for (final tag in availableFrequent)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ApplePressable(
                        scaleDown: 0.92,
                        onTap: () => onAddTag(tag),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppleTokens.bgDarkSecondary
                                : AppleTokens.bgLightSecondary,
                            borderRadius:
                                BorderRadius.circular(AppleTokens.radiusPill),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.10)
                                  : Colors.black.withValues(alpha: 0.06),
                              width: AppleTokens.hairline,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '#$tag',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppleTokens.systemPink
                                      .withValues(alpha: 0.9),
                                ),
                              ),
                              const SizedBox(width: 2),
                              const Icon(CupertinoIcons.plus,
                                  size: 10, color: AppleTokens.systemPink),
                            ],
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
