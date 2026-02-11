import 'package:flutter/material.dart';

class EventDetailScreen extends StatelessWidget {
  final String eventId;

  const EventDetailScreen({super.key, required this.eventId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Details'),
      ),
      body: ListView(
        children: [
          Container(
            height: 300,
            color: Colors.grey[300],
            child: const Center(
              child: Icon(Icons.image, size: 100),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Event Title',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                _buildInfoRow(
                  icon: Icons.calendar_today,
                  label: 'Date & Time',
                  value: 'Date and time will be shown here',
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  icon: Icons.location_on,
                  label: 'Location',
                  value: 'Location will be shown here',
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  icon: Icons.money,
                  label: 'Price',
                  value: 'Price will be shown here',
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {},
                    child: const Text('Book Event'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 12)),
            Text(value),
          ],
        ),
      ],
    );
  }
}
