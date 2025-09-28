import 'package:flutter/material.dart';

class IntroComponent extends StatelessWidget {
  final String title;
  final String description;
  final String imagePath;

  const IntroComponent({
    super.key,
    required this.title,
    required this.description,
    required this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        
        Image.asset(
          imagePath,
          height: screenHeight * 0.4,
          width: screenWidth * 0.7,
          fit: BoxFit.contain,
        ),
        SizedBox(height: screenHeight * 0.03),
        
        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: screenHeight * 0.03,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: screenHeight * 0.015),
        
        Padding(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.1),
          child: Text(
            description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: screenHeight * 0.02,
              color: Colors.grey[700],
            ),
          ),
        ),
      ],
    );
  }
}
