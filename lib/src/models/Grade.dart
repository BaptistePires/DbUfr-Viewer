import 'dart:core';

class Grade {
  double grade;
  double max;
  String desc;
  bool viewed;
  bool newGrade = false;
  Grade(this.grade, this.max, this.desc, {this.viewed = false, this.newGrade = false});



  Grade.fromJson(Map<String, dynamic> json)
      : grade = json['grade'],
        max = json['max'],
        desc = json['desc'],
        viewed = json['viewed'],
        newGrade = false;

  Map<String, dynamic> toJson() => {
        'grade': this.grade,
        'max': this.max,
        'desc': this.desc,
        'viewed': this.viewed
      };

  bool operator ==(o) => o is Grade && this.grade == o.grade && this.max == o.max && this.desc == o.desc;

  int get hashCode => grade.round() + max.round() + desc.length % 12;
  }

