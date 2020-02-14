import 'dart:io';
import 'package:dbufr_checker/src/CrendentialsArgument.dart';
import 'package:dbufr_checker/src/LangHandlerSingleton.dart';
import 'package:dbufr_checker/src/models/Grade.dart';
import 'package:dbufr_checker/src/models/TeachingUnit.dart';
import 'package:flag/flag.dart';
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
  bool _loading = true;

  LangHandlerSingleton langHandler;

  @override
  void initState() {
    super.initState();
    LangHandlerSingleton.getInstance().then((value) {
      setState(() {
        langHandler = value;
        _loading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      setup();
    }
    if (ues.length >= 2) {
      ues = sortTeachingUnits(ues);
    }
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: _setUpAppBar(),
        body: !_cantConnect || _loading
            ? Container(
          padding: EdgeInsets.only(top: 10),
          decoration:
          BoxDecoration(gradient: getLinearGradientBg()),
          child: _isInitialized
              ? _buildListView(context)
              : Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                  Colors.blue[800]),
              strokeWidth: 3,
            ),
          ),
        )
            : getLoadingScreen(),
        floatingActionButton: !_loading ? _setUpFloatingActionBtn() : null,
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
        builder: (context) =>
            AlertDialog(
              title: Text(langHandler.getTranslationFor('logout')),
              content: Text(
                  langHandler.getTranslationFor('grades_confirm_desc')),
              actions: <Widget>[
                FlatButton(
                  onPressed: () {
                    Navigator.of(context).pop(false);
                  },
                  child: Text(langHandler.getTranslationFor('no')),
                ),
                FlatButton(
                  onPressed: () async {
                    await clearUserData();
                    Navigator.of(context).pushAndRemoveUntil(
                        _createRoute(), (Route<dynamic> route) => false);
                  },
                  child: Text(langHandler.getTranslationFor('yes')),
                )
              ],
            ))) ??
        false;
  }

  Future<bool> doDisconnect() async {
    return (await showDialog(
        context: context,
        builder: (context) =>
            AlertDialog(
              title: Text(langHandler.getTranslationFor('logout')),
              content: Text(
                  langHandler.getTranslationFor('grades_confirm_disc')),
              actions: <Widget>[
                FlatButton(
                  onPressed: () {
                    Navigator.of(context).pop(false);
                  },
                  child: Text(langHandler.getTranslationFor('no')),
                ),
                FlatButton(
                  onPressed: () {
                    Navigator.of(context).pop(true);
                  },
                  child: Text(langHandler.getTranslationFor('yes')),
                )
              ],
            )));
  }

  AppBar _setUpAppBar() {
    return AppBar(
      title: !_loading ? Text(langHandler.getTranslationFor('grades')) : Text(
          ''),
      actions: <Widget>[
        Padding(
          padding: EdgeInsets.only(right: 10),
          child: IconButton(
            icon: Icon(Icons.power_settings_new),
            onPressed: () async {
              if (_loading) return;
              bool doDisconnectUser = await doDisconnect();
              if (doDisconnectUser) {
                await clearUserData();
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
    CredentialsArgument args = ModalRoute
        .of(context)
        .settings
        .arguments;

    // If the user is not already logged in
    if (args.htmlGrades != null) {
      parseHTML(args.htmlGrades);
    } else {
      // If he's, then we parse the saved data
      try {
        loadGrades().then((r) {
          if (r == null) {
            _refreshing = true;
            refresh();
            return;
          }
          setState(() {
            ues = r;
            _isInitialized = true;
            _cantConnect = false;
          });
        });
      } catch (e) {
        setState(() {
          _refreshing = true;
          refresh();
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
            side: BorderSide(
                color: !hasUnviewedGrades(ues[i])
                    ? Colors.transparent
                    : Colors.red,
                width: 2),
          ),
          child: Container(
            padding: EdgeInsets.all(3),

            child: ues[i].grades.length > 0
                ? Theme(
                data: theme,
                // START TILE
                child: ExpansionTile(
                  // TITLE
                  title: Text('${ues[i].desc}',
                    style: TextStyle(
                        color: Colors.blue,
                        letterSpacing: 1,
                    ),
                    textAlign: TextAlign.center,


                  ),
                  // SUBTITLE
                  subtitle: Container(
                    padding: EdgeInsets.only(top: 5, left: 8),
                    child: Text(
                      '${ues[i].name} [${ues[i].group}] - ${ues[i].year} - ' +
                          truncMonthToFull(ues[i].month),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  // TILE CONTENT
                  children: _setUpGradesListForTU(i),
                  onExpansionChanged: (change) {
                    bool hasChanged = false;
                    setState(() {
                      ues[i].grades.forEach((g) {
                        if (!g.viewed) {
                          g.viewed = true;
                          hasChanged = true;
                        }
                        ;
                      });
                    });
                    if (hasChanged) saveToFile(ues);
                  },
                ))
                : Container(
              padding: EdgeInsets.all(15),
              alignment: Alignment.center,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Text('${ues[i].desc}',
                    style: TextStyle(
                        fontSize: 15, color: Colors.blue, letterSpacing: 1),
                  ),
                  Container(
                    padding: EdgeInsets.only(top: 5, left: 8),
                    child: Text('${ues[i].name} [${ues[i].group}] - ${ues[i]
                        .year} - ${truncMonthToFull(ues[i].month)}',
                      overflow: TextOverflow.ellipsis,
                    ),
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
      gradesWidgets.add(
          Text(langHandler.getTranslationFor('grades_no_grades')));
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
                      style: TextStyle(
                          fontSize: 13,
                          color: g.newGrade ? Colors.red : Colors.black),
                      children: <TextSpan>[
                        TextSpan(
                            text: '${g.grade}/${g.max}',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
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

  Widget _setUpFloatingActionBtn() {
    return !_refreshing
        ? SpeedDial(
//      child: Icon(Icons.add),
      animatedIcon: AnimatedIcons.menu_close,
      animationSpeed: 300,
      closeManually: true,
      children: [
        SpeedDialChild(
            child: Icon(Icons.power_settings_new),
            label: langHandler.getTranslationFor('logout'),
            onTap: () async {
              bool doDisconnectUser = await doDisconnect();
              if (doDisconnectUser) {
                await clearUserData();
                Navigator.of(context).pushAndRemoveUntil(
                    _createRoute(), (Route<dynamic> route) => false);
              }
            }),
        SpeedDialChild(
            child: Icon(Icons.refresh),
            label: langHandler.getTranslationFor('refresh'),
            onTap: () {
              setState(() {
                _refreshing = true;
              });
              refresh();
            }),
        SpeedDialChild(
            child: langHandler.getCurrentFlag(),
            label: langHandler.getTranslationFor('language'),
            onTap: () {
              setState(() {
                _loading = true;
              });

              Future(langHandler.nextLang).then((value) {
                setState(() {
                  _loading = false;
                });
              });
            })
      ],
    )
        : FloatingActionButton(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
      ),
      onPressed: () {},
    );
  }

  void refresh() async {
    Map<String, String> credentials = await getCredentials();

    if (credentials['student_no'] == null || credentials['password'] == null) {
      CredentialsArgument args = ModalRoute
          .of(context)
          .settings
          .arguments;
      credentials = {
        STUDENT_NO_KEY: args.studentNo,
        PASSWORD_KEY: args.password
      };
    }

    getHtmlFromDbUfr(credentials).then((html) {
      try {
        List<TeachingUnit> newTeachingUnits = pareTUFromHTML(parse(html));
        newTeachingUnits.forEach((newTeachingUnData) {
          bool teachingUExists = false;
          ues.forEach((currentTu) {
            if (newTeachingUnData.name == currentTu.name) {
              teachingUExists = true;
              if (newTeachingUnData.grades.length != currentTu.grades.length) {
                newTeachingUnData.grades.forEach((gradeFromQuery) {
                  bool present = false;
                  currentTu.grades.forEach((current_grade) {
                    if (gradeFromQuery == current_grade) {
                      present = true;
                    }
                  });
                  gradeFromQuery.newGrade = true;
                  if (!present) currentTu.grades.add(gradeFromQuery);
                });
              } else {
                currentTu.grades.forEach((g) {
                  g.newGrade = false;
                });
              }
            }
          });
          if (!teachingUExists) ues.add(newTeachingUnData);
        });
        setState(() {
          _refreshing = false;
          _cantConnect = false;
          _isInitialized = true;
        });
        _showSnackBarSuccessRefresh();
      } catch (e) {
        setState(() {
          _refreshing = false;
          if (ues.length > 0) {
            Scaffold.of(context).showSnackBar(setUpConnectDbUfrSnack(
                langHandler.getTranslationFor('grades_update_error')));
          }
        });
      }
    });
  }

  Widget _setUpCantConnect() {
    return Container(
      decoration: BoxDecoration(
        gradient: getLinearGradientBg(),
      ),
      padding: EdgeInsets.all(20),
      child: Center(
        child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15.0),
              color: Colors.white,
            ),
            child: Padding(
                padding: EdgeInsets.all(20),
                child: Wrap(
                  children: <Widget>[
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Text(
                          langHandler.getTranslationFor('error'),
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(
                          height: 10,
                        ),
                        Divider(),
                        SizedBox(
                          height: 10,
                        ),
                        Text(
                          langHandler.getTranslationFor('login_connect_error'),
                          style: TextStyle(
                            fontSize: 17,
                          ),
                        ),
                        OutlineButton(
                          onPressed: () {
                            setState(() {
                              refresh();
                              _refreshing = true;
                            });
                          },
                        ),
                      ],
                    )
                  ],
                ))),
      ),
    );
  }

  void _showSnackBarSuccessRefresh() {
    Scaffold.of(context).showSnackBar(
        setUpConnectDbUfrSnack(
            langHandler.getTranslationFor('grades_data_update_success')));
  }
}
