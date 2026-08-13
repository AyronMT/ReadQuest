import 'package:flutter/material.dart';

class StyledText extends StatelessWidget {
  const StyledText(this.text, {super.key});

  final String text;
  
  @override
  Widget build(context) {
    return Text(
      text,
      style: TextStyle(color: Color.fromARGB(12, 56, 166, 200), fontSize: 12),
    );
  }
}
