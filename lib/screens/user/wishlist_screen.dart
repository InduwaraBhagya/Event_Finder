import 'package:flutter/material.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wishlist'),
      ),
      body: ListView(
        children: const [
          Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(
              child: Text('Your wishlist is empty'),
            ),
          ),
        ],
      ),
    );
  }
}
