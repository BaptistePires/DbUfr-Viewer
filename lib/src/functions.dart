import 'dart:convert';
import 'dart:io';
import 'package:dbufr_checker/src/models/Grade.dart';
import 'package:dbufr_checker/src/models/UserSettings.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:html/dom.dart' show Document;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'exceptions/Exceptions.dart';
import 'models/TeachingUnit.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

const String STUDENT_NO_KEY = 'student_no';
const String PASSWORD_KEY = 'password';
const String LANG_KEY = 'lang';
const String USER_SETTINGS_KEY = 'user_settings';

const String DB_UFR_URL =
    'https://www-dbufr.ufr-info-p6.jussieu.fr/lmd/2004/master/auths/seeStudentMarks.php';
const String GRADES_FILE_NAME = 'grades.json';
const String STRING_FILE_PATH = "assets/lang";
const String USER_SETTINGS_NAME = "user_settings.json";

Future<void> clearUserData() async {
  await clearSharedPreferences();
  await deleteGradesFile();
}

// Shared preferences functions
Future<bool> isLogged() async {
  SharedPreferences sp = await SharedPreferences.getInstance();
  if (sp.getString(STUDENT_NO_KEY) == null ||
      sp.getString(PASSWORD_KEY) == null)
    return false;
  else
    return true;
}

Future<void> saveCredentials(String studentNo, String password) async {
  SharedPreferences sp = await SharedPreferences.getInstance();
  sp.setString(STUDENT_NO_KEY, studentNo);
  sp.setString(PASSWORD_KEY, password);
}

Future<Map<String, String>> getCredentials() async {
  SharedPreferences sp = await SharedPreferences.getInstance();
  return {
    STUDENT_NO_KEY: sp.getString(STUDENT_NO_KEY),
    PASSWORD_KEY: sp.getString(PASSWORD_KEY)
  };
}

Future<void> clearSharedPreferences() async {
  SharedPreferences sp = await SharedPreferences.getInstance();
  sp.clear();
}

Future<String> getSavedLangPref() async {
  SharedPreferences sp = await SharedPreferences.getInstance();
  return sp.getString(LANG_KEY);
}

Future<void> saveLangPref(String lang) async {
  SharedPreferences sp = await SharedPreferences.getInstance();
  sp.setString(LANG_KEY, lang);
}

// Http functions
Future<http.Response> queryToDbUfr(String studentNo, String password) async {
  String basicAuth =
      'Basic ' + base64Encode(utf8.encode('$studentNo:$password'));
  return await http.get(DB_UFR_URL, headers: {'authorization': basicAuth});
}

Future<String> getHtmlFromDbUfr(Map<String, String> credentials) async {
  String basicAuth = 'Basic ' +
      base64Encode(utf8.encode(
          '${credentials[STUDENT_NO_KEY]}:${credentials[PASSWORD_KEY]}'));
  try {
    http.Response response =
        await http.get(DB_UFR_URL, headers: {'authorization': basicAuth});
    int code = response.statusCode;
    if (code != 200) {
      if (code == 404) {
        throw new CantReachDbUfrError('Impossible de se connecter à DBUFR.');
      } else if (code == 401) {
        throw new CredentialsError('Mauvais identifiant et/ou mot de passe.');
      }
    } else {
      return response.body;
    }
  } catch (Exception) {
    return null;
  }
  return null;
}

bool t = false;
// HTML functions
List<TeachingUnit> pareTUFromHTML(Document document) {
  List<TeachingUnit> uesObjects = new List<TeachingUnit>();
  var ues =
      document.getElementsByTagName('table')[2].getElementsByTagName('tr');
//      int c = 0;
//      TeachingUnit tu;
  uesObjects = parseTUObjects(ues);
  var grades =
      document.getElementsByTagName('table')[3].getElementsByTagName('tr');
  grades.forEach((child) {
    double grade, max;
    String desc;
    if (child.children[0].text != 'UE') {
      // info => index:
      // 0 - Teaching unit name LUXXXXXX
      // 1 - Description fo the grade
      // 2 - Grade XX/XX
      List info = child.children;
      String tuName = info[0].text.split('-')[0];
      String desc = info[1].text.replaceAll(' ', '');
      String grade = info[2].text.replaceAll(' ', '');

      int i = uesObjects.indexWhere((tu) {
        return tu.name == tuName;
      });
      if (i != -1) {
        String max = grade.split('/')[1];
        grade = grade.split('/')[0];
        uesObjects[i].grades.add(new Grade(
            double.parse(grade), double.parse(max), desc,
            newGrade: true));
      }
    }
  });
  uesObjects.sort((a, b) {
    DateFormat format = DateFormat('yyyy-MM-dd');
    DateTime aTime = format.parse('${a.year}-' + monthToNo(a.month) + '-01');
    DateTime bTime = format.parse('${b.year}-' + monthToNo(b.month) + '-01');
    return bTime.compareTo(aTime);
  });

  return uesObjects;
}

List<TeachingUnit> parseTUObjects(ues) {
  List<TeachingUnit> uesObjects = new List<TeachingUnit>();

  // Foreach teaching unit in the first table that describe them
  ues.forEach((ue) {
    List info = ue.children;
    String group = info[0].text.replaceAll(' ', '');
    String name = info[1].text.replaceAll(' ', '');
    String year = '';
    String month = '';
    info[2].text.split('').forEach((char) {
      if ('0123456789'.contains(char)) {
        year += char;
      } else if (char != ' ') {
        month += char;
      }
    });
    String desc;
    try {
      desc = utf8.decode(Latin1Codec().encode(info[3].text));
    } catch (Exception) {
      desc = info[3].text;
    }

    if (group.length > 0 &&
        name.length > 0 &&
        year.length > 0 &&
        month.length > 0 &&
        desc.length > 0) {
      uesObjects
          .add(new TeachingUnit(group, name, int.parse(year), month, desc));
    }
  });
  return uesObjects;
}

// Models related functions
List<TeachingUnit> sortTeachingUnits(List<TeachingUnit> teachingUnits) {
  teachingUnits.sort((a, b) {
    int aL = a.grades.length;
    int bL = b.grades.length;

    if (aL == 0 && bL == 0) return -1;
    if (aL == 0) return 1;
    if (bL == 0) return 0;
    return compareTwoTuTimes(b, a);
  });
  return teachingUnits;
}

bool hasUnviewedGrades(TeachingUnit tu) {
  bool allViewed = false;
  tu.grades.forEach((g) {
    if (!g.viewed) allViewed = true;
  });
  return allViewed;
}

// Strings related function
String truncMonthToFull(String truncatedMonth) {
  List<String> months = [
    'Janvier',
    'Fevrier',
    'Mars',
    'Avril',
    'Mai',
    'Juin',
    'Juilled',
    'Aout',
    'Septembre',
    'Octobre',
    'Novembre',
    'Decembre'
  ];

  try {
    String m = months.firstWhere((m) {
      return m.toLowerCase().contains(truncatedMonth.toLowerCase());
    });
    return m;
  } catch (Exception) {
    return '';
  }
}

int compareTwoTuTimes(TeachingUnit a, TeachingUnit b) {
  DateFormat format = DateFormat('yyyy-MM-dd');
  DateTime aTime = format.parse('${a.year}-' + monthToNo(a.month) + '-01');
  DateTime bTime = format.parse('${b.year}-' + monthToNo(b.month) + '-01');
  return aTime.compareTo(bTime);
}

String monthToNo(String month) {
  month = month.toLowerCase();
  if (month == 'janvier') {
    return '01';
  }
  if (month == 'fevrier') {
    return '02';
  }
  if (month == 'mars') {
    return '03';
  }
  if (month == 'avril') {
    return '04';
  }
  if (month == 'mai') {
    return '05';
  }
  if (month == 'juin') {
    return '06';
  }
  if (month == 'juillet') {
    return '07';
  }
  if (month == 'aout') {
    return '08';
  }
  if (month == 'septembre') {
    return '09';
  }
  if (month == 'octobre') {
    return '10';
  }
  if (month == 'novembre') {
    return '11';
  }
  if (month == 'decembre') {
    return '12';
  }
  return '01';
}

// Files related functions
Future<String> get _localPath async {
  final directory = await getApplicationDocumentsDirectory();
  return directory.path;
}

Future<File> get _gradesFiles async {
  final path = await _localPath;
  return File('$path/grades.json');
}

Future<File> saveToFile(List<TeachingUnit> teachingUnits) async {
  final file = await _gradesFiles;
  String jsonTeachingUnits = json.encode(teachingUnits);
  return file.writeAsString(jsonTeachingUnits);
}

Future<List<TeachingUnit>> loadGrades() async {
  final file = await _gradesFiles;
  if (!file.existsSync()) return null;
  String content = await file.readAsString();
  if (content.length == 0) return null;
  List<dynamic> json = jsonDecode(content);
  List<TeachingUnit> teachingUnits = new List<TeachingUnit>();

  json.forEach((o) {
    teachingUnits.add(TeachingUnit.fromJson(o));
  });
  return teachingUnits;
}

Future<void> deleteGradesFile() async {
  final file = await _gradesFiles;
  await file.delete();
}

Future<File> _getLangFile(String langCode) async {
  final path = await _localPath;
  return File('$path/$STRING_FILE_PATH/$langCode.json');
}

Future<Map<String, dynamic>> loadLang(String langCode) async {
  String content =
      await rootBundle.loadString('$STRING_FILE_PATH/$langCode.json');
  dynamic json = jsonDecode(content);
  return json;
}

Future<UserSettings> loadUserSettings() async {
  final path = await _localPath;
  File file = File('$path/$USER_SETTINGS_NAME');
  if (!file.existsSync()) {
    UserSettings us = UserSettings();
    saveUserSettings(us);
    return us;
  }
  return UserSettings.fromMap(json.decode(file.readAsStringSync()));
}

Future<void> saveUserSettings(UserSettings settings) async {
  final path = await _localPath;
  File file = File('$path/$USER_SETTINGS_NAME');
  String jsonSettings = json.encode(settings.asMap);
  await file.writeAsString(jsonSettings);
}

Future<List<String>> getFontPaths(context) async {
  // To get paths you need these 2 lines
  final manifestContent =
      await DefaultAssetBundle.of(context).loadString('AssetManifest.json');
  final Map<String, dynamic> manifestMap = json.decode(manifestContent);

  return manifestMap.keys
      .where((String key) => key.contains('assets/fonts/'))
      .where((String key) => key.contains('.ttf'))
      .toList();
}

List<String> getFontsNameFromPaths(List<String> paths) {
  return paths
      .map((e) => e.substring(e.lastIndexOf('/') + 1, e.lastIndexOf('.')))
      .toList();
}

// WIDGETS CONSTRUCTOS
LinearGradient getLinearGradientBg() {
  return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Colors.lightBlue[400],
        Colors.lightBlue,
        Colors.lightBlue[600],
        Colors.lightBlue[700],
        Colors.lightBlue[800],
      ]);
}

SnackBar setUpConnectDbUfrSnack(String text) {
  return SnackBar(
    duration: Duration(seconds: 2),
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(10)),
        side: BorderSide(color: Colors.lightBlue[300], width: 2)),
    content: Container(
      padding: EdgeInsets.all(10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Icon(Icons.error),
          SizedBox(
            width: 15,
          ),
          Flexible(
            child: Text(
              text,
              overflow: TextOverflow.clip,
            ),
          )
        ],
      ),
    ),
  );
}

Container getLoadingScreen(AnimationController parent) {
  return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(gradient: getLinearGradientBg()),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          SpinKitPouringHourglass(
            color: Colors.black,
//          TODO : FIX ISSUE WITH TIMER
//            controller: parent,
          ),
          SizedBox(
            height: 60,
          ),
          Text(
            '{ Loading }',
            style: TextStyle(fontSize: 30, letterSpacing: 1),
          )
        ],
      ));
}

Text formatTitle(String text, UserSettings us, [bool colored = false]) {
  return Text(text,
      style: TextStyle(
          fontSize: us.asMap[TITLE_FONT_SIZE],
          fontFamily: us.asMap[FONT_NAME],
          color: colored ? us.asMap[PRIMARY_COLOR_NAME] : null));
}

Text formatSubtitle(String text, UserSettings us) {
  return Text(text,
      style: TextStyle(
        fontSize: us.asMap[SUBTITLE_FONT_SIZE],
        fontFamily: us.asMap[FONT_NAME],
      ));
}

// COLORS FUNCTIONS

Color colorFromDouble(double c) {
  assert(c >= 0 && c <= 360);
  return HSVColor.fromAHSV(1, c, 1, 1).toColor();
}

List<Color> getGradientFromTmpColors(List<double> colors) =>
    colors.map((e) => HSVColor.fromAHSV(1, e, 1, 1).toColor()).toList();
