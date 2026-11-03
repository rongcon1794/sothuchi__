# CONSTRAINTS.md — Quality & Engineering Contract

Last reviewed: 2026-11-03 (Autonomous `/goal` Floor + Architecture Gates)

## Floor (Always Enforced)
- **Zero Static Analysis Issues:** `flutter analyze` must exit with `0` errors, `0` warnings, and `0` lints after every milestone.
- **No Lint Suppressions:** No `// ignore:` or `// ignore_for_file:` comments in handwritten code (only generated `*.g.dart` / `*.freezed.dart` files are excluded via `analysis_options.yaml`).
- **No Unimplemented Stubs or Silent Catches:** Zero `UnimplementedError`, zero `// TODO`, and zero empty `catch (_) {}` blocks. Every failure maps to a typed `AppException` / `Result<T>` with localized Vietnamese & English messages.
- **No Secrets in Source Control:** `google-services.json`, `GoogleService-Info.plist`, `firebase_options.dart`, and `.env*` are strictly `.gitignore`d; only `.example` templates are committed.
- **Integer-Only Money:** Money is stored and calculated strictly as `int` minor units + ISO 4217 currency code. Never use `double` for monetary storage or arithmetic.
- **Soft Delete Audit Trail:** Every Firestore document (`users`, `accounts`, `categories`, `transactions`, `budgets`) carries `createdAt`, `updatedAt`, and `deletedAt`.

## Enforced Architecture & Quality Gates

| Dimension | Rule | Checked By | Runs At |
|---|---|---|---|
| Static Analysis | 0 issues | `flutter analyze` | Every milestone |
| Architecture Boundary | `domain/` & `presentation/` never import `cloud_firestore`, `firebase_auth`, or `google_sign_in` | `test/architecture/architecture_boundary_test.dart` | Every test run |
| Google Sign-In API | Uses `google_sign_in` v7 `GoogleSignIn.instance`, `initialize()`, `authenticate()`; zero deprecated `GoogleSignIn()` or `.signIn()` | Static analysis + `architecture_boundary_test.dart` | Every test run |
| Unit & Widget Tests | 100% pass across Money, Date, Repositories, and main UI flows | `flutter test` | Every milestone |
| Accessibility | Semantic labels on icon controls, contrast >= 4.5:1, touch targets >= 48dp | `flutter_a11y_agent` + widget semantics tests | Milestone (h) |
| Firestore Security | Strict `request.auth.uid == uid` isolation + schema/type validation | `firestore-rules-author` review | Milestone (h) |

