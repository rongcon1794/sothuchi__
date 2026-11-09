import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:so_thu_chi/core/router/app_router.dart';
import 'package:so_thu_chi/core/router/app_routes.dart';
import 'package:so_thu_chi/core/theme/app_theme.dart';

void main() {
  group('iOS Swipe-to-Back & Adaptive Page Routing Tests', () {
    testWidgets(
      'adaptivePage produces CupertinoPage on iOS and MaterialPage on Android',
      (tester) async {
        final router = GoRouter(
          initialLocation: '/',
          routes: [
            GoRoute(
              path: '/',
              builder: (context, _) => const Scaffold(body: Text('Home')),
            ),
          ],
        );

        await tester.pumpWidget(
          MaterialApp.router(
            theme: AppTheme.light(),
            routerConfig: router,
          ),
        );
        await tester.pumpAndSettle();

        final mockState = GoRouterState(
          router.configuration,
          uri: Uri.parse('/detail'),
          matchedLocation: '/detail',
          name: 'detail',
          path: '/detail',
          fullPath: '/detail',
          pathParameters: const <String, String>{},
          pageKey: const ValueKey('detail'),
        );

        // Under iOS platform theme
        final iosTheme = AppTheme.light().copyWith(platform: TargetPlatform.iOS);
        await tester.pumpWidget(
          Theme(
            data: iosTheme,
            child: Builder(
              builder: (ctx) {
                final page = adaptivePage(
                  context: ctx,
                  state: mockState,
                  child: const Text('Detail Screen'),
                );
                expect(page, isA<CupertinoPage<void>>());
                return const SizedBox();
              },
            ),
          ),
        );

        // Under Android platform theme
        final androidTheme = AppTheme.light().copyWith(
          platform: TargetPlatform.android,
        );
        await tester.pumpWidget(
          Theme(
            data: androidTheme,
            child: Builder(
              builder: (ctx) {
                final page = adaptivePage(
                  context: ctx,
                  state: mockState,
                  child: const Text('Detail Screen'),
                );
                expect(page, isA<MaterialPage<void>>());
                return const SizedBox();
              },
            ),
          ),
        );
      },
    );

    testWidgets(
      'Interactive swipe from left edge on iOS pops the pushed detail screen',
      (tester) async {
        final router = GoRouter(
          initialLocation: '/',
          routes: [
            GoRoute(
              path: '/',
              builder: (context, _) => Scaffold(
                appBar: AppBar(title: const Text('Home Screen')),
                body: Center(
                  child: ElevatedButton(
                    onPressed: () => context.push('/detail'),
                    child: const Text('Open Detail'),
                  ),
                ),
              ),
            ),
            GoRoute(
              path: '/detail',
              pageBuilder: (context, state) => adaptivePage(
                context: context,
                state: state,
                child: Scaffold(
                  appBar: AppBar(title: const Text('Detail Screen')),
                  body: const Center(child: Text('Detail Content')),
                ),
              ),
            ),
          ],
        );

        await tester.pumpWidget(
          MaterialApp.router(
            theme: AppTheme.light().copyWith(platform: TargetPlatform.iOS),
            routerConfig: router,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Home Screen'), findsOneWidget);
        expect(find.text('Detail Content'), findsNothing);

        // Open detail
        await tester.tap(find.text('Open Detail'));
        await tester.pumpAndSettle();

        expect(find.text('Detail Screen'), findsOneWidget);
        expect(find.text('Detail Content'), findsOneWidget);

        // Verify CupertinoPageTransition is in the tree
        expect(find.byType(CupertinoPageTransition), findsOneWidget);

        // Perform edge swipe gesture from left edge (x: 5, y: 300) to right
        await tester.flingFrom(const Offset(5, 300), const Offset(400, 0), 1000.0);
        await tester.pumpAndSettle();

        // Screen popped back to Home Screen
        expect(find.text('Detail Content'), findsNothing);
        expect(find.text('Home Screen'), findsOneWidget);
      },
    );

    testWidgets(
      'goRouterProvider has pageBuilder on detail and subroutes',
      (tester) async {
        final container = ProviderContainer();
        addTearDown(container.dispose);
        final router = container.read(goRouterProvider);

        final expectedPageBuilderPaths = [
          AppRoutes.transactionNew,
          '/transactions/:id',
          '/transactions/:id/edit',
          AppRoutes.accounts,
          '/accounts/:id',
          AppRoutes.categories,
          '/categories/:id',
          '/budgets/:id',
          AppRoutes.debts,
          '/debts/:id',
          AppRoutes.recurring,
          '/recurring/:id',
          AppRoutes.savings,
          '/savings/:id',
          AppRoutes.ledgers,
        ];

        for (final path in expectedPageBuilderPaths) {
          final match = router.configuration.routes
              .whereType<GoRoute>()
              .firstWhere(
                (r) => r.path == path,
                orElse: () => throw StateError('Route $path not found in root routes'),
              );
          expect(
            match.pageBuilder,
            isNotNull,
            reason: 'Route $path must specify pageBuilder for adaptive iOS swipe',
          );
        }
      },
    );
  });
}
