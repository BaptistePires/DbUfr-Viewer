import 'dart:io';
import 'package:dbufr_checker/src/CrendentialsArgument.dart';
import 'package:dbufr_checker/src/models/Grade.dart';
import 'package:dbufr_checker/src/models/TeachingUnit.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:url_launcher/url_launcher.dart';
import 'login_page.dart';
import 'package:html/parser.dart' show parse;
import '../src/functions.dart';
import 'package:url_launcher/url_launcher.dart';

class GradesPage extends StatefulWidget {
  @override
  _GradesPageState createState() => _GradesPageState();
}

class _GradesPageState extends State<GradesPage> {
  List<TeachingUnit> ues = new List<TeachingUnit>();
  bool _isInitialized = false;
  bool _cantConnect = false;
  bool _refreshing = false;
  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      setup();
    }
    if (ues.length >= 2){
      ues = sortTeachingUnits(ues);
    }
    return WillPopScope(
        onWillPop: _onWillPop,
        child: Scaffold(
          appBar: _setUpAppBar(),
          body:
              !_cantConnect ? Container(
                  padding: EdgeInsets.only(top: 10),
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
                  child: _isInitialized ? _buildListView(context) : Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[800]),
                      strokeWidth: 3,
                    ),
                  ),
                ) : Text('Can\'t connect to DbUfr or read saved data, try again lateror disconnect.'),
          floatingActionButton: _setUpFloatingActionBtn(),
        ),
    );
  }

  Route _createRoute() {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => LoginPage(),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        var begin = Offset(0, 1);
        var end = Offset.zero;
        var tween = Tween(begin: begin, end: end);
        var offsetAnimation = animation.drive(tween);
        return SlideTransition(
          position: offsetAnimation,
          child: child,
        );
      },
    );
  }

  Future<bool> _onWillPop() async {
    return (await showDialog(
            context: context,
            builder: (context) => AlertDialog(
                  title: Text('Déconnexion'),
                  content: Text('Êtes-vous sûr de vouloir vous déconnecter ? '),
                  actions: <Widget>[
                    FlatButton(
                      onPressed: () {
                        Navigator.of(context).pop(false);
                      },
                      child: Text('Non'),
                    ),
                    FlatButton(
                      onPressed: () {
                        clearSharedPreferences();
                        Navigator.of(context).pushAndRemoveUntil(
                            _createRoute(), (Route<dynamic> route) => false);
                      },
                      child: Text('Oui'),
                    )
                  ],
                ))) ??
        false;
  }

  Future<bool> doDisconnect() async {
    return (await showDialog(
        context: context,
        builder: (context) => AlertDialog(
              title: Text('Déconnexion'),
              content: Text('Êtes-vous sûr de vouloir vous déconnecter ? '),
              actions: <Widget>[
                FlatButton(
                  onPressed: () {
                    Navigator.of(context).pop(false);
                  },
                  child: Text('Non'),
                ),
                FlatButton(
                  onPressed: () {
                    Navigator.of(context).pop(true);
                  },
                  child: Text('Oui'),
                )
              ],
            )));
  }

  AppBar _setUpAppBar() {
    return AppBar(
      title: Text('Notes'),
      actions: <Widget>[
        Padding(
          padding: EdgeInsets.only(right: 10),
          child: IconButton(
            icon: Icon(Icons.power_settings_new),
            onPressed: () async {
              bool doDisconnectUser = await doDisconnect();
              if (doDisconnectUser) {
                clearSharedPreferences();
                Navigator.of(context).pushAndRemoveUntil(
                    _createRoute(), (Route<dynamic> route) => false);
              }
            },
          ),
        )
      ],
    );
  }

  void setup() {
    CredentialsArgument args = ModalRoute.of(context).settings.arguments;

    // If the user is not already logged in
    if (args.htmlGrades != null) {
      parseHTML(args.htmlGrades);
    } else {
      // If he's, then we parse the saved data
      try{
        loadGrades().then((r) {
          setState(() {
            ues = r;
            _isInitialized = true;
          });
        });
      }catch(Exception) {
        // If an error occurs during file's parsing
        getCredentials().then((credentials) {
          getHtmlFromDbUfr(credentials).then((html) {
            parseHTML(args.htmlGrades);
          });
        });
      }

    }
  }

  void parseHTML(String html) async {
    var document = parse(html);
    await Future.delayed(Duration(seconds: 1));
    setState(() {
      ues = pareTUFromHTML(document);
      saveToFile(ues);
      _isInitialized = true;
      _refreshing = false;
    });
  }

  ListView _buildListView(context) {
    final theme = Theme.of(context).copyWith(dividerColor: Colors.transparent);

    return ListView.builder(
      itemCount: ues.length,
      scrollDirection: Axis.vertical,
      padding: EdgeInsets.all(5),
      itemBuilder: (context, i) {
        return Card(
          margin: EdgeInsets.all(10.0),
          elevation: 5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25.0),
            side: BorderSide(color: Colors.transparent, width: 2),
          ),
          child: Container(
            padding: EdgeInsets.all(3),
            child: ues[i].grades.length > 0
                ? Theme(
                    data: theme,
                    child: ExpansionTile(
                      title: Text(
                          '${ues[i].name} [${ues[i].group}] - ${ues[i].year} - ' +
                              truncMonthToFull(ues[i].month)),
                      subtitle: Text('${ues[i].desc}'),
                      children: _setUpGradesListForTU(i),
                    ))
                : Container(
                    padding: EdgeInsets.all(15),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          '${ues[i].name} [${ues[i].group}] - ${ues[i].year} - ' +
                              truncMonthToFull(ues[i].month),
                          style: TextStyle(
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          '${ues[i].desc}',
                          style: TextStyle(fontSize: 14),
                        )
                      ],
                    ),
                  ),
          ),
        );
      },
    );
  }

  List<Widget> _setUpGradesListForTU(int i) {
    List<Widget> gradesWidgets = new List<Widget>();
    List<Grade> grades = ues[i].grades;

    if (grades.length == 0) {
      gradesWidgets.add(Text('Pas de notes'));
    } else {
      ues[i].grades.forEach((Grade g) {
        gradesWidgets.add(Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            SizedBox(
              height: 30,
            ),
            Expanded(
//                  padding: EdgeInsets.only(left:30, bottom: 10),
                child: Padding(
              padding: EdgeInsets.only(left: 30, right: 30, bottom: 5),
              child: RichText(
                text: TextSpan(
                  style: TextStyle(fontSize: 13, color: Colors.black),
                  children: <TextSpan>[
                    TextSpan(
                        text: '${g.grade}/${g.max}',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(text: ' - ${g.desc}')
                  ],
                ),
              ),
            )),
            SizedBox(
              height: 30,
            )
          ],
        ));
      });
    }
    return gradesWidgets;
  }

  List<Widget> setUpTUList() {
    List<Widget> listTiles = new List<ListTile>();
    ues.forEach((TeachingUnit tu) {
      listTiles.add(Card(
        borderOnForeground: false,
        child: ListTile(
          title: Text('oulele'),
        ),
      ));
    });

    return listTiles;
  }

  Widget _setUpFloatingActionBtn() {
    return !_refreshing ? SpeedDial(
      animationSpeed: 10,
//      child: ,
      animatedIcon: AnimatedIcons.menu_close,
      children: [
        SpeedDialChild(
          child: Icon(Icons.refresh),
          label: 'Rafraichir',
          onTap: () {
            setState(() {
              _refreshing = true;
            });
            refresh();
          }
        ),
      ],
    ) : FloatingActionButton(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
      ),
      onPressed: () {},
    );
  }

  void refresh() async {

    getCredentials().then((credentials) {
      getHtmlFromDbUfr(credentials).then((html) {
        parseHTML(html);

      });
    });
  }
}