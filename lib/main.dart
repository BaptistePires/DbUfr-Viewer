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
        '/login': (context) => Scaffold(body: LoginPage(),),
        '/grades': (context) => Scaffold(body: GradesPage()),
      },
    );
  }
}
//
//class LoginPage extends StatefulWidget {
//  LoginPage({Key key, this.title}) : super(key: key);
//  final String title;
//
//  @override
//  _LoginPageState createState() => _LoginPageState();
//}
//
//class _LoginPageState extends State<LoginPage> {
//  final style = TextStyle(fontFamily: 'Montserrat', fontSize: 22.0);
//  final studentNoFieldController = TextEditingController();
//  final passwordController = TextEditingController();
//
//  final _formKey = GlobalKey<FormState>();
//
//  @override
//  Widget build(BuildContext context) {
//    return Scaffold(
//    );
//  }
//
//}
