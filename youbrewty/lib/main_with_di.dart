// SPDX-License-Identifier: MIT
// Example app wiring: initialize GetIt in main(), then expose FormStoreService via Provider.
// Demonstrates how to access the service from widgets either via Provider or GetIt.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'di/service_locator.dart';
import 'services/form_store_service.dart';
import 'screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize and register persistence service (Sembast-based by default).
  await setupServiceLocator();

  // Run the app. The GetIt instance holds the service; we also create a ChangeNotifierProvider
  // so widgets can listen for updates using Provider APIs.
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({Key? key}) : super(key: key);

  // Obtain the registered service synchronously from GetIt (it was registered in setup).
  final FormStoreService _formStoreService = getIt<FormStoreService>();

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<FormStoreService>.value(
      value: _formStoreService,
      child: MaterialApp(
        title: 'YouBrewty (DI Demo)',
        theme: ThemeData(primarySwatch: Colors.brown),
        home: const HomeScreen(),
      ),
    );
  }
}