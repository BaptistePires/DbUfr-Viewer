import 'dart:ffi';

import 'package:dbufr_checker/src/CrendentialsArgument.dart';
import 'package:dbufr_checker/src/LangHandlerSingleton.dart';
import 'package:dbufr_checker/src/models/UserSettings.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import '../src/functions.dart';

class LoginPage extends StatefulWidget {
  static String tag = 'login-page';

  @override
  _LoginPageState createState() => new _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  // Flags
  bool _connecting = false;
  bool _doRememberMe = false;
  bool _connectError = false;
  bool _credentialsError = false;
  bool _obscureText = true;
  bool _connected = false;
  bool _firstOpening = true;
  bool _loading = true;

  // Fields controllers
  final studentNoController = TextEditingController();
  final passwordController = TextEditingController();

  // Others
  LangHandlerSingleton langHandler;
  AnimationController _animationcontroller;
  UserSettings userSettings = UserSettings();

  @override
  void initState() {
    setState(() {
      _loading = true;
      _animationcontroller = new AnimationController(
          vsync: this, duration: Duration(milliseconds: 800));
    });
    LangHandlerSingleton.getInstance().then(((o) {
      setState(() {
        this.langHandler = o;
        this._loading = false;
      });
    }));

    loadUserSettings().then((value) {
      if (value != null) {
        setState(() {
          userSettings = value;
        });
      }
    });
  }

  Future<void> nextLang() async {
    await langHandler.nextLang();
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (_firstOpening) checkIfLogged();
    return _loading
        ? Scaffold(body: getLoadingScreen(_animationcontroller, userSettings))
        : Scaffold(
            floatingActionButton: FloatingActionButton(
              child: langHandler.getCurrentFlag(),
              onPressed: () {
                if (!_loading) {
                  setState(() {
                    _loading = true;
                  });

                  Future(langHandler.nextLang).whenComplete(() {
                    setState(() {
                      _loading = false;
                    });
                  });
                }
              },
            ),
            body: Container(
              decoration: BoxDecoration(
                  gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: getGradientFromTmpColors(
                          userSettings.linearBgColors))),
              child: Center(
                child: ListView(
                  shrinkWrap: true,
                  padding: EdgeInsets.only(left: 24, right: 24),
                  children: <Widget>[
                    _setUpLogo(),
                    SizedBox(
                      height: 30,
                    ),
                    Container(
                      padding: EdgeInsets.fromLTRB(20, 30, 20, 0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: Colors.black, width: 1),
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                              color: Colors.lightBlue[900], blurRadius: 10)
                        ],
                      ),
                      child: Column(
                        children: <Widget>[
                          Text(
                            langHandler.getTranslationFor('login_connection'),
                            style: TextStyle(
                                fontFamily: 'Montserrat',
                                fontSize: 25,
                                fontWeight: FontWeight.bold),
                          ),
                          SizedBox(
                            height: 30,
                          ),
                          _setUpForm(),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ));
  }

  void checkIfLogged() async {
    /*
      Method called when the app is opened.
      If user's credentials are already saved, create next route
      and delete this one.
     */
    _firstOpening = false;
    // Check in SharedPreferences
    bool logged = await isLogged();
    if (logged) {
      Map<String, String> credentials = await getCredentials();

      UserArgsBundle args = UserArgsBundle(
          credentials[STUDENT_NO_KEY], credentials[PASSWORD_KEY], userSettings);

      Navigator.of(context).pushNamedAndRemoveUntil(
          '/grades', (Route<dynamic> route) => false,
          arguments: args);
    }
  }

  void login() async {
    /*
      Method used to login.
     */
    // Updating UI
    if (_formKey.currentState.validate()) {
      setState(() {
        _connecting = _connecting ? false : true;
      });
    } else {
      return;
    }
    // Querying DbUfr to get user data
    String studentNo = studentNoController.text;
    String password = passwordController.text;

    try {
      http.Response response = await queryToDbUfr(studentNo, password);
      setState(() {
        resetFlags();
        if (response.statusCode != 200) {
          if (response.statusCode == 401) {
            _credentialsError = true;
          } else {
            _connectError = true;
          }
        } else {
          _connected = true;
        }
      });
      if (_credentialsError) {
        Scaffold.of(context).showSnackBar(setUpSnackBar(
            langHandler.getTranslationFor('login_credentials_error'),
            userSettings));
      }
      if (_credentialsError || _connectError) {
        return;
      }
      // Do we save user credentials
      if (_doRememberMe) {
        await saveCredentials(studentNo, password);
      }

      // Go to next route and delete this one
      UserArgsBundle args = new UserArgsBundle(
          studentNo, password, userSettings,
          htmlGrades: response.body);
      Navigator.pushNamedAndRemoveUntil(
          context, '/grades', (Route<dynamic> route) => false,
          arguments: args);
    } catch (Exception) {
      setState(() {
        resetFlags();
        _connectError = true;
      });
      Scaffold.of(context).showSnackBar(
          setUpSnackBar('Impossible de joindre DbUfr.', userSettings));
    }
  }

  void resetFlags() {
    _connecting = false;
    _connectError = false;
    _credentialsError = false;
    _obscureText = true;
    _connected = false;
  }

  /* ***************************
 * Widgets formating functions *
 *******************************/
  void _showRememberMeDialog() {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Column(
//              padding: EdgeInsets.fromLTRB(5, 5, 5, 5),
//              child: Column(
              children: <Widget>[
                Text(
                  langHandler.getTranslationFor('login_info'),
                  style: TextStyle(
                      fontFamily: userSettings.fontName,
                      fontSize: userSettings.titleFontSize),
                ),
                Divider(
                  color: colorFromDouble(userSettings.primaryColor),
                  thickness: 2,
                ),
              ],
//              )
            ),
            content: Text(
                langHandler.getTranslationFor("login_alert_remember_me"),
                style: TextStyle(
                    fontFamily: userSettings.fontName,
                    fontSize: userSettings.subtitlesFontSize)),
            actions: <Widget>[
              FlatButton(
                child: Text(
                  langHandler.getTranslationFor('login_ok'),
                  style: TextStyle(
                    fontFamily: userSettings.fontName,
                    color: colorFromDouble(userSettings.primaryColor),
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              )
            ],
          );
        });
  }

  Widget _setUpLogo() {
    return Icon(
      FontAwesomeIcons.userGraduate,
      size: 100,
      color: Colors.black,
    );
  }

  Form _setUpForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: <Widget>[
          _setUpStudentNoField(),
          SizedBox(
            height: 20,
          ),
          _setUpPasswordField(),
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
              Text(
                langHandler.getTranslationFor('login_remember_me'),
                style: TextStyle(
                    fontSize: userSettings.subtitlesFontSize,
                    fontFamily: userSettings.fontName),
              ),
              _setUpRememberMe(),
            ],
          ),
          _setUpLoginBtn(),
        ],
      ),
    );
  }

  TextFormField _setUpStudentNoField() {
    return TextFormField(
      keyboardType: TextInputType.number,
      autofocus: false,
      decoration: InputDecoration(
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide(
              color: colorFromDouble(
                userSettings.primaryColor,
              ),
            )),
        hintText: langHandler.getTranslationFor('login_student_no'),
        contentPadding: EdgeInsets.fromLTRB(20, 10, 20, 10),
        labelText: langHandler.getTranslationFor('login_student_no'),
        labelStyle: TextStyle(
            color: colorFromDouble(userSettings.primaryColor),
            fontFamily: userSettings.fontName),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30.0),
          borderSide:
              BorderSide(color: colorFromDouble(userSettings.primaryColor)),
        ),
      ),
      cursorColor: colorFromDouble(userSettings.primaryColor),
      controller: studentNoController,
      enabled: _connecting ? false : true,
      validator: (value) {
        if (value.isEmpty)
          return langHandler.getTranslationFor('login_student_no_missing');
        return null;
      },
      style: TextStyle(fontFamily: userSettings.fontName),
    );
  }

  TextFormField _setUpPasswordField() {
    return TextFormField(
      autofocus: false,
      obscureText: _obscureText,
      decoration: InputDecoration(
        fillColor: colorFromDouble(userSettings.primaryColor),
        hoverColor: colorFromDouble(userSettings.primaryColor),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide(
              color: colorFromDouble(
                userSettings.primaryColor,
              ),
            )),
        hintText: langHandler.getTranslationFor('login_password'),
        labelText: langHandler.getTranslationFor('login_password'),
        labelStyle: TextStyle(
            color: colorFromDouble(userSettings.primaryColor),
            fontFamily: userSettings.fontName),
        contentPadding: EdgeInsets.fromLTRB(20, 10, 20, 10),
        focusColor: colorFromDouble(userSettings.primaryColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30.0),
          borderSide:
              BorderSide(color: colorFromDouble(userSettings.primaryColor)),
        ),
        suffixIcon: IconButton(
          onPressed: () {
            setState(() {
              _obscureText = _obscureText ? false : true;
            });
          },
          icon: Icon(Icons.remove_red_eye),
          color: colorFromDouble(userSettings.primaryColor),
        ),
      ),
      cursorColor: colorFromDouble(userSettings.primaryColor),
      controller: passwordController,
      enabled: _connecting ? false : true,
      validator: (value) {
        if (value.isEmpty)
          return langHandler.getTranslationFor('login_password_missing');
        return null;
      },
      style: TextStyle(fontFamily: userSettings.fontName),
    );
  }

  Checkbox _setUpRememberMe() {
    return Checkbox(
      value: _doRememberMe,
      activeColor: colorFromDouble(userSettings.primaryColor),
      onChanged: (state) {
        setState(() {
          _doRememberMe = state;
        });
      },
    );
  }

  Padding _setUpLoginBtn() {
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: 16,
      ),
      child: OutlineButton(
        color: colorFromDouble(userSettings.primaryColor),
        onPressed: _connecting
            ? null
            : () {
                login();
              },
        child: _connecting
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
                        valueColor: new AlwaysStoppedAnimation<Color>(
                            colorFromDouble(userSettings.primaryColor)),
                      ),
                      widthFactor: 1,
                    ),
                  )
            : Text(
                langHandler.getTranslationFor('login_login'),
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: userSettings.subtitlesFontSize,
                    fontFamily: userSettings.fontName),
              ),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
            side: BorderSide(
              color: colorFromDouble(userSettings.primaryColor),
            )),
        borderSide: BorderSide(
          color: colorFromDouble(userSettings.primaryColor),
        ),
      ),
    );
  }
}
