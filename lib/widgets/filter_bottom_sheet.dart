import 'package:flutter/material.dart';

class FilterBottomSheet extends StatefulWidget {
  final Function(Map<String, dynamic>) onApplyFilters;

  const FilterBottomSheet({
    super.key,
    required this.onApplyFilters,
  });

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  String? _selectedCategory;
  RangeValues _priceRange = const RangeValues(0, 1000);
  String? _selectedSortBy;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filter Events',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 20),
          // Category Filter
          Text('Category', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          DropdownButton<String>(
            isExpanded: true,
            value: _selectedCategory,
            hint: const Text('Select a category'),
            items: ['Music', 'Sports', 'Technology', 'Art', 'Food']
                .map((category) {
              return DropdownMenuItem<String>(
                value: category,
                child: Text(category),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedCategory = value;
              });
            },
          ),
          const SizedBox(height: 20),
          // Price Range Filter
          Text('Price Range', style: Theme.of(context).textTheme.titleMedium),
          RangeSlider(
            values: _priceRange,
            max: 1000,
            divisions: 100,
            labels: RangeLabels(
              '\$${_priceRange.start.toStringAsFixed(0)}',
              '\$${_priceRange.end.toStringAsFixed(0)}',
            ),
            onChanged: (values) {
              setState(() {
                _priceRange = values;
              });
            },
          ),
          const SizedBox(height: 20),
          // Sort By
          Text('Sort By', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          DropdownButton<String>(
            isExpanded: true,
            value: _selectedSortBy,
            hint: const Text('Select sorting'),
            items: ['Date: Earliest', 'Date: Latest', 'Price: Low to High', 'Price: High to Low']
                .map((sort) {
              return DropdownMenuItem<String>(
                value: sort,
                child: Text(sort),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedSortBy = value;
              });
            },
          ),
          const SizedBox(height: 24),
          // Apply Button
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.close),
                  label: const Text('Reset'),
                  onPressed: () {
                    setState(() {
                      _selectedCategory = null;
                      _priceRange = const RangeValues(0, 1000);
                      _selectedSortBy = null;
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.check),
                  label: const Text('Apply'),
                  onPressed: () {
                    widget.onApplyFilters({
                      'category': _selectedCategory,
                      'priceMin': _priceRange.start,
                      'priceMax': _priceRange.end,
                      'sortBy': _selectedSortBy,
                    });
                    Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
