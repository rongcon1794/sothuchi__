# PRODUCT.md — Sổ Thu Chi (Smart Personal Finance Tracker)

## Vision & Target Audience
**Sổ Thu Chi** is a fast, modern, offline-capable personal finance tracking application designed primarily for **Vietnamese users** (with full English localization). It enables effortless daily income, expense, and wallet-transfer tracking in integer minor units (defaulting to VND `1.250.000 ₫` with zero floating-point rounding bugs), monthly budgeting with proactive threshold alerts, visual category/trend analytics, and seamless multi-device cloud sync via Firebase Auth (Google Sign-In) and Cloud Firestore.

## Platforms & Localization
- **Platforms:** Android & iOS from a single Flutter codebase.
- **Languages:** Vietnamese (`vi`, default) and English (`en`, secondary) via Flutter `gen-l10n` ARB resources.
- **Currencies:** Selectable (`VND` default with 0 decimals; `USD`, `EUR` with 2 decimals; `JPY`, `KRW` with 0 decimals).

## Core Workflows (Phase 1 MVP)
1. **Onboarding & Authentication:** 3-slide value onboarding -> Google Sign-In (`google_sign_in` v7 API) -> Automatic seeding of Vietnamese default categories & initial Cash wallet on first login -> Persistent session, Sign Out, and full Account + Data Deletion for privacy compliance.
2. **Home Dashboard:** Total net balance across active wallets (with one-tap privacy mask toggle), current month Income vs. Expense summary, active budget threshold warnings, recent transactions, and instant Add Transaction FAB.
3. **Wallets / Accounts:** Manage `cash`, `bank`, `ewallet`, and `card` accounts; atomic balance updates from transactions; archive/unarchive wallets; inter-wallet transfers.
4. **Transactions:** Record income, expense, or transfer; real-time thousand-separator amount input; soft-delete with instant Undo snackbar; swipe actions; day-grouped ledger with daily net totals; search by note/tags and multi-criteria filtering (date range, category, wallet, type).
5. **Categories:** Pre-seeded Vietnamese categories (`Ăn uống`, `Di chuyển`, `Nhà ở`, `Hóa đơn`, `Mua sắm`, `Giải trí`, `Sức khỏe`, `Giáo dục`, `Lương`, `Thưởng`, `Khác`...) plus custom categories with curated icon & color pickers.
6. **Budgets:** Overall monthly budget and/or per-category monthly budgets with configurable alert threshold (e.g., 80%), visual progress bars, and immediate in-app warnings upon crossing thresholds.
7. **Reports:** Interactive month switcher, monthly net summary, expense-by-category Donut chart (`fl_chart`), and 6-month Income vs. Expense trend Bar/Line chart.
8. **Settings & Offline Sync:** System/Light/Dark theme, `vi`/`en` switcher, currency selector, biometric app lock (`local_auth`), UTF-8 BOM CSV export, offline/syncing status badge, privacy policy, and app info.

## Extensibility Architecture (Phase 2 Readiness)
- Strict Repository Interface boundary (`domain/` & `presentation/` have zero imports from `cloud_firestore`, `firebase_auth`, or `google_sign_in`).
- `TransactionDraft` contract allows future `lib/features/ai/` modules (natural-language parsing like `"ăn phở 50k hôm qua"`, receipt OCR, smart categorization) to populate transactions without modifying existing feature modules.

