import 'package:flutter/material.dart';
import 'package:event_finder/utils/app_theme.dart';

class EventCard extends StatelessWidget {
  final String title;
  final String location;
  final String date;
  final String price;
  final String? imageUrl;
  final VoidCallback onTap;

  const EventCard({
    super.key,
    required this.title,
    required this.location,
    required this.date,
    required this.price,
    this.imageUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Event Image
            Container(
              height: 200,
              width: double.infinity,
              color: Colors.grey[300],
              child: imageUrl != null
                  ? Image.network(imageUrl!, fit: BoxFit.cover)
                  : const Center(
                      child: Icon(Icons.image, size: 80),
                    ),
            ),
            // Event Info
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 16),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          location,
                          style: Theme.of(context).textTheme.bodySmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            date,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                      Text(
                        price,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
