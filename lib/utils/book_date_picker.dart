import 'package:flutter/material.dart';
import 'package:flutter_cupertino_datetime_picker/flutter_cupertino_datetime_picker.dart';

class BookDatePicker extends StatefulWidget {
  final Function(DateTime) onDateSelected;

  const BookDatePicker({super.key, required this.onDateSelected});

  @override
  State<BookDatePicker> createState() => _BookDatePickerState();
}

class _BookDatePickerState extends State<BookDatePicker> {
  DateTime? selectedDate;
  void _showDatePicker() {
    DatePicker.showDatePicker(
      context,
      pickerMode: DateTimePickerMode.date,
      minDateTime: DateTime(2000, 1, 1),
      maxDateTime: DateTime(2100, 12, 31),
      initialDateTime: selectedDate ?? DateTime.now(),
      dateFormat: 'yyyy-MM-dd',
      onConfirm: (DateTime dateTime, List<int> index) {
        final fixedDate = DateTime(
          dateTime.year,
          dateTime.month,
          /* dateTime.day != null && */ dateTime.day > 0 ? dateTime.day : 1,
        );
        setState(() {
          selectedDate = fixedDate;
        });

        widget.onDateSelected(fixedDate);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextButton.icon(
            onPressed: _showDatePicker,
            icon: const Icon(Icons.date_range),
            label: const Text("Tarih Seç")),
        if (selectedDate != null)
          Text(
              "Seçilen Tarih: ${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')}"),
      ],
    );
  }
}
