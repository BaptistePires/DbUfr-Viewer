import 'package:dbufr_checker/src/CrendentialsArgument.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../src/functions.dart';
import '../src/exceptions/Exceptions.dart';

class LoginPage extends StatefulWidget {
  static String tag = 'login-page';

  @override
  _LoginPageState createState() => new _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();

  // Flags
  bool _connecting = false;
  bool _doRememberMe = false;
  bool _connectError = false;
  bool _credentialsError = false;
  bool _obscureText = true;
  bool _connected = false;
  bool _firstOpening = true;

  // Fields controllers
  final studentNoController = TextEditingController();
  final passwordController = TextEditingController();


  @override
  Widget build(BuildContext context) {
    if (_firstOpening) checkIfLogged();
    return new Scaffold(
        body: Container(
          decoration: BoxDecoration(
              gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.lightBlue[400],
                    Colors.lightBlue,
                    Colors.lightBlue[600],
                    Colors.lightBlue[700],
                    Colors.lightBlue[800],
                  ])),
          child: Center(
            child: ListView(
              shrinkWrap: true,
              padding: EdgeInsets.only(left: 24, right: 24),
              children: <Widget>[
                _setUpLogo(),
                SizedBox(
                  height: 30,
                ),
                Container(
                  padding: EdgeInsets.fromLTRB(20, 30, 20, 20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.black, width: 1),
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(color: Colors.lightBlue[900], blurRadius: 10)
                    ],
                  ),
                  child: Column(
                    children: <Widget>[
                      Text(
                        'Connexion',
                        style: TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 25,
                            fontWeight: FontWeight.bold),
                      ),
                      SizedBox(
                        height: 30,
                      ),
                      _setUpForm(),
                    ],
                  ),
                )
              ],
            ),
          ),
        ));
  }

  void checkIfLogged() async {
    /*
      Method called when the app is opened.
      If user's credentials are already saved, create next route
      and delete this one.
     */
    _firstOpening = false;
    // Check in SharedPreferences
    bool logged = await isLogged();
    if (logged) {
      Map<String, String> credentials = await getCredentials();

      CredentialsArgument args = CredentialsArgument(
          credentials[STUDENT_NO_KEY], credentials[PASSWORD_KEY]);

      Navigator.of(context).pushNamedAndRemoveUntil(
          '/grades', (Route<dynamic> route) => false,
          arguments: args);
    }
  }

  void login() async {
    /*
      Method used to login.
     */
    // Updating UI
    if (_formKey.currentState.validate()) {
      setState(() {
        _connecting = _connecting ? false : true;
      });
    } else {
      return;
    }
    // Querying DbUfr to get user data
    String studentNo = studentNoController.text;
    String password = passwordController.text;

    try{
      http.Response response = await queryToDbUfr(studentNo, password);
      setState(() {
        resetFlags();
        if (response.statusCode != 200) {
          if (response.statusCode == 401) {
            _credentialsError = true;
          } else {
            _connectError = true;
          }

        }else{
          _connected = true;
        }

      });
      if(_credentialsError || _connectError){
        return;
      }
        // Do we save user credentials
        if (_doRememberMe) {
          await saveCredentials(studentNo, password);
        }

        // Go to next route and delete this one
        CredentialsArgument args = new CredentialsArgument(
            studentNo, password, htmlGrades: response.body);
        Navigator.pushNamedAndRemoveUntil(
            context, '/grades', (Route<dynamic> route) => false, arguments: args);


    }catch(Exception) {
      setState(() {
        resetFlags();
        _connectError = true;
      });
    }
  }

  void resetFlags() {
     _connecting = false;
    _connectError = false;
    _credentialsError = false;
    _obscureText = true;
    _connected = false;
  }

  /* ***************************
 * Widgets formating functions *
 *******************************/
  void _showRememberMeDialog() {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Informations'),
            content: Text(
                'La fonction \'Rester connecté\' peut présenter des risques si vous perdez votre téléphone.'),
            actions: <Widget>[
              FlatButton(
                child: Text('D\'accord'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              )
            ],
          );
        });
  }

  Image _setUpLogo() {
    return  Image(
      image: AssetImage('assets/imgs/logo.png'),
    );
  }

  Form _setUpForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: <Widget>[
          _setUpStudentNoField(),
          SizedBox(
            height: 20,
          ),
          _setUpPasswordField(),
          SizedBox(
            height: 5,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              IconButton(
                icon: Icon(Icons.info),
                onPressed: () {
                  _showRememberMeDialog();
                },
                iconSize: 19,
              ),
              Text('Rester connecté'),
              _setUpRememberMe(),
            ],
          ),
          SizedBox(
            height: 20,
          ),
          _setUpLoginBtn(),
          Text(
            _credentialsError ?'Numéro étudiant ou mot de passe incorect' :
            'Erreur lors de la requête à DbUfr.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _connectError || _credentialsError? Colors.red : Colors.white,
            ),
          )
        ],
      ),
    );
  }

  TextFormField _setUpStudentNoField() {
      return TextFormField(
      keyboardType: TextInputType.number,
      autofocus: false,
      decoration: InputDecoration(
        hintText: 'N° étudiant',
        contentPadding: EdgeInsets.fromLTRB(20, 10, 20, 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(32.0),
          borderSide: BorderSide(color: Colors.blue),
        ),
      ),
      controller: studentNoController,
      enabled: _connecting ? false : true,
      validator: (value) {
        if (value.isEmpty) return 'Indiquez votre numéro d\'étudiant';
        return null;
      },
    );
  }

  TextFormField _setUpPasswordField() {
    return TextFormField(
      autofocus: false,
      obscureText: _obscureText,
      decoration: InputDecoration(
        hintText: 'Mot de passe',
        contentPadding: EdgeInsets.fromLTRB(20, 10, 20, 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(32.0),
          borderSide: BorderSide(color: Colors.blue),
        ),
        suffixIcon: IconButton(
          onPressed: () {
            setState(() {
              _obscureText = _obscureText ? false : true;
            });
          },
          icon: Icon(Icons.remove_red_eye),
        ),
      ),
      controller: passwordController,
      enabled: _connecting ? false : true,
      validator: (value) {
        if (value.isEmpty) return 'Indiquez votre mot de passe';
        return null;
      },
    );
  }

  Checkbox _setUpRememberMe() {
    return Checkbox(
      value: _doRememberMe,
      onChanged: (state) {
        setState(() {
          _doRememberMe = state;
        });
      },
    );
  }

  Padding _setUpLoginBtn() {
      return  Padding(
      padding: EdgeInsets.symmetric(
        vertical: 16,
      ),
      child: OutlineButton(
        onPressed: _connecting
            ? null
            : () {
          login();
        },
        child: _connecting
            ? _connected
            ? Container(
          margin: EdgeInsets.all(5),
          child: Center(
            child: Icon(Icons.done),
            widthFactor: 1,
          ),
        )
            : Container(
          margin: EdgeInsets.all(5),
          child: Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
            ),
            widthFactor: 1,
          ),
        )
            : Text('Se connecter'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        borderSide: BorderSide(color: Colors.blue),
      ),
    );
  }
}
