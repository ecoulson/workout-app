import 'package:app/src/pages/machine_creation_page.dart';
import 'package:app/src/pages/repitition_counter_page.dart';
import 'package:app/src/pages/scan_tag_page.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

void main() {
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
        routerConfig: GoRouter(routes: [
      GoRoute(
          path: '/',
          builder: ((context, state) => const ScanTagPage()),
          routes: [
            GoRoute(
              path: 'create',
              builder: (context, state) => const MachineCreationPage(),
            ),
            GoRoute(
                path: 'repititions',
                builder: (context, state) => RepititionCounterPage(
                    machineId: state.queryParams["machineId"] ?? "0"))
          ])
    ]));
  }
}
