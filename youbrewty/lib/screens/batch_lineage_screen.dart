import 'package:flutter/material.dart';
import '../models/models.dart';
import '../widgets/batch_node_widget.dart';

class BatchLineageScreen extends StatelessWidget {
  final Batch rootBatch;
  final Map<String, Batch> batchMap;

  BatchLineageScreen({required this.rootBatch, required this.batchMap});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Batch Lineage')),
      body: ListView(
        children: [
          BatchNodeWidget(batch: rootBatch, batchMap: batchMap),
        ],
      ),
    );
  }
}