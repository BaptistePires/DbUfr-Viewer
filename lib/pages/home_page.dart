import 'package:dbufr_checker/src/CrendentialsArgument.dart';
import 'package:dbufr_checker/src/LangHandlerSingleton.dart';
import 'package:dbufr_checker/src/functions.dart';
import 'package:dbufr_checker/src/models/UserSettings.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {

  UserSettings us;

  HomePage(this.us);

  @override
  _HomePageState createState() => _HomePageState(us);
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  LangHandlerSingleton langHandler;
  AnimationController _controller;
  UserSettings userSettings = UserSettings();


  _HomePageState(this.userSettings);
  @override
  void initState() {
    super.initState();
    _controller = new AnimationController(
        vsync: this, duration: Duration(milliseconds: 800));

    LangHandlerSingleton.getInstance().then(((o) {
      setState(() {
        this.langHandler = o;
      });

      getCredentials().then((credentials) {
        if (credentials[STUDENT_NO_KEY] == null ||
            credentials[PASSWORD_KEY] == null) {
          Navigator.pushNamedAndRemoveUntil(
              context, '/login', (Route<dynamic> route) => false);
        } else {
          UserArgsBundle args = new UserArgsBundle(
              credentials[STUDENT_NO_KEY], credentials[PASSWORD_KEY], userSettings);
          Navigator.pushNamedAndRemoveUntil(
              context, '/grades', (Route<dynamic> route) => false,
              arguments: args);
        }

//        loadUserSettings().then((value) {

//        });
      });
    }));
  }

  @override
  Widget build(BuildContext context) {
    return getLoadingScreen(_controller, userSettings);
  }
}
