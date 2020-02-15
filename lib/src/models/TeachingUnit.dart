import 'dart:convert';

import 'package:dbufr_checker/src/models/Grade.dart';

class TeachingUnit {
  String group;
  String name;
  int year;
  String month;
  String desc;
  List<Grade> grades = new List<Grade>();

  TeachingUnit(this.group, this.name, this.year, this.month, this.desc);

  TeachingUnit.fromJson(Map<String, dynamic> jsonTu)
      : group = jsonTu['group'],
        name = jsonTu['name'],
        year = jsonTu['year'],
        month = jsonTu['month'],
        desc = jsonTu['desc'],
        grades = jsonTu['grades'].length > 0
            ? jsonTu['grades']
                .asMap((o) => Grade.fromJson(o))
                .toList()
                .cast<Grade>()
            : new List<Grade>();

  Map toJson() => {
        'group': this.group,
        'name': this.name,
        'year': this.year,
        'month': this.month,
        'desc': this.desc,
        'grades': this.grades.map((g) => g.toJson()).toList()
      };
}
