import 'package:flutter/material.dart';
import 'package:sliding_pill_bottom_nav/sliding_pill_bottom_nav.dart';

void main() => runApp(const ExampleApp());

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        useMaterial3: true,
        extensions: [
          SlidingPillNavBarTheme.light,
          SlidingPillNavBarMotion.regular,
        ],
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        extensions: [
          SlidingPillNavBarTheme.dark,
          SlidingPillNavBarMotion.regular,
        ],
      ),
      home: const ExampleShell(),
    );
  }
}

class ExampleShell extends StatefulWidget {
  const ExampleShell({super.key});

  @override
  State<ExampleShell> createState() => _ExampleShellState();
}

class _ExampleShellState extends State<ExampleShell> {
  var _index = 0;

  static const _items = [
    SlidingPillNavBarItem(
      icon: Icons.home_rounded,
      label: 'Home',
      semanticLabel: 'Home tab',
    ),
    SlidingPillNavBarItem(
      icon: Icons.search_rounded,
      label: 'Search',
      semanticLabel: 'Search tab',
    ),
    SlidingPillNavBarItem(
      icon: Icons.notifications_rounded,
      label: 'Alerts',
      semanticLabel: 'Alerts tab',
    ),
    SlidingPillNavBarItem(
      icon: Icons.person_rounded,
      label: 'Profile',
      semanticLabel: 'Profile tab',
    ),
  ];

  void _onAction() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Centre action pressed')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      appBar: AppBar(title: const Text('Sliding pill bottom nav')),
      body: Center(child: Text('Tab $_index')),
      bottomNavigationBar: SlidingPillBottomNavBar(
        items: _items,
        selectedIndex: _index,
        onSelected: (i) => setState(() => _index = i),
        // Needs an even number of items: two either side of the button.
        centerAction: SlidingPillNavBarCenterAction(
          icon: Icons.add_rounded,
          semanticLabel: 'Create',
          tooltip: 'Create',
          foregroundColor: Colors.white,
          onPressed: _onAction,
        ),
      ),
    );
  }
}
