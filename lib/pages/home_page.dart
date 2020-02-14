import 'package:dbufr_checker/src/CrendentialsArgument.dart';
import 'package:dbufr_checker/src/LangHandlerSingleton.dart';
import 'package:dbufr_checker/src/functions.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  LangHandlerSingleton langHandler;
  AnimationController _controller;

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
          CredentialsArgument args = new CredentialsArgument(
              credentials[STUDENT_NO_KEY], credentials[PASSWORD_KEY]);
          Navigator.pushNamedAndRemoveUntil(
              context, '/grades', (Route<dynamic> route) => false,
              arguments: args);
        }
      });
    }));
  }

  @override
  Widget build(BuildContext context) {
    return getLoadingScreen(_controller);
  }
}
