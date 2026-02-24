import 'package:flutter/material.dart';

class RegistrationBackground extends StatelessWidget {
  const RegistrationBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: MediaQuery.of(context).size.height,
      child: Image.asset(
        'assets/images/pattern2.png',
        fit: BoxFit.cover,
        alignment: Alignment.topCenter,
      ),
    );
  }
}
