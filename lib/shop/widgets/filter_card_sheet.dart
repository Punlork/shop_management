// New FilterSheet widget
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:my_app/shop/shop.dart';

class FilterSheet extends StatefulWidget {
  const FilterSheet({
    required this.initialCategoryFilter,
    required this.onApply,
    super.key,
  });
  final CategoryItemModel? initialCategoryFilter;
  final void Function(CategoryItemModel? category) onApply;

  @override
  State<FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<FilterSheet> {
  late CategoryItemModel? _categoryFilter;

  bool get isDisabled => _categoryFilter == null;

  @override
  void initState() {
    super.initState();
    _categoryFilter = widget.initialCategoryFilter;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filter Items',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          CategoryDropdown(
            initialValue: _categoryFilter,
            onChanged: (value) {
              _categoryFilter = value;
              setState(() {});
            },
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {
                  widget.onApply.call(null);
                  context.pop();
                },
                child: const Text(
                  'Reset',
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: isDisabled
                    ? null
                    : () {
                        widget.onApply(_categoryFilter);
                        context.pop();
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDisabled ? colorScheme.onSurface.withValues(alpha: .38) : colorScheme.primary,
                  foregroundColor: isDisabled ? colorScheme.onSurface.withValues(alpha: .38) : colorScheme.onPrimary,
                ),
                child: const Text('Apply'),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
