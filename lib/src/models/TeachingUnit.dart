import 'package:dbufr_checker/src/models/Grade.dart';

class TeachingUnit {
  String group;
  String name;
  int year;
  String month;
  String desc;
  List<Grade> grades = new List<Grade>();

  TeachingUnit(this.group, this.name, this.year, this.month, this.desc);
}