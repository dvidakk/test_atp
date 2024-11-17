import 'package:flutter/material.dart';
import 'package:test_atp/auth/screens/login_screen.dart';
import 'package:test_atp/core/constants/colors.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cumulus',
      theme: ThemeData(
        primaryColor: AppColors.blue,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 1,
          iconTheme: IconThemeData(color: AppColors.blue),
          titleTextStyle: TextStyle(
            color: AppColors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      home: const LoginScreen(),
    );
  }
}
