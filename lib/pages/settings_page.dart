import 'package:dbufr_checker/src/LangHandlerSingleton.dart';
import 'package:dbufr_checker/src/functions.dart';
import 'package:dbufr_checker/src/models/UserSettings.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage>
    with SingleTickerProviderStateMixin {
  // FLAGS
  bool _loadingLang = true;
  bool _loadingSettings = true;
  bool _saving = false;

  // Buffer values
  List<double> tmpLinear;
  double tmpPrimaryColor;
  double _tmpTitleFontSize;
  double _tmpSubtitleFontSize;

  LangHandlerSingleton langHandler;
  AnimationController _animationController;

  UserSettings userSettings;

  @override
  void initState() {
    super.initState();

    _animationController = new AnimationController(
        vsync: this, duration: Duration(milliseconds: 800));

    LangHandlerSingleton.getInstance().then(((o) {
      setState(() {
        this.langHandler = o;
        _loadingLang = false;
      });
    }));
    loadUserSettings().then((userSettings) {
      setState(() {
        this.userSettings = userSettings;
        tmpLinear = List.from(userSettings.asMap[LINEAR_GRADIENT_NAME]);
        tmpPrimaryColor = userSettings.asMap[PRIMARY_COLOR_NAME];
        _tmpTitleFontSize = userSettings.titleFontSize;
        _tmpSubtitleFontSize = userSettings.subtitlesFontSize;
        print(userSettings.subtitlesFontSize);
        _loadingSettings = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
//    print('${userSettings.asMap[LINEAR_GRADIENT_NAME]} : $_loadingSettings');
    return !_loadingLang && !_loadingSettings
        ? Scaffold(
            appBar: _setUpAppbar(),
            backgroundColor: colorFromDouble(userSettings.linearBgColors[0]),
            body: Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                  gradient: LinearGradient(
                      colors: getGradientFromTmpColors(),
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter)
//                gradient: getLinearGradientBg(),
                  ),
              child: _buildListView(),
            ),
            bottomNavigationBar: _setUpBottomAppBar(),
          )
        : getLoadingScreen(_animationController);
  }

  List<Widget> _setUpLinearGradientParameters() {
    List<Widget> gradientParams = new List<Widget>();

    gradientParams.add(Text(
        langHandler.getTranslationFor('settings_background_gradient_params'),
        style:TextStyle(fontSize: _tmpTitleFontSize)), );

    gradientParams += _formatGradientParamsSliders();

    gradientParams.add(Container(
      width: 40,
      height: 40,
      padding: EdgeInsets.all(0),
      decoration: BoxDecoration(
          border: Border.all(
            width: 1,
            color: Colors.lightGreenAccent[700],
          ),
          borderRadius: BorderRadius.circular(30)),
      child: IconButton(
        icon: Icon(
          Icons.add,
          color: Colors.lightGreenAccent[700],
          size: 21,
        ),
        onPressed: () {
          setState(() {
            if (tmpLinear.length >= 10) {
              Scaffold.of(context).showSnackBar(setUpConnectDbUfrSnack(
                  langHandler.getTranslationFor('settings_no_more_colors')));
            } else {
              tmpLinear.add(tmpLinear[tmpLinear.length-1]);
            }
          });
        },
      ),
    ));
    gradientParams.add(SizedBox(
      height: 15,
    ));
    gradientParams.add(Container(
      height: 100,
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: getGradientFromTmpColors(),
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          )),
    ));
    gradientParams.add(SizedBox(
      height: 20,
    ));
    gradientParams.add(
        Text(langHandler.getTranslationFor('settings_primary_color_params'),
        style: TextStyle(
          fontSize: _tmpTitleFontSize
        ),));
    gradientParams += _setUpPrimaryColorParameters();


    return gradientParams;
  }

  List<Widget> _formatGradientParamsSliders() {
    List<Widget> gradientParams = List<Widget>();
    tmpLinear.asMap().forEach((i, element) {
      Color c = colorFromDouble(tmpLinear[i]);
      gradientParams.add(Row(
        children: <Widget>[
          Flexible(
            flex: 8,
            child: Slider(
              divisions: 360,
              value: tmpLinear[i],
              min: 0,
              max: 360,
              activeColor: c,
              onChanged: (v) {
                setState(() {
                  tmpLinear[i] = v;
                });
              },
              label: '#' + c.toString().substring(10, c.toString().length - 2),
            ),
          ),
          Flexible(
              flex: 1,
              child: OutlineButton(
                padding: EdgeInsets.all(0),
                onPressed: () {
                  if (tmpLinear.length > 2) {
                    setState(() {
                      tmpLinear.removeAt(i);
                    });
                  } else {
                    Scaffold.of(context).showSnackBar(setUpConnectDbUfrSnack(
                        langHandler
                            .getTranslationFor('settings_min_two_colors')));
                  }
                },
                child: Icon(
                  Icons.remove,
                  color: Colors.red,
                ),
                borderSide: BorderSide(color: Colors.red),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
              ))
        ],
      ));
    });
    return gradientParams;
  }

  List<Widget> _setUpPrimaryColorParameters() {
    List<Widget> widgets = new List<Widget>();

    widgets.add(Row(
      children: <Widget>[
        Flexible(
            flex: 8,
            child: Slider(
              value: tmpPrimaryColor,
              min: 0,
              max: 360,
              activeColor: colorFromDouble(tmpPrimaryColor),
              onChanged: (v) {
                setState(() {
                  tmpPrimaryColor = v;
                });
              },
            )),
        Flexible(
          flex: 2,
          child: Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorFromDouble(tmpPrimaryColor),
              )),
        )
      ],
    ));

    return widgets;
  }

  List<Color> getGradientFromTmpColors() =>
      tmpLinear.map((e) => HSVColor.fromAHSV(1, e, 1, 1).toColor()).toList();

  AppBar _setUpAppbar() {
    return AppBar(
      title: Text(langHandler.getTranslationFor('settings'),
      style: TextStyle(fontSize: _tmpTitleFontSize),),
      backgroundColor: colorFromDouble(tmpPrimaryColor),
      centerTitle: true,
      elevation: 10,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
    );
  }

  Widget _setUpSaveButton() {
    return OutlineButton(
      child: !_saving
          ? Text(langHandler.getTranslationFor("save"))
          : Container(
              margin: EdgeInsets.all(5),
              child: Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                ),
                widthFactor: 1,
              ),
            ),
      onPressed: () {
        if (_saving) return;
        setState(() {
          _saving = true;
          userSettings.linearBgColors = tmpLinear;
        });
        saveUserSettings(userSettings).then((value) {
          setState(() {
            _saving = false;
          });
        });
      },
    );
  }

  Widget _buildListView() {
    return ListView(
        scrollDirection: Axis.vertical,
        padding: EdgeInsets.all(5),
        children: <Widget>[
          Card(
            color: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(20))
            ),
            child: ExpansionTile(
              title: Text(langHandler.getTranslationFor('colors'),
                  style:TextStyle(fontSize: _tmpTitleFontSize,
                      color: colorFromDouble(tmpPrimaryColor))),
              children: <Widget>[
                Container(
                  padding: EdgeInsets.all(3),

                  decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(20)
                  ),
                  child:Card(
//                  elevation: 30,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(20))
                    ),
                    child: Container(
                      padding: EdgeInsets.all(20),
                      child: Column(
                        children: _setUpLinearGradientParameters(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Card(
            color: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(20))
            ),
            child: ExpansionTile(
              title: Text(langHandler.getTranslationFor('text'),
                  style:TextStyle(fontSize: _tmpTitleFontSize,
                      color: colorFromDouble(tmpPrimaryColor))),
              children: <Widget>[
                Container(
                  padding: EdgeInsets.all(3),

                  decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(20)
                  ),
                  child:Card(
//                  elevation: 30,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(20))
                    ),
                    child: Container(
                      padding: EdgeInsets.all(20),
                      child: Column(
                        children: _setUpTextParameters(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          )
        ]);
  }


  List<Widget> _setUpTextParameters() {
    List<Widget> txtParams = new List<Widget>();
    txtParams.add(
        Text(langHandler.getTranslationFor('settings_title_font_size'),
          style: TextStyle(
              fontSize: _tmpTitleFontSize
          ),)
    );
    txtParams.add(
      Slider(
        value: _tmpTitleFontSize,
        min: 15,
        max: 25,
        divisions: 10,
        label: _tmpTitleFontSize.toString(),
        onChanged: (v) {
          setState(() {
            _tmpTitleFontSize = v;
          });
        },
      )
    );

    txtParams.add(
        Text(langHandler.getTranslationFor('settings_subtitle_font_size'),
          style: TextStyle(
              fontSize: _tmpSubtitleFontSize
          ),)
    );
    txtParams.add(
        Slider(
          value: _tmpSubtitleFontSize,
          min: 10,
          max: 20,
          divisions: 10,
          label: _tmpSubtitleFontSize.toString(),
          onChanged: (v) {
            setState(() {
              _tmpSubtitleFontSize= v;
            });
          },
        )
    );

    return txtParams;
  }

  Widget _setUpBottomAppBar() {
    return BottomNavigationBar(
      backgroundColor: colorFromDouble(tmpLinear[tmpLinear.length-1]),
      selectedLabelStyle: TextStyle(color: Colors.black, fontSize: 14),
      unselectedFontSize: 14,

      onTap: (i) {
        if(i==0){
          setState(() {
            tmpLinear = List.from(userSettings.asMap[LINEAR_GRADIENT_NAME]);
            tmpPrimaryColor = userSettings.asMap[PRIMARY_COLOR_NAME];
          });
        }else if(i==1){
          setState(() {
            userSettings.linearBgColors = tmpLinear;
            userSettings.primaryColor = tmpPrimaryColor;
          });


          saveUserSettings(userSettings);

        }
      },

      items: [
        BottomNavigationBarItem(
          icon: Icon(
            Icons.undo,
            color: Colors.black,
          ),
          title: Text(
            langHandler.getTranslationFor("reset"),
            style: TextStyle(color: Colors.black, fontSize: 14),
          ),
          activeIcon: Icon(
            Icons.undo,
            color: Colors.black,
          ),
        ),
        BottomNavigationBarItem(
          icon: Icon(
            Icons.file_download,
            color: Colors.black,
          ),
          activeIcon: Icon(
            Icons.file_download,
            color: Colors.black,
          ),
          title: Text(
            langHandler.getTranslationFor("save"),
            style: TextStyle(color: Colors.black, fontSize: 14),
          ),
        )
      ],
    );
  }
}
