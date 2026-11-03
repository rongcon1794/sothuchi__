import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Clean Architecture & API Contract Guardrails', () {
    test(
      'core/, domain/, and presentation/ layers never import Firebase or GoogleSignIn SDKs directly',
      () {
        final libDir = Directory('lib');
        expect(libDir.existsSync(), isTrue);

        const forbiddenImports = [
          'package:cloud_firestore/',
          'package:firebase_auth/',
          'package:firebase_core/',
          'package:google_sign_in/',
        ];

        final violations = <String>[];
        for (final entity in libDir.listSync(recursive: true)) {
          if (entity is! File || !entity.path.endsWith('.dart')) continue;
          final normalizedPath = entity.path.replaceAll(r'\', '/');
          if (normalizedPath.endsWith('.g.dart') ||
              normalizedPath.endsWith('.freezed.dart')) {
            continue;
          }

          final isProtectedLayer =
              normalizedPath.contains('/core/') ||
              normalizedPath.contains('/domain/') ||
              normalizedPath.contains('/presentation/');
          if (!isProtectedLayer) continue;

          final content = entity.readAsStringSync();
          for (final forbidden in forbiddenImports) {
            if (content.contains(forbidden)) {
              violations.add('$normalizedPath imports $forbidden');
            }
          }
        }

        expect(
          violations,
          isEmpty,
          reason:
              'core/, domain/, and presentation/ layers must depend ONLY on repository interfaces:\n${violations.join('\n')}',
        );
      },
    );

    test(
      'data/ never imports presentation/, and UI widgets/screens/core never import data/',
      () {
        final libDir = Directory('lib');
        final violations = <String>[];

        for (final entity in libDir.listSync(recursive: true)) {
          if (entity is! File || !entity.path.endsWith('.dart')) continue;
          final normalizedPath = entity.path.replaceAll(r'\', '/');
          if (normalizedPath.endsWith('.g.dart') ||
              normalizedPath.endsWith('.freezed.dart')) {
            continue;
          }

          final content = entity.readAsStringSync();

          final isDataLayer =
              normalizedPath.contains('/lib/data/') ||
              (normalizedPath.contains('/features/') &&
                  normalizedPath.contains('/data/'));
          if (isDataLayer && content.contains('/presentation/')) {
            violations.add(
              '$normalizedPath (data layer) imports presentation layer',
            );
          }

          final isCoreOrUiWidget =
              normalizedPath.contains('/lib/core/') ||
              normalizedPath.contains('/presentation/screens/') ||
              normalizedPath.contains('/presentation/widgets/');
          if (isCoreOrUiWidget &&
              content.contains('package:so_thu_chi/data/')) {
            violations.add(
              '$normalizedPath (UI/core) imports package:so_thu_chi/data/ directly instead of going through controllers or contracts',
            );
          }
        }

        expect(violations, isEmpty, reason: violations.join('\n'));
      },
    );

    test(
      'codebase never uses deprecated pre-7.0 GoogleSignIn() constructor or .signIn()',
      () {
        final libDir = Directory('lib');
        final violations = <String>[];

        for (final entity in libDir.listSync(recursive: true)) {
          if (entity is! File || !entity.path.endsWith('.dart')) continue;
          final normalizedPath = entity.path.replaceAll(r'\', '/');
          if (normalizedPath.endsWith('.g.dart') ||
              normalizedPath.endsWith('.freezed.dart')) {
            continue;
          }
          final content = entity.readAsStringSync();
          if (RegExp(r'\bGoogleSignIn\s*\(').hasMatch(content)) {
            violations.add(
              '$normalizedPath calls deprecated GoogleSignIn() constructor',
            );
          }
          if (RegExp(r'GoogleSignIn\.instance\.signIn\s*\(').hasMatch(content)) {
            violations.add('$normalizedPath calls deprecated .signIn() method');
          }
        }

        expect(violations, isEmpty, reason: violations.join('\n'));
      },
    );
  });
}
