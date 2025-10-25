import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast_memory.dart';
import 'package:sembast/sembast.dart';

import 'package:youbrewty/storage/sembast_form_store.dart';
import 'package:youbrewty/storage/form_store.dart';
import 'package:youbrewty/storage/form_instance.dart';

void main() {
  test('SembastFormStore in-memory save/load', () async {
    final dbFactory = databaseFactoryMemory;
    final store = SembastFormStore(dbPath: 'in_memory.db', dbFactory: dbFactory);
    await store.init();

    final fi = FormInstance(
      id: '1',
      templateId: 'brew_batch_v1',
      values: {'recipe_name': {'descriptorId': 'recipe_name', 'value': 'Test'}},
    );

    await store.saveForm(fi);
    final loaded = await store.loadForm('1');
    expect(loaded, isNotNull);
    expect(loaded!.templateId, 'brew_batch_v1');

    await store.deleteForm('1');
    final loaded2 = await store.loadForm('1');
    expect(loaded2, isNull);

    await store.close();
  });
}
