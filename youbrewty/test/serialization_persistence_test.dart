import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:youbrewty/models.dart';
import 'package:youbrewty/utils/serialization.dart';
import 'package:youbrewty/utils/test_data.dart';

void main() {
  test('serialize to disk -> deserialize preserves ids and structure', () async {
    final batches = generateBatchesForUi(batchCount: 8);
    final serialized = batches.map(batchToJson).toList();

    // Write to a temp file
    final tmpDir = Directory.systemTemp.createTempSync('youbrewty_test_');
    final file = File('${tmpDir.path}/batches.json');
    await file.writeAsString(jsonEncode(serialized));

    // Read back
    final read = jsonDecode(await file.readAsString()) as List<dynamic>;
    final deserialized = deserializeBatches(read.cast<Map<String, dynamic>>());

    // Basic sanity checks
    expect(deserialized.length, equals(batches.length));
    final origIds = batches.map((b) => b.batchId).toSet();
    final newIds = deserialized.map((b) => b.batchId).toSet();
    expect(newIds, equals(origIds));

    tmpDir.deleteSync(recursive: true);
  });
}
