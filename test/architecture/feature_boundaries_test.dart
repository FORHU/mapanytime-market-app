import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// A feature's widgets and pages are private to it. Anything a second feature
/// needs goes in `lib/shared/` — so no file in one feature, and no file in
/// `lib/shared/`, may import another feature's `presentation/widgets/` or
/// `presentation/pages/`.
///
/// `lib/routes/` is exempt: the router exists to wire pages together.
/// Controllers and domain types may still cross features; this rule is about
/// UI only.
void main() {
  final privateUi = RegExp(
    r"import 'package:mapanytime_market_app/features/(\w+)/presentation/(?:widgets|pages)/",
  );
  final featurePath = RegExp(r'^lib[\\/]features[\\/](\w+)[\\/]');

  test(
    "no feature or shared file imports another feature's widgets or pages",
    () {
      final violations = <String>[];

      final files = Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'));

      for (final file in files) {
        final path = file.path;
        final owner = featurePath.firstMatch(path)?.group(1);
        final isShared =
            path.startsWith('lib${Platform.pathSeparator}shared') ||
            path.startsWith('lib/shared');
        if (owner == null && !isShared) continue;

        final lines = file.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          final imported = privateUi.firstMatch(lines[i])?.group(1);
          if (imported != null && imported != owner) {
            violations.add('$path:${i + 1} imports features/$imported UI');
          }
        }
      }

      expect(
        violations,
        isEmpty,
        reason:
            'Move the widget into lib/shared/ (or its type into the owning '
            "feature's domain/) instead:\n${violations.join('\n')}",
      );
    },
  );
}
