import 'package:dbufr_checker/src/models/UserSettings.dart';

class UserArgsBundle {
  final String studentNo;
  final String password;
  final String htmlGrades;
  final UserSettings userSettings;
  UserArgsBundle(this.studentNo, this.password, this.userSettings,
      {this.htmlGrades});
}
