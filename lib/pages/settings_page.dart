import 'package:dbufr_checker/src/LangHandlerSingleton.dart';
import 'package:dbufr_checker/src/functions.dart';
import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage>
    with SingleTickerProviderStateMixin {
  LangHandlerSingleton langHandler;
  AnimationController _animationController;
  bool _loading = true;

  @override
  void initState() {
    super.initState();

    _animationController = new AnimationController(
        vsync: this, duration: Duration(milliseconds: 800));

    LangHandlerSingleton.getInstance().then(((o) {
      setState(() {
        this.langHandler = o;
        _loading = false;
      });
    }));
  }

  double v = 0;
  List<double> _linearGradient = [0.55, 0.50];

  @override
  Widget build(BuildContext context) {
    return !_loading
        ? Scaffold(
            appBar: _setUpAppbar(),
            body: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: getGradientFromList())
              ),
              child: ListView.builder(
                  itemCount: 1,
                  itemBuilder: (context, i) {
                    return new ExpansionTile(
                        title: Text(langHandler.getTranslationFor('colors')),
                        backgroundColor: Colors.white,

                        children: <Widget>[
                      Card(

//                        padding: EdgeInsets.all(20),
                        child: Container(
                          padding: EdgeInsets.all(20),
                          child: Column(
                            children: _setUpLinearGradientParameters(),
                          ),
                        ),
                      ),
                    ]);
                  }),
            ))
        : getLoadingScreen(_animationController);
  }

  List<Widget> _setUpLinearGradientParameters() {
    List<Widget> gradientParams = new List<Widget>();

    gradientParams.add(Text(
        langHandler.getTranslationFor('settings_background_gradient_params')));

    _linearGradient.asMap().forEach((i, element) {
      gradientParams.add(Slider(
        value: _linearGradient[i],
        min: 0,
        max: 360,
        onChanged: (v) {
          setState(() {
            _linearGradient[i] = v;
          });
        },
        label: _linearGradient[i].toString(),
      ));
    });
    gradientParams.add(Container(
      height: 100,
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
//        shape: RoundedRectangleBorder(
//          borderRadius: BorderRadius.circular(30),

          gradient: LinearGradient(
            colors: getGradientFromList(),
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          )),
    ));

    return gradientParams;
  }

  List<Color> getGradientFromList() => _linearGradient
      .map((e) => HSVColor.fromAHSV(1, e, 1, 1).toColor())
      .toList();

  AppBar _setUpAppbar() {
    return AppBar(
      title: Text(langHandler.getTranslationFor('settings')),
      centerTitle: true,
      elevation: 10,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
    );
  }
}
