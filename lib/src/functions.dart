import 'dart:convert';
import 'package:dbufr_checker/src/models/Grade.dart';
import 'package:flutter/foundation.dart';
import 'package:html/dom.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'exceptions/Exceptions.dart';
import 'models/TeachingUnit.dart';
import 'package:html/parser.dart' show parse;
import 'package:intl/intl.dart';

const String STUDENT_NO_KEY = 'student_no';
const String PASSWORD_KEY = 'password';
const String DB_UFR_URL = 'https://www-dbufr.ufr-info-p6.jussieu.fr/lmd/2004/master/auths/seeStudentMarks.php';

// Shared preferences functions
Future<bool> isLogged() async {
  SharedPreferences sp = await SharedPreferences.getInstance();
  sp.getKeys().forEach((key) {
    print(sp.get(key));
  });
  if (sp.getString(STUDENT_NO_KEY) == null ||
      sp.getString(PASSWORD_KEY) == null)
    return false;
  else
    return true;
}

void saveCredentials(String studentNo, String password) async {
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

void clearSharedPreferences() async {
  SharedPreferences sp = await SharedPreferences.getInstance();
  sp.clear();
}

// Http functions
Future<http.Response> queryToDbUfr(String studentNo, String password )async {
  String basicAuth = 'Basic ' +
      base64Encode(utf8.encode(
          '$studentNo:$password}'));
  return await http.get(DB_UFR_URL, headers: {'authorization': basicAuth});

}

Future<String> getHtmlFromDbUfr(Map<String, String> creditentials) async {
  String basicAuth = 'Basic ' +
      base64Encode(utf8.encode(
          '${creditentials[STUDENT_NO_KEY]}:${creditentials[PASSWORD_KEY]}'));
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
  return null;
}

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
            grade: double.parse(grade), max: double.parse(max), desc: desc));
      }
    }
  });
  uesObjects.sort((a, b) {
   DateFormat format = DateFormat('yyyy-MM-dd');
   DateTime aTime = format.parse('${a.year}-'+monthToNo(a.month)+'-01');
   DateTime bTime = format.parse('${b.year}-'+monthToNo(b.month)+'-01');
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
    try{
      desc = utf8.decode(Latin1Codec().encode(info[3].text));
    }catch(Exception){
      desc = info[3].text;
    }

    print(desc);
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
  print(truncatedMonth);

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
  DateTime aTime = format.parse('${a.year}-'+monthToNo(a.month)+'-01');
  DateTime bTime = format.parse('${b.year}-'+monthToNo(b.month)+'-01');
  return aTime.compareTo(bTime);
}

String monthToNo(String month) {
    month = month.toLowerCase();
    if(month == 'janvier') {
      return '01';
    }
    if(month == 'fevrier') {
      return '02';
    }
    if(month == 'mars') {
      return '03';
    }
    if(month == 'avril') {
      return '04';
    }
    if(month == 'mai') {
      return '05';
    }
    if(month == 'juin') {
      return '06';
    }
    if(month == 'juillet') {
      return '07';
    }
    if(month == 'aout') {
      return '08';
    }
    if(month == 'septembre') {
      return '09';
    }
    if(month == 'octobre') {
      return '10';
    }
    if(month == 'novembre') {
      return '11';
    }
    if(month == 'decembre') {
      return '12';
    }
    return '01';

}
