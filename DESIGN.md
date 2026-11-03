# DESIGN.md — Design System & Art Direction

## Aesthetic Direction: Refined Vietnamese Fintech ("Jade Ledger")
- **Mode:** Operate — high scanability, calm precision, zero visual clutter, native Material 3 ergonomics tailored for fast one-handed financial entry.
- **Seed Palette:** Imperial Jade (`#0D7C66`) symbolizing prosperity and clarity, paired with warm alabaster surfaces in Light Mode (`#F8FAF9`) and deep obsidian-slate surfaces in Dark Mode (`#0F1513`).

## Color Tokens & Semantic Contrast (WCAG AA >= 4.5:1)
- **Primary Seed:** `#0D7C66` (Jade Green)
- **Semantic Financial Colors:**
  - **Income (`thu`):** Light `#0B7A5C` on `#E3F6EF` / Dark `#5CE0B8` on `#0E382C`
  - **Expense (`chi`):** Light `#C0352B` on `#FCEAE8` / Dark `#FF8A80` on `#3E1815`
  - **Transfer (`chuyển khoản`):** Light `#1D5BD6` on `#E8F0FE` / Dark `#8AB4F8` on `#162B54`
  - **Warning / Threshold (`cảnh báo ngân sách`):** Light `#B25E09` on `#FEF3E2` / Dark `#FFB74D` on `#3B2307`
- **Elevation Rule:** Declare elevation once — use Material 3 tonal surface containers (`surfaceContainerLowest` -> `surfaceContainerHigh`) with a crisp `1px` `outlineVariant` border (`alpha: 0.45`) and zero muddy drop-shadows. Never nest cards inside cards.

## Typography & Numerals
- **Hierarchy:** Clear scale steps across `displaySmall` (Hero Net Balance), `headlineSmall` (Monthly Totals / Form Amount), `titleMedium` (Section & Day Headers), `bodyLarge` (Transaction Titles), and `labelMedium` (Metadata & Badges).
- **Tabular Figures (Mandatory):** Every currency amount, percentage, date header, and chart axis label applies `FontFeature.tabularFigures()` so digits align vertically down transaction lists without jitter.
- **VND Formatting:** Integer grouping with dot separators (`1.250.000 ₫` in `vi`, `1,250,000 ₫` or localized symbol per active locale), never showing `.00` decimals for zero-decimal currencies (`VND`, `JPY`, `KRW`).

## Spacing, Radii & Touch Ergonomics
- **Grid:** Strict `4dp` / `8dp` spatial rhythm (`4, 8, 12, 16, 20, 24, 32`).
- **Corner Radii:** Cards & sheets `16dp`, inputs & tiles `12dp`, filter chips `8dp`–`20dp`.
- **Touch Targets:** Minimum `48x48 dp` on all interactive buttons, icon toggles, swipe actions, and picker items.
- **Iconography:** Unified Material Symbols (`Icons.*_rounded`) across wallets, categories, and navigation — never raw emoji standing in for UI icons.

