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
      title: 'Flutter Demo',
      theme: ThemeData(
        fontFamily: 'Montserrat',
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => Scaffold(
              body: LoginPage(),
            ),
        '/grades': (context) => Scaffold(body: GradesPage()),
      },
    );
  }
}
