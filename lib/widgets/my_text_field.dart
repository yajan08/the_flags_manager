import 'package:flutter/material.dart';

class MyTextField extends StatefulWidget {
  final String hintText;
  final bool obscureText;
  final TextEditingController controller;
  final FocusNode? focusNode;
  final TextInputType keyboardType;
  final void Function(String)? onChanged;
  final IconData? prefixIcon; // ✅ Added

  const MyTextField({
    super.key,
    required this.hintText,
    required this.obscureText,
    required this.controller,
    this.focusNode,
    this.keyboardType = TextInputType.text,
    this.onChanged,
    this.prefixIcon, // ✅ Added
  });

  @override
  State<MyTextField> createState() => _MyTextFieldState();
}

class _MyTextFieldState extends State<MyTextField> {
  late bool _isObscured;

  @override
  void initState() {
    super.initState();
    _isObscured = widget.obscureText;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: TextField(
        controller: widget.controller,
        obscureText: _isObscured,
        focusNode: widget.focusNode,
        keyboardType: widget.keyboardType,
        onChanged: widget.onChanged,
        cursorColor: Colors.orange.shade700,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.orange.shade50,

          hintText: widget.hintText,
          hintStyle: TextStyle(
            color: Colors.orange.shade400,
            fontWeight: FontWeight.w400,
          ),

          // ✅ Prefix Icon Support
          prefixIcon: widget.prefixIcon != null
              ? Icon(
                  widget.prefixIcon,
                  color: Colors.orange.shade600,
                )
              : null,

          // Password Visibility Toggle
          suffixIcon: widget.obscureText
              ? IconButton(
                  icon: Icon(
                    _isObscured
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                    color: Colors.orange.shade600,
                  ),
                  onPressed: () {
                    setState(() {
                      _isObscured = !_isObscured;
                    });
                  },
                )
              : null,

          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 18),

          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),

          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(
              color: Colors.orange.shade200,
              width: 1.5,
            ),
          ),

          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(
              color: Colors.orange.shade700,
              width: 2,
            ),
          ),
        ),
      ),
    );
  }
}
