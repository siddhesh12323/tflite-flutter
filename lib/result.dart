import 'dart:io';

import 'package:flutter/material.dart';

class ResultScreen extends StatelessWidget {
  final File image;
  final String result;
  final dynamic probability;
  const ResultScreen(
      {super.key,
      required this.image,
      required this.result,
      required this.probability});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 100, 101, 97),
      appBar: AppBar(
        title: const Text('Result'),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(8),
          child: Column(
            children: [
              Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                    border: Border.all(width: 2),
                    borderRadius: BorderRadius.circular(12)),
                child: Image.file(image, fit: BoxFit.cover),
              ),
              const SizedBox(height: 30),
              Text(
                'Result: $result',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              Text(
                'Probability: ${(probability * 100).toStringAsFixed(2)}%',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
