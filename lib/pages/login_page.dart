import 'dart:convert';

import 'package:dbufr_checker/src/CrendentialsArgument.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../src/functions.dart';

class LoginPage extends StatefulWidget {
  static String tag = 'login-page';

  @override
  _LoginPageState createState() => new _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  bool connecting = false;
  bool doRememberMe = false;
  bool connectError = false;
  bool _obscureText = true;
  bool _connected = false;
  bool _firstOpening = true;
  final studentNoController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    if(_firstOpening) checkIfLogged();
    final logo = Hero(
      tag: 'upmc',
      child: CircleAvatar(
        backgroundColor: Colors.transparent,
        radius: 48.0,
        child: Image.asset('assets/imgs/logo.png'),
      ),
    );

    final studentNoInput = TextFormField(
      keyboardType: TextInputType.number,
      autofocus: false,
      decoration: InputDecoration(
        hintText: 'N° étudiant',
        contentPadding: EdgeInsets.fromLTRB(20, 10, 20, 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(32.0),
          borderSide: BorderSide(color: Colors.blue),
        ),
      ),
      controller: studentNoController,
      enabled: connecting ? false : true,
      validator: (value) {
        if (value.isEmpty) return 'Indiquez votre numéro d\'étudiant';
        return null;
      },
    );

    final passwordInput = TextFormField(
      autofocus: false,
      obscureText: _obscureText,
      decoration: InputDecoration(
        hintText: 'Mot de passe',
        contentPadding: EdgeInsets.fromLTRB(20, 10, 20, 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(32.0),
          borderSide: BorderSide(color: Colors.blue),
        ),
        suffixIcon: IconButton(
          onPressed: () {
            setState(() {
              _obscureText = _obscureText ? false : true;
            });
          },
          icon: Icon(Icons.remove_red_eye),
        ),
      ),
      controller: passwordController,
      enabled: connecting ? false : true,
      validator: (value) {
        if (value.isEmpty) return 'Indiquez votre mot de passe';
        return null;
      },
    );

    final rememberMe = Checkbox(
      value: doRememberMe,
      onChanged: (state) {
        setState(() {
          doRememberMe = state;
        });
      },
    );

    final loginBtn = Padding(
      padding: EdgeInsets.symmetric(
        vertical: 16,
      ),
      child: OutlineButton(
        onPressed: connecting
            ? null
            : () {
                login();
              },
        child: connecting
            ? _connected
                ? Container(
                    margin: EdgeInsets.all(5),
                    child: Center(
                      child: Icon(Icons.done),
                      widthFactor: 1,
                    ),
                  )
                : Container(
                    margin: EdgeInsets.all(5),
                    child: Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                      widthFactor: 1,
                    ),
                  )
            : Text('Se connecter'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        borderSide: BorderSide(color: Colors.blue),
      ),
    );
    return new Scaffold(
        body: Container(
      decoration: BoxDecoration(
          gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
            Colors.lightBlue[400],
            Colors.lightBlue,
            Colors.lightBlue[600],
            Colors.lightBlue[700],
            Colors.lightBlue[800],
          ])),
      child: Center(
        child: ListView(
          shrinkWrap: true,
          padding: EdgeInsets.only(left: 24, right: 24),
          children: <Widget>[
            logo,
            SizedBox(
              height: 120,
            ),
            Container(
              padding: EdgeInsets.fromLTRB(20, 30, 20, 20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.black, width: 1),
                color: Colors.white,
                boxShadow: [
                  BoxShadow(color: Colors.lightBlue[900], blurRadius: 10)
                ],
              ),
              child: Column(
                children: <Widget>[
                  Text(
                    'Connexion',
                    style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 25,
                        fontWeight: FontWeight.bold),
                  ),
                  SizedBox(
                    height: 30,
                  ),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: <Widget>[
                        studentNoInput,
                        SizedBox(
                          height: 20,
                        ),
                        passwordInput,
                        SizedBox(
                          height: 5,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: <Widget>[
                            IconButton(
                              icon: Icon(Icons.info),
                              onPressed: () {
                                _showRememberMeDialog();
                              },
                              iconSize: 19,

                            ),
                            Text('Rester connecté'),
                            rememberMe,
                          ],
                        ),
                        SizedBox(
                          height: 20,
                        ),
                        loginBtn,
                        Text(
                          'Numéro étudiant ou mot de passe incorect',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: connectError ? Colors.red : Colors.white,
                          ),
                        )
                      ],
                    ),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    ));
  }

  void checkIfLogged() async {
    _firstOpening = false;
    bool logged = await isLogged();
    if (logged) {
      Map<String, String> credentials = await getCredentials();
      CredentialsArgument args = CredentialsArgument(
          credentials[STUDENT_NO_KEY], credentials[PASSWORD_KEY]);
      Navigator.of(context).pushNamedAndRemoveUntil(
           '/grades', (Route<dynamic> route) => false,
          arguments: args);
    }
  }

  void login() async {
    if (_formKey.currentState.validate()) {
      setState(() {
        connecting = connecting ? false : true;
      });
    } else {
      return;
    }
    String studentNo = studentNoController.text;
    String password = passwordController.text;
    String basicAuth =
        'Basic ' + base64Encode(utf8.encode('$studentNo:$password'));
    String url =
        'https://www-dbufr.ufr-info-p6.jussieu.fr/lmd/2004/master/auths/seeStudentMarks.php';
    http.Response response =
    await http.get(url, headers: {'authorization': basicAuth});
    if (response.statusCode != 200) {
      setState(() {
        connecting = false;
        connectError = true;
      });
    } else {
      setState(() {
//        _connected = true;
        connecting = false;
//        connectError = true;
      });
      SharedPreferences sp = await SharedPreferences.getInstance();

      if (doRememberMe) {
        saveCredentials(studentNo, password);
      }
      CredentialsArgument args = new CredentialsArgument(studentNo, password, htmlGrades: response.body);
      Navigator.pushNamedAndRemoveUntil(
          context, '/grades', (Route<dynamic> route) => false, arguments: args);
    }
  }

  void _showRememberMeDialog() {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Informations'),
            content: Text(
                'La fonction \'Rester connecté\' peut présenter des risques si vous perdez votre téléphone.'),
            actions: <Widget>[
              FlatButton(
                child: Text('D\'accord'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              )
            ],
          );
        });
  }
}
