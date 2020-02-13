import 'dart:io';

import 'package:dbufr_checker/src/CrendentialsArgument.dart';
import 'package:dbufr_checker/src/models/Grade.dart';
import 'package:dbufr_checker/src/models/TeachingUnit.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'login_page.dart';
import 'package:html/parser.dart' show parse;
import 'package:quiver/strings.dart';
import '../src/functions.dart';

class GradesPage extends StatefulWidget {
  @override
  _GradesPageState createState() => _GradesPageState();
}

class _GradesPageState extends State<GradesPage> {
  List<TeachingUnit> ues = new List<TeachingUnit>();
  bool isInitialized = false;

  @override
  Widget build(BuildContext context) {
    if (!isInitialized) {
      setup();
    }

    return WillPopScope(
        onWillPop: _onWillPop,
        child: Scaffold(
          appBar: _setUpAppBar(),
          body: isInitialized ? Container(
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
            child: _buildListView(context),
          ) : Center(
            child: CircularProgressIndicator(),
          ),
        ));
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
        builder: (context) =>
            AlertDialog(
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
              print(doDisconnectUser);
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
    parseHTML();
    // TODO : Save to file
  }

  void parseHTML() async {
    CredentialsArgument args = ModalRoute
        .of(context)
        .settings
        .arguments;
    if (args.htmlGrades == null) {
      // Retrieve from file
    } else {
      var document = parse(args.htmlGrades);

      await Future.delayed(Duration(seconds: 1));
      setState(() {
        ues = pareTUFromHTML(document);
        print('parsing terminé');
        isInitialized = true;
      });
    }
  }

  ListView _buildListView(context) {
    final theme = Theme.of(context).copyWith(
        dividerColor: Colors.transparent);

//    TeachingUnit tu = new TeachingUnit('grp2', 'LU32', 2020, 'fev', 'desc' );
//    tu.grades.add(new Grade(max: 20, grade: 20, desc: 'lol'));
//    ues.add(tu);
    ues.sort((a,b)  {
      int aL = a.grades.length;
      int bL = b.grades.length;

      if(aL == 0&& bL==0) return -1;
      if(aL == 0) return 1;
      return compareTwoTuTimes(b, a);
    });
    return ListView.builder(
      itemCount: ues.length,
      scrollDirection: Axis.vertical,
      semanticChildCount: 3,

      itemBuilder: (context, i) {
        return Card(
          margin: EdgeInsets.all(10.0),
          elevation: 5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(32.0),
            side: BorderSide(
          color: Colors.transparent,
        width: 2
        ),
          ),
          child: Container(
            padding: EdgeInsets.all(3),
            child: ues[i].grades.length >0 ? Theme(data:theme, child:ExpansionTile(

              title: Text('${ues[i].name} [${ues[i].group}] - ${ues[i].year} - ' + truncMonthToFull(ues[i].month)),
              subtitle: Text('${ues[i].desc}'),
              children: _setUpGradesListForTU(i),
            )) : Container(
              padding: EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[

                  Text('${ues[i].name} [${ues[i].group}] - ${ues[i].year} - ' + truncMonthToFull(ues[i].month),
                  style: TextStyle(
                    fontSize: 15,

                  ),),
                  Text('${ues[i].desc}',
                  style: TextStyle(
                    fontSize: 14
                  ),)
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

    if(grades.length == 0) {
      gradesWidgets.add(Text('Pas de notes'));
    }else{
      ues[i].grades.forEach((Grade g) {
        gradesWidgets.add(
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              SizedBox(height: 30,),
              Expanded(
//                  padding: EdgeInsets.only(left:30, bottom: 10),
                    child: Padding(
                      padding: EdgeInsets.only(left: 30, right:30, bottom: 5),
                      child: RichText(
                        text: TextSpan(
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.black
                          ),
                          children: <TextSpan>[
                            TextSpan(
                              text: '${g.grade}/${g.max}',
                              style: TextStyle(fontWeight: FontWeight.bold)
                            ),
                            TextSpan(text:' - ${g.desc}')
                          ],
                        ),
                      ),
                    )
                 ),
              SizedBox(
                height: 30,
              )
            ],
          )
        );
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
}
//@override
//void initState() {
//  super.initState();
//  setup();
//  print('e');
//}
