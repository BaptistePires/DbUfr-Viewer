import 'package:dbufr_checker/src/LangHandlerSingleton.dart';
import 'package:dbufr_checker/src/functions.dart';
import 'package:dbufr_checker/src/models/UserSettings.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AlertInfoDialog extends StatefulWidget {
  final UserSettings us;
  final LangHandlerSingleton langHandler;

  AlertInfoDialog(this.us, this.langHandler);

  @override
  _AlertInfoDialogState createState() =>
      _AlertInfoDialogState(this.us, this.langHandler);
}

class _AlertInfoDialogState extends State<AlertInfoDialog> {
  UserSettings us;
  LangHandlerSingleton langHandler;

  _AlertInfoDialogState(this.us, this.langHandler);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30),
      ),
      content: Container(
        padding: EdgeInsets.all(10),
        child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: _setUpTitle() +
                _setUpDivider() +
                _setUpInfoText() +
                _setUpCreditTitle() +
                _setUpDivider() +
                _setUpCredits()),
      ),
    );
  }

  List<Widget> _setUpTitle() {
    return [
      Text(
        langHandler.getTranslationFor('information'),
        style: TextStyle(
            fontFamily: us.fontName,
            fontSize: us.titleFontSize,
            color: colorFromDouble(us.primaryColor),
            letterSpacing: 2),
      )
    ];
  }

  List<Widget> _setUpDivider() {
    return [
      SizedBox(
        height: 10,
      ),
      Divider(
        color: colorFromDouble(us.primaryColor),
        thickness: 1,
      ),
      SizedBox(
        height: 10,
      )
    ];
  }

  List<Widget> _setUpInfoText() {
    return [
      Text(
        langHandler.getTranslationFor('information_text_info'),
        style: TextStyle(fontSize: 15, fontFamily: us.fontName),
      )
    ];
  }

  List<Widget> _setUpCreditTitle() {
    return [
      SizedBox(
        height: 20,
      ),
      Text(langHandler.getTranslationFor('credits'),
          style: TextStyle(
              fontFamily: us.fontName,
              fontSize: us.titleFontSize,
              color: colorFromDouble(us.primaryColor),
              letterSpacing: 2))
    ];
  }

  List<Widget> _setUpCredits() {
    return [
      Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Icon(Icons.code),
          SizedBox(
            width: 10,
          ),
          GestureDetector(
            child: Text(
              'Baptiste Pires',
              style: TextStyle(),
            ),
            onTap: () {
              launch('https://icons8.com/');
            },
          ),
        ],
      ),
      Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Image.asset(
            'assets/icon/icon.png',
            height: 24,
            width: 24,
          ),
          SizedBox(
            width: 10,
          ),
          GestureDetector(
            child: Text(
              'icons8.com',
              style: TextStyle(
                  color: Colors.blue, decoration: TextDecoration.underline),
            ),
            onTap: () {
              launch('https://icons8.com/');
            },
          )
        ],
      ),
    ];
  }

  void _launchURL(String url) async {}
}
