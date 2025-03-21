import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_app/customer/customer.dart';

class LoanerFilterSheet extends StatefulWidget {
  const LoanerFilterSheet({
    required this.onApply,
    this.initialFromDate,
    this.initialToDate,
    this.initialLoanerFilter,
    super.key,
  });

  final DateTime? initialFromDate;
  final DateTime? initialToDate;
  final CustomerModel? initialLoanerFilter;
  final void Function(DateTime? fromDate, DateTime? toDate, CustomerModel? loanerFilter) onApply;

  @override
  State<LoanerFilterSheet> createState() => _LoanerFilterSheetState();
}

class _LoanerFilterSheetState extends State<LoanerFilterSheet> {
  late DateTime? _fromDate = widget.initialFromDate;
  late DateTime? _toDate = widget.initialToDate;
  late CustomerModel? _loanerFilter;

  bool get isDisabled => _fromDate == null && _toDate == null && _loanerFilter == null;

  @override
  void initState() {
    super.initState();
    _loanerFilter = widget.initialLoanerFilter;
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isFromDate) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: (isFromDate ? _fromDate : _toDate) ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        if (isFromDate) {
          _fromDate = picked;
        } else {
          _toDate = picked;
        }
      });
    }
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
            'Filter Loaners',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextFormField(
            readOnly: true,
            onTap: () => _selectDate(context, true),
            decoration: InputDecoration(
              labelText: 'From Date',
              hintText: _fromDate == null ? 'Not Set' : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              suffixIcon: const Icon(Icons.calendar_today, size: 20),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            ),
            controller: TextEditingController(
              text: _fromDate?.toString().split(' ')[0] ?? 'Not Set',
            )..addListener(() {}),
          ),
          const SizedBox(height: 16),
          TextFormField(
            readOnly: true,
            onTap: () => _selectDate(context, false),
            decoration: InputDecoration(
              labelText: 'To Date',
              hintText: _toDate == null ? 'Not Set' : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              suffixIcon: const Icon(Icons.calendar_today, size: 20),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            ),
            controller: TextEditingController(
              text: _toDate?.toString().split(' ')[0] ?? 'Not Set',
            )..addListener(() {}),
          ),
          const SizedBox(height: 16),
          BlocBuilder<CustomerBloc, CustomerState>(
            builder: (context, state) {
              if (state is CustomerLoaded) {
                return DropdownButtonFormField<CustomerModel>(
                  value: _loanerFilter,
                  decoration: InputDecoration(
                    labelText: 'Loaner',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  items: state.customers.map(
                    (option) {
                      return DropdownMenuItem<CustomerModel>(
                        value: option,
                        child: Text(option.name),
                      );
                    },
                  ).toList(),
                  onChanged: (value) {
                    setState(() {
                      _loanerFilter = value;
                    });
                  },
                  hint: const Text('Select Loaner'),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {
                  widget.onApply(null, null, null); // Reset all filters
                  Navigator.pop(context);
                },
                child: const Text('Reset'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: isDisabled
                    ? null
                    : () {
                        widget.onApply(_fromDate, _toDate, _loanerFilter);
                        Navigator.pop(context);
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDisabled ? colorScheme.onSurface.withValues(alpha: .38) : colorScheme.primary,
                  foregroundColor: isDisabled ? colorScheme.onSurface.withValues(alpha: .38) : colorScheme.onPrimary,
                ),
                child: const Text('Apply'),
              ),
            ],
          ),
          const SizedBox(height: 16), // Matches FilterSheet bottom padding
        ],
      ),
    );
  }
}
