import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Dropdown de fecha: Month | Day | Year.
/// Diseño: xzvWp — 3 dropdowns con borde, radius 28, caret-down icon.
class DateSelector extends StatefulWidget {
  const DateSelector({
    super.key,
    required this.onChanged,
  });

  final ValueChanged<DateTime?> onChanged;

  @override
  State<DateSelector> createState() => _DateSelectorState();
}

class _DateSelectorState extends State<DateSelector> {
  int? _selectedMonth;
  int? _selectedDay;
  int? _selectedYear;

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  int get _maxDay {
    if (_selectedMonth == null || _selectedYear == null) return 31;
    return DateTime(_selectedYear!, _selectedMonth! + 1, 0).day;
  }

  int get _minYear => 1920;
  int get _maxYear => DateTime.now().year - AppConstants.minAge;

  void _emitDate() {
    if (_selectedMonth != null &&
        _selectedDay != null &&
        _selectedYear != null) {
      widget.onChanged(
        DateTime(_selectedYear!, _selectedMonth!, _selectedDay!),
      );
    } else {
      widget.onChanged(null);
    }
  }

  Widget _buildDropdown<T>({
    required String hint,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
    required double width,
  }) {
    return Container(
      width: width,
      height: 56,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.inputBorder),
        borderRadius: AppRadius.chipRadius,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          hint: Text(hint, style: AppTextStyles.inputHint),
          icon: const Icon(
            PhosphorIconsRegular.caretDown,
            color: AppColors.placeholder,
            size: 16,
          ),
          isExpanded: true,
          style: AppTextStyles.inputText,
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Month
        Expanded(
          flex: 3,
          child: _buildDropdown<int>(
            hint: 'Month',
            value: _selectedMonth,
            width: double.infinity,
            items: List.generate(12, (i) {
              return DropdownMenuItem(
                value: i + 1,
                child: Text(_months[i]),
              );
            }),
            onChanged: (v) {
              setState(() {
                _selectedMonth = v;
                // Adjustar día si excede max
                if (_selectedDay != null && _selectedDay! > _maxDay) {
                  _selectedDay = _maxDay;
                }
              });
              _emitDate();
            },
          ),
        ),
        const SizedBox(width: 12),

        // Day
        Expanded(
          flex: 2,
          child: _buildDropdown<int>(
            hint: 'Day',
            value: _selectedDay,
            width: double.infinity,
            items: List.generate(_maxDay, (i) {
              return DropdownMenuItem(
                value: i + 1,
                child: Text('${i + 1}'),
              );
            }),
            onChanged: (v) {
              setState(() => _selectedDay = v);
              _emitDate();
            },
          ),
        ),
        const SizedBox(width: 12),

        // Year
        Expanded(
          flex: 3,
          child: _buildDropdown<int>(
            hint: 'Year',
            value: _selectedYear,
            width: double.infinity,
            items: List.generate(_maxYear - _minYear + 1, (i) {
              final year = _maxYear - i;
              return DropdownMenuItem(
                value: year,
                child: Text('$year'),
              );
            }),
            onChanged: (v) {
              setState(() {
                _selectedYear = v;
                if (_selectedDay != null && _selectedDay! > _maxDay) {
                  _selectedDay = _maxDay;
                }
              });
              _emitDate();
            },
          ),
        ),
      ],
    );
  }
}
