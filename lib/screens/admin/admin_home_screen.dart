import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:event_finder/providers/auth_provider.dart';
import 'package:event_finder/utils/app_theme.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              await authProvider.logout();
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Admin Control Panel',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Manage users, events, and system',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Stats Cards
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildStatCard(
                context,
                title: 'Total Users',
                value: '0',
                icon: Icons.people,
              ),
              _buildStatCard(
                context,
                title: 'Total Events',
                value: '0',
                icon: Icons.event,
              ),
              _buildStatCard(
                context,
                title: 'Total Bookings',
                value: '0',
                icon: Icons.bookmark,
              ),
              _buildStatCard(
                context,
                title: 'Revenue',
                value: '\$0',
                icon: Icons.attach_money,
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Admin Actions
          _buildActionButton(
            context,
            label: 'Manage Users',
            icon: Icons.people,
            onTap: () {},
          ),
          const SizedBox(height: 12),
          _buildActionButton(
            context,
            label: 'Review Events',
            icon: Icons.event,
            onTap: () {},
          ),
          const SizedBox(height: 12),
          _buildActionButton(
            context,
            label: 'View Reports',
            icon: Icons.assessment,
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: AppTheme.primaryColor),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 4),
            Text(title, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: Icon(icon),
        label: Text(label),
        onPressed: onTap,
      ),
    );
  }
}
