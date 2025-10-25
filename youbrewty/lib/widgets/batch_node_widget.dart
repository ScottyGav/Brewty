import 'package:flutter/material.dart';
import '../models.dart';

class BatchNodeWidget extends StatelessWidget {
  final Batch batch;
  final Map<String, Batch> batchMap;
  final Set<String> visited;

  BatchNodeWidget({required this.batch, required this.batchMap, Set<String>? visited})
      : visited = visited ?? {};

  @override
  Widget build(BuildContext context) {
    if (visited.contains(batch.batchId)) {
      return Text('↳ ${batch.batchId} [see above]', style: TextStyle(fontStyle: FontStyle.italic));
    }
    final newVisited = Set<String>.from(visited)..add(batch.batchId);

    return ExpansionTile(
      title: Text('Batch ${batch.batchId} (${batch.name})'),
      children: [
        ...batch.ingredientEvents.map((e) => ListTile(
              title: Text('${e.ingredient.ingredientType} (${e.quantity}ml)'),
              subtitle: Text(e.timestamp.toIso8601String()),
            )),
        ...batch.mergeEvents.map((me) => ListTile(
              title: Text('MERGE [${me.type}] from ${me.sourceBatches.map((b) => b.batchId).join(", ")}'),
              subtitle: Text(me.timestamp.toIso8601String()),
            )),
        ...batch.parentBatchs.map((parent) => Padding(
              padding: EdgeInsets.only(left: 16),
              child: BatchNodeWidget(
                batch: parent,
                batchMap: batchMap,
                visited: newVisited,
              ),
            )),
      ],
    );
  }
}