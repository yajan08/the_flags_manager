import 'package:flutter/material.dart';

class MyTextField extends StatefulWidget {
  final String hintText;
  final bool obscureText;
  final TextEditingController controller;
  final FocusNode? focusNode;
  final TextInputType keyboardType;
  final void Function(String)? onChanged;
  final IconData? prefixIcon;

  const MyTextField({
    super.key,
    required this.hintText,
    required this.obscureText,
    required this.controller,
    this.focusNode,
    this.keyboardType = TextInputType.text,
    this.onChanged,
    this.prefixIcon,
  });

  @override
  State<MyTextField> createState() => _MyTextFieldState();
}

class _MyTextFieldState extends State<MyTextField> {
  late bool _isObscured;
  bool _isFocused = false;
  late FocusNode _internalFocusNode;

  @override
  void initState() {
    super.initState();
    _isObscured = widget.obscureText;
    _internalFocusNode = widget.focusNode ?? FocusNode();
    _internalFocusNode.addListener(() {
      setState(() {
        _isFocused = _internalFocusNode.hasFocus;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    const Color brandOrange = Color(0xFFFF6F00);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: _isFocused ? Colors.white : Colors.orange.shade50.withAlpha(128),
        borderRadius: BorderRadius.circular(18),
        boxShadow: _isFocused 
          ? [BoxShadow(color: brandOrange.withAlpha(26), blurRadius: 10, offset: const Offset(0, 4))] 
          : [],
      ),
      child: TextField(
        controller: widget.controller,
        obscureText: _isObscured,
        focusNode: _internalFocusNode,
        keyboardType: widget.keyboardType,
        onChanged: widget.onChanged,
        cursorColor: brandOrange,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
        decoration: InputDecoration(
          hintText: widget.hintText,
          hintStyle: TextStyle(
            color: Colors.orange.shade300,
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: widget.prefixIcon != null
              ? Icon(
                  widget.prefixIcon,
                  color: _isFocused ? brandOrange : Colors.orange.shade300,
                  size: 22,
                )
              : null,
          suffixIcon: widget.obscureText
              ? IconButton(
                  icon: Icon(
                    _isObscured
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                    color: _isFocused ? brandOrange : Colors.orange.shade300,
                  ),
                  onPressed: () => setState(() => _isObscured = !_isObscured),
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(
              color: Colors.orange.shade100,
              width: 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(
              color: brandOrange,
              width: 2,
            ),
          ),
        ),
      ),
    );
  }
}