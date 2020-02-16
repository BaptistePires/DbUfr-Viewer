import 'package:dbufr_checker/pages/home_page.dart';
import 'package:dbufr_checker/pages/settings_page.dart';
import 'package:dbufr_checker/src/functions.dart';
import 'package:dbufr_checker/src/models/UserSettings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'pages/login_page.dart';
import 'pages/grades_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  loadUserSettings().then((value) {
    runApp(MyApp(value));
  });
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  UserSettings us;

  MyApp(this.us);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Db ufr checker',
      theme: ThemeData(
//        primarySwatch: Colors.blue,
          ),
      initialRoute: '/',
      routes: {
        '/': (context) => Scaffold(body: HomePage(us)),
        '/login': (context) => Scaffold(body: LoginPage()),
        '/grades': (context) => Scaffold(body: GradesPage()),
        '/settings': (context) => Scaffold(body: SettingsPage())
      },
    );
  }
}
