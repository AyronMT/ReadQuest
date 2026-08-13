import 'package:flutter/material.dart';
import 'package:projeto_pratico/gradient_container.dart';

void main() {
  runApp(
    const MaterialApp(
      home: Scaffold(
        body: GradientContainer(Colors.black, Colors.white)
      )
    )
  );
}

