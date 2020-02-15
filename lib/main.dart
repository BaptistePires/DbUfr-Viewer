import 'package:dbufr_checker/pages/home_page.dart';
import 'package:dbufr_checker/pages/settings_page.dart';
import 'package:flutter/material.dart';
import 'pages/login_page.dart';
import 'pages/grades_page.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Db ufr checker',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => Scaffold(body: HomePage()),
        '/login': (context) => Scaffold(
              body: LoginPage(),
            ),
        '/grades': (context) => Scaffold(body: GradesPage()),
        '/settings': (context) => Scaffold(
              body: SettingsPage(),
            )
      },
    );
  }
}
