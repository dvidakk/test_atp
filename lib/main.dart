import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/services/auth_service.dart';
import 'auth/screens/login_screen.dart';
import 'feed/screens/feed_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final authService = AuthService();
  await authService.initializeFromStorage();

  runApp(
    ChangeNotifierProvider<AuthService>.value(
      value: authService,
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return MaterialApp(
      title: 'Cumulus',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: authService.isAuthenticated ? FeedScreen() : LoginScreen(),
    );
  }
}
