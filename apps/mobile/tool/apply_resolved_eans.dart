// Applies the backend curated-seed result to the mobile manifest overlay.
//
// Reads the slug→EAN map the seed CLI writes
// (`server/.tmp/curated-eans.json`) and regenerates
// `lib/features/catalog/data/resolved_eans.g.dart` so the bundled launch
// products resolve their real barcodes (and thus real nutrition/health).
//
// Usage (from apps/mobile):
//   dart run tool/apply_resolved_eans.dart [path/to/curated-eans.json]
//
// Default input path is ../../server/.tmp/curated-eans.json relative to the
// app root. Idempotent — safe to re-run; only real, OFF-resolved EANs are
// written (the seed never emits guessed codes).

import 'dart:convert';
import 'dart:io';

Future<void> main(List<String> args) async {
  final inputPath = args.isNotEmpty
      ? args.first
      : '../../server/.tmp/curated-eans.json';

  final inputFile = File(inputPath);
  if (!inputFile.existsSync()) {
    stderr.writeln('✖ Seed result not found at: ${inputFile.absolute.path}');
    stderr.writeln(
      '  Run the backend seed first:  pnpm -C server db:import:curated',
    );
    exitCode = 1;
    return;
  }

  final raw = jsonDecode(await inputFile.readAsString());
  final resolvedDynamic = (raw is Map && raw['resolved'] is Map)
      ? raw['resolved'] as Map
      : (raw is Map ? raw : <String, dynamic>{});

  // Keep only well-formed string→string pairs with plausible retail barcodes.
  final entries = <String, String>{};
  resolvedDynamic.forEach((key, value) {
    if (key is String && value is String) {
      final ean = value.trim();
      if (ean.length >= 6 &&
          ean.length <= 13 &&
          RegExp(r'^\d+$').hasMatch(ean)) {
        entries[key] = ean;
      }
    }
  });

  final sortedKeys = entries.keys.toList()..sort();
  final buffer = StringBuffer()
    ..writeln('// GENERATED — do not edit by hand.')
    ..writeln('//')
    ..writeln(
      '// Maps a curated launch-catalog product `slug` to the **real** market barcode',
    )
    ..writeln('// resolved by the backend Open Food Facts seed')
    ..writeln('// (`server/src/db/import-curated-catalog.ts`), applied by')
    ..writeln('// `apps/mobile/tool/apply_resolved_eans.dart`.')
    ..writeln('//')
    ..writeln(
      '// Honesty contract: every entry was resolved from a real OFF row at seed time —',
    )
    ..writeln(
      '// none are guessed. Unresolved products are absent (app shows "scan to unlock").',
    )
    ..writeln('')
    ..writeln('const Map<String, String> kResolvedEans = <String, String>{');
  for (final key in sortedKeys) {
    buffer.writeln("  '$key': '${entries[key]}',");
  }
  buffer.writeln('};');

  final outFile = File('lib/features/catalog/data/resolved_eans.g.dart');
  await outFile.writeAsString(buffer.toString());

  stdout.writeln(
    '✓ Wrote ${entries.length} resolved EAN(s) to ${outFile.path}',
  );
}
