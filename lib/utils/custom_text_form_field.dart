import 'package:flutter/material.dart';

class CustomTextFormField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final String validatorMessage;

  const CustomTextFormField({
    super.key,
    required this.controller,
    required this.labelText,
    required this.validatorMessage,
  });

  String? _defaultValidator(String? value) {
    if (value == null || value.isEmpty) {
      return validatorMessage;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: labelText),
      validator: _defaultValidator,
    );
  }
}
