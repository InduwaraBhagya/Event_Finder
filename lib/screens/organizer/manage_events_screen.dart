import 'package:flutter/material.dart';

class ManageEventsScreen extends StatefulWidget {
  const ManageEventsScreen({super.key});

  @override
  State<ManageEventsScreen> createState() => _ManageEventsScreenState();
}

class _ManageEventsScreenState extends State<ManageEventsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Events'),
      ),
      body: ListView(
        children: const [
          Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(
              child: Text('Your events will appear here'),
            ),
          ),
        ],
      ),
    );
  }
}
