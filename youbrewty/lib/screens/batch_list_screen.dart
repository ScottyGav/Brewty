import 'package:flutter/material.dart';
import '../models.dart';

class BatchListScreen extends StatelessWidget {
  const BatchListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Temporary mock data
    final batches = [
      Batch(batchId: 'B001', name: 'Pineapple Pandemic', capacity: 20.0),
      Batch(batchId: 'B002', name: 'Berry Blast', capacity: 15.0),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Your Batches')),
      body: ListView.builder(
        itemCount: batches.length,
        itemBuilder: (context, index) {
          final batch = batches[index];
          return ListTile(
            leading: const Icon(Icons.local_drink),
            title: Text(batch.name),
            subtitle: Text('Capacity: ${batch.capacity}L'),
            onTap: () {
              // Later: Navigate to batch detail
            },
          );
        },
      ),
    );
  }
}