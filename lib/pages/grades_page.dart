import 'dart:math';
import 'package:dbufr_checker/src/CrendentialsArgument.dart';
import 'package:dbufr_checker/src/LangHandlerSingleton.dart';
import 'package:dbufr_checker/src/LifeCycleEventHandler.dart';
import 'package:dbufr_checker/src/models/Grade.dart';
import 'package:dbufr_checker/src/models/TeachingUnit.dart';
import 'package:dbufr_checker/src/models/UserSettings.dart';
import 'package:dbufr_checker/src/widgets/AlertDialogInfo.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'login_page.dart';
import 'package:html/parser.dart' show parse;
import '../src/functions.dart';

class GradesPage extends StatefulWidget {
  @override
  _GradesPageState createState() => _GradesPageState();
}

class _GradesPageState extends State<GradesPage>
    with SingleTickerProviderStateMixin {
  List<TeachingUnit> teachingUnits = new List<TeachingUnit>();
  bool _isInitialized = false;
  bool _cantConnect = false;
  bool _refreshing = false;
  bool _loading = true;
  bool _settingsInit = true;

  LangHandlerSingleton langHandler;
  AnimationController _animationController;

  UserSettings userSettings = UserSettings();

  @override
  void initState() {
    super.initState();
    _animationController = new AnimationController(
        vsync: this, duration: Duration(milliseconds: 800));
    LangHandlerSingleton.getInstance().then((value) {
      setState(() {
        langHandler = value;
        _loading = false;

        // Handle on resume
        WidgetsBinding.instance
            .addObserver(LifecycleEventHandler(resumeCallBack: () {
          refresh();
          refreshSettings();
          return null;
        }));

        UserArgsBundle args = ModalRoute.of(context).settings.arguments;
        // give config from parent
        setState(() {
          userSettings = args.userSettings;
        });
      });
    });


  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      setup();
    }
    if (teachingUnits.length >= 2) {
      teachingUnits = sortTeachingUnits(teachingUnits);
    }
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: colorFromDouble(userSettings.linearBgColors[0]),
        appBar: _setUpAppBar(),
        body: !_cantConnect || _loading || !_settingsInit
            ? Container(
                padding: EdgeInsets.only(top: 10),
                decoration: BoxDecoration(
                    gradient: LinearGradient(
                        colors: getGradientFromTmpColors(
                            userSettings.linearBgColors),
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter)),
                child: _isInitialized
                    ? _buildListView(context)
                    : Center(
                        child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.blue[800]),
                          strokeWidth: 3,
                        ),
                      ),
              )
            : getLoadingScreen(_animationController, userSettings),
        floatingActionButton: !_cantConnect || _loading || !_settingsInit
            ? _setUpFloatingActionBtn()
            : null,
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
                  title: Text(
                    langHandler.getTranslationFor('logout'),
                    style: TextStyle(
                        fontFamily: userSettings.fontName,
                        fontSize: userSettings.titleFontSize,
                        color: colorFromDouble(userSettings.primaryColor)),
                  ),
                  content: Text(
                    langHandler.getTranslationFor('grades_confirm_disc'),
                    style: TextStyle(
                      fontFamily: userSettings.fontName,
                      fontSize: userSettings.subtitlesFontSize,
                    ),
                  ),
                  actions: <Widget>[
                    FlatButton(
                      onPressed: () {
                        Navigator.of(context).pop(false);
                      },
                      child: Text(
                        langHandler.getTranslationFor('no'),
                        style: TextStyle(
                            fontFamily: userSettings.fontName,
                            fontSize: userSettings.subtitlesFontSize,
                            color: colorFromDouble(userSettings.primaryColor)),
                      ),
                    ),
                    FlatButton(
                      onPressed: () async {
                        await clearUserData();
                        Navigator.of(context).pushAndRemoveUntil(
                            _createRoute(), (Route<dynamic> route) => false);
                        return false;
                      },
                      child: Text(
                        langHandler.getTranslationFor('yes'),
                        style: TextStyle(
                            fontFamily: userSettings.fontName,
                            fontSize: userSettings.subtitlesFontSize,
                            color: colorFromDouble(userSettings.primaryColor)),
                      ),
                    ),
                  ],
                ))) ??
        false;
  }

  Future<bool> doDisconnect() async {
    return (await showDialog(
        context: context,
        builder: (context) => AlertDialog(
              title: Text(
                langHandler.getTranslationFor('logout'),
                style: TextStyle(
                    fontFamily: userSettings.fontName,
                    fontSize: userSettings.titleFontSize,
                    color: colorFromDouble(userSettings.primaryColor)),
              ),
              content: Text(
                langHandler.getTranslationFor('grades_confirm_disc'),
                style: TextStyle(
                  fontFamily: userSettings.fontName,
                  fontSize: userSettings.subtitlesFontSize,
                ),
              ),
              actions: <Widget>[
                FlatButton(
                  onPressed: () {
                    Navigator.of(context).pop(false);
                  },
                  child: Text(langHandler.getTranslationFor('no'),
                      style: TextStyle(
                          fontFamily: userSettings.fontName,
                          fontSize: userSettings.subtitlesFontSize,
                          color: colorFromDouble(userSettings.primaryColor))),
                ),
                FlatButton(
                  onPressed: () {
                    Navigator.of(context).pop(true);
                  },
                  child: Text(langHandler.getTranslationFor('yes'),
                      style: TextStyle(
                          fontFamily: userSettings.fontName,
                          fontSize: userSettings.subtitlesFontSize,
                          color: colorFromDouble(userSettings.primaryColor))),
                )
              ],
            )));
  }

  AppBar _setUpAppBar() {
    return AppBar(
      title: !_loading
          ? Text(
              langHandler.getTranslationFor('grades'),
              style: TextStyle(
                fontFamily: userSettings.fontName,
                fontSize: userSettings.titleFontSize + 2,
//              color:colorFromDouble(userSettings.primaryColor)
              ),
            )
          : Text(''),
      backgroundColor: colorFromDouble(userSettings.primaryColor),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
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
    UserArgsBundle args = ModalRoute.of(context).settings.arguments;

    // If the user is not already logged in
    if (args.htmlGrades != null) {
      parseHTML(args.htmlGrades);
    } else {
      // If he's, then we parse the saved data
      try {
        loadGrades().then((r) {
          if (r == null) {
            refresh();
            return;
          }
          setState(() {
            teachingUnits = r;
            _isInitialized = true;
            _cantConnect = false;
          });
        });
      } catch (e) {
        setState(() {
          refresh();
        });
      }
    }
  }

  void parseHTML(String html) async {
    var document = parse(html);
    await Future.delayed(Duration(seconds: 1));
    setState(() {
      teachingUnits = pareTUFromHTML(document);
      saveToFile(teachingUnits);
      _isInitialized = true;
      _refreshing = false;
    });
  }

  Widget _buildListView(context) {
    final theme = Theme.of(context).copyWith(dividerColor: Colors.transparent);

    return RefreshIndicator(
      onRefresh: () => refresh(),
      child: ListView.builder(
        itemCount: teachingUnits.length,
        scrollDirection: Axis.vertical,
        padding: EdgeInsets.all(5),
        itemBuilder: (context, i) {
          return Card(
            margin: EdgeInsets.all(10.0),
            elevation: 5,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25.0),
              side: BorderSide(
                  color: !hasUnviewedGrades(teachingUnits[i])
                      ? Colors.transparent
                      : Colors.red,
                  width: 2),
            ),
            child: Container(
              padding: EdgeInsets.all(3),
              child: teachingUnits[i].grades.length > 0
                  ? Theme(
                      data: theme,
                      // START TILE
                      child: ExpansionTile(
                        // TITLE
                        title: Text(
                          '${teachingUnits[i].desc}',
                          style: TextStyle(
                              fontFamily: userSettings.fontName,
                              fontSize: userSettings.titleFontSize,
                              color:
                                  colorFromDouble(userSettings.primaryColor)),
                          textAlign: TextAlign.center,
                        ),
                        // SUBTITLE
                        subtitle: Container(
                          padding: EdgeInsets.only(top: 5, left: 8),
                          child: Text(
                              '${teachingUnits[i].name} [${teachingUnits[i].group}] - ${teachingUnits[i].year} - ' +
                                  truncMonthToFull(teachingUnits[i].month),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: userSettings.fontName,
                                fontSize: userSettings.subtitlesFontSize,
                                color: Colors.black,
                              )),
                        ),

                        // TILE CONTENT
                        children: _setUpGradesListForTU(i),
                        onExpansionChanged: (change) {
                          bool hasChanged = false;
                          setState(() {
                            teachingUnits[i].grades.forEach((g) {
                              if (!g.viewed) {
                                g.viewed = true;
                                hasChanged = true;
                              }
                            });
                          });
                          if (hasChanged) saveToFile(teachingUnits);
                        },
                      ))
                  : Container(
                      padding: EdgeInsets.all(15),
                      alignment: Alignment.center,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          Text(
                            '${teachingUnits[i].desc}',
                            style: TextStyle(
                                fontFamily: userSettings.fontName,
                                fontSize: userSettings.titleFontSize,
                                color:
                                    colorFromDouble(userSettings.primaryColor),
                                letterSpacing: 1),
                            textAlign: TextAlign.center,
                          ),
                          Container(
                            padding: EdgeInsets.only(top: 5, left: 8),
                            child: Text(
                              '${teachingUnits[i].name} [${teachingUnits[i].group}] - ${teachingUnits[i].year} - ${truncMonthToFull(teachingUnits[i].month)}',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: userSettings.fontName,
                                fontSize: userSettings.subtitlesFontSize,
//                                color:colorFromDouble(userSettings.primaryColor)
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
            ),
          );
        },
      ),
    );
  }

  List<Widget> _setUpGradesListForTU(int i) {
    List<Widget> gradesWidgets = new List<Widget>();
    List<Grade> grades = teachingUnits[i].grades;

    if (grades.length == 0) {
      gradesWidgets.add(Text(
        langHandler.getTranslationFor('grades_no_grades'),
        style: TextStyle(
            fontSize: userSettings.subtitlesFontSize,
            fontFamily: userSettings.fontName),
      ));
    } else {
      teachingUnits[i].grades.forEach((Grade g) {
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
                      fontSize: userSettings.subtitlesFontSize,
                      color: g.newGrade ? Colors.red : Colors.black,
                      fontFamily: userSettings.fontName),
                  children: <TextSpan>[
                    TextSpan(
                        text: '${g.grade}/${g.max}',
                        style: TextStyle(
                            fontSize: userSettings.subtitlesFontSize,
                            fontWeight: FontWeight.bold,
                            color: colorFromDouble(
                              userSettings.primaryColor,
                            ))),
                    TextSpan(text: ' ${g.desc}')
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
            animatedIcon: AnimatedIcons.menu_close,
            animationSpeed: 300,
            closeManually: true,
            curve: Curves.fastOutSlowIn,
            backgroundColor: colorFromDouble(userSettings.primaryColor),
            children: [
              SpeedDialChild(
                  child: Icon(Icons.power_settings_new),
                  backgroundColor: colorFromDouble(userSettings.primaryColor),
                  label: !_loading
                      ? langHandler.getTranslationFor('logout')
                      : null,
                  labelStyle: TextStyle(
                      fontFamily: userSettings.fontName,
                      fontSize: userSettings.subtitlesFontSize),
                  onTap: () async {
                    if (_loading) return;
                    bool doDisconnectUser = await doDisconnect();
                    if (doDisconnectUser) {
                      await clearUserData();
                      Navigator.of(context).pushAndRemoveUntil(
                          _createRoute(), (Route<dynamic> route) => false);
                    }
                  }),
              SpeedDialChild(
                  child: Icon(Icons.settings),
                  backgroundColor: colorFromDouble(userSettings.primaryColor),
                  label: !_loading
                      ? langHandler.getTranslationFor('settings')
                      : '',
                  labelStyle: TextStyle(
                      fontFamily: userSettings.fontName,
                      fontSize: userSettings.subtitlesFontSize),
                  onTap: () {
                    Navigator.of(context)
                        .pushNamed('/settings')
                        .then((o) => refreshSettings());
                  }),
              SpeedDialChild(
                  child: Icon(Icons.refresh),
                  backgroundColor: colorFromDouble(userSettings.primaryColor),
                  label: !_loading
                      ? langHandler.getTranslationFor('refresh')
                      : null,
                  labelStyle: TextStyle(
                      fontFamily: userSettings.fontName,
                      fontSize: userSettings.subtitlesFontSize),
                  onTap: () {
                    if (_loading) return;
                    refresh();
                  }),
              SpeedDialChild(
                  backgroundColor: colorFromDouble(userSettings.primaryColor),
                  child: !_loading ? langHandler.getCurrentFlag() : null,
                  label: !_loading
                      ? langHandler.getTranslationFor('language')
                      : null,
                  labelStyle: TextStyle(
                      fontFamily: userSettings.fontName,
                      fontSize: userSettings.subtitlesFontSize),
                  onTap: () {
                    if (_loading) return;
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
            backgroundColor: colorFromDouble(userSettings.primaryColor),
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
            onPressed: () {},
          );
  }

  Future<void> refresh() async {
    setState(() {
      _refreshing = true;
    });
    Map<String, String> credentials = await getCredentials();

    if (credentials['student_no'] == null || credentials['password'] == null) {
      UserArgsBundle args = ModalRoute.of(context).settings.arguments;
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
          teachingUnits.forEach((currentTu) {
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
          if (!teachingUExists) teachingUnits.add(newTeachingUnData);
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
          if (teachingUnits.length > 0) {
            Scaffold.of(context).showSnackBar(setUpSnackBar(
                langHandler.getTranslationFor('grades_update_error'),
                userSettings));
          }
        });
      }
    });
  }

  Future<void> refreshSettings() async {
    loadUserSettings().then((value) {
      setState(() {
        userSettings = value;
      });
    });
  }

  void _showSnackBarSuccessRefresh() {
    Scaffold.of(context).showSnackBar(setUpSnackBar(
        langHandler.getTranslationFor('grades_data_update_success'),
        userSettings));
  }
}
