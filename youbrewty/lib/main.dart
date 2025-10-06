import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/batch_list_screen.dart';
import 'screens/community_screen.dart';
import 'screens/settings_screen.dart';

import 'screens/batch_lineage_screen.dart';
import 'utils/test_data.dart';

//void main() => runApp(const YouBrewtyApp());

void main() {
  final batches = generateBatchesForUi();
  //final batchMap = { for (var b in batches) b.batchId : b };
  //final rootBatch = batches.first;

  final batchMap = { for (var b in batches) b.batchId : b };

    // Find terminal batches with a merge in their ancestry
    final terminalBatches = findTerminalBatches(batches);
    final mergedTerminalBatches = terminalBatches.where((b) => hasMergeInAncestry(b, batchMap)).toList();

    if (mergedTerminalBatches.isEmpty) {
      throw Exception('No terminal batches found that are also merge nodes or have merges in their ancestry!');
    }
    final finalBatch = mergedTerminalBatches[random.nextInt(mergedTerminalBatches.length)];


  runApp(MaterialApp(
    home: BatchLineageScreen(rootBatch: finalBatch, batchMap: batchMap),
  ));
}



class YouBrewtyApp extends StatelessWidget {
  const YouBrewtyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'YouBrewty',
      theme: ThemeData(primarySwatch: Colors.brown),
      home: const MainNavigation(),
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({Key? key}) : super(key: key);

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  static final List<Widget> _screens = [
    HomeScreen(),
    BatchListScreen(),
    CommunityScreen(),
    SettingsScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.brown[800],
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.local_drink), label: 'Batches'),
          BottomNavigationBarItem(icon: Icon(Icons.group), label: 'Community'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}