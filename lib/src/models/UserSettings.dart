const String LINEAR_GRADIENT_NAME = 'linearBgColors';
const String PRIMARY_COLOR_NAME = 'primaryColor';
const String TITLE_FONT_SIZE = 'titleFontSize';
const String SUBTITLE_FONT_SIZE = 'subtitleFontSize';
const String FONT_NAME = 'fontName';
const List<double> DEFAULT_GRADIENT = [
  360 * .5558,
  360 * .5638,
  360 * .5829,
  360 * .5887
];
const double DEFAULT_PRIMARY_COLOR = 206.568;
const double DEFAULT_TITLE_FONT_SIZE = 20;
const double DEFAULT_SUBTITLE_FONT_SIZE = 15;
const String DEFAULT_FONT_NAME = 'montserrat';

class UserSettings {
  /// [linearBgColors] Must contains double from 0 to 360. Will be used
  /// to generate colors based on HSV.
  List<double> linearBgColors;

  /// [primaryColor] Must be a double from 0 to 360. Will be used to generate
  /// color based on HSV
  double primaryColor;

  /// [titleFontSize] Font size for titles. Must be between 20 & 30
  double titleFontSize;

  /// [subtitleFontSize] Font size for subtitles and texts. Must be between 15
  /// & 25
  double subtitlesFontSize;

  String fontName;

  UserSettings(
      {this.linearBgColors = DEFAULT_GRADIENT,
      this.primaryColor = DEFAULT_PRIMARY_COLOR,
      this.titleFontSize = DEFAULT_TITLE_FONT_SIZE,
      this.subtitlesFontSize = DEFAULT_SUBTITLE_FONT_SIZE,
      this.fontName = DEFAULT_FONT_NAME});

  Map<String, dynamic> get asMap {
    return {
      LINEAR_GRADIENT_NAME: linearBgColors,
      PRIMARY_COLOR_NAME: primaryColor,
      TITLE_FONT_SIZE: titleFontSize,
      SUBTITLE_FONT_SIZE: subtitlesFontSize,
      FONT_NAME: fontName
    };
  }

  static UserSettings fromMap(Map<String, dynamic> mappedSettings) {
    return UserSettings(
        linearBgColors: mappedSettings[LINEAR_GRADIENT_NAME].cast<double>(),
        primaryColor: mappedSettings[PRIMARY_COLOR_NAME],
        titleFontSize: mappedSettings[TITLE_FONT_SIZE],
        subtitlesFontSize: mappedSettings[SUBTITLE_FONT_SIZE],
        fontName: mappedSettings[FONT_NAME]);
  }

  void setLinearColorById(int id, double v) {
    assert(v >= 0 && v <= 360);
    assert(id >= 0 && id < linearBgColors.length);
    linearBgColors[id] = v;
  }

  UserSettings copy() => new UserSettings(
      linearBgColors: this.linearBgColors,
      primaryColor: this.primaryColor,
      titleFontSize: this.titleFontSize,
      subtitlesFontSize: this.subtitlesFontSize,
      fontName: this.fontName);

  static List<UserSettings> getTemplates() {
    return [
      UserSettings(
          linearBgColors: [276.0, 251.99999999999997],
          primaryColor: 270.6443914081144,
          titleFontSize: 20.0,
          subtitlesFontSize: 16.0,
          fontName: 'tomorrow')
    ];
  }
}
