import 'dart:core';

class Grade {
  double grade;
  double max;
  String desc;
  Grade({this.grade, this.max, this.desc});

  Grade.fromJson(Map<String, dynamic> json)
      : grade = json['grade'],
        max = json['max'],
        desc = json['desc'];

  Map<String, dynamic> toJson() => {
    'grade': this.grade,
    'max': this.max,
    'desc': this.desc};

}
