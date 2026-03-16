import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  final String? labelText;
  final String? hintText;
  final bool obscureText;
  final String? Function(String?)? validator;
  final TextEditingController? controller;
  final TextInputType keyboardType;
  final int maxLines;
  final Widget? prefixIcon;

  const CustomTextField({
    super.key,
    this.labelText,
    this.hintText,
    this.obscureText = false,
    this.validator,
    this.controller,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
    this.prefixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      validator: validator,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        prefixIcon: prefixIcon,
      ),
    );
  }
}
