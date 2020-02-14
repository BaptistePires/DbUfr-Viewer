import 'dart:core';
import 'dart:io';
import 'package:dbufr_checker/src/functions.dart';
import 'package:flutter/cupertino.dart';

const String DEFAULT_LANG = 'en';

class LangHandlerSingleton {


  Map<String, Image> langs = {
    'en': null,
    'fr': null
  };
  String currentLang = 'en';
  Map<String, dynamic> translations;
  static LangHandlerSingleton __instance;


  LangHandlerSingleton({this.currentLang = DEFAULT_LANG}) {
   this.langs.forEach((key, value) {
      this.langs[key] = Image(image: AssetImage('assets/imgs/flags/${key}.png'),);
   });
  }

  Image getCurrentFlag() => this.langs[this.currentLang];

  static Future<LangHandlerSingleton> getInstance([String langCode = DEFAULT_LANG]) async  {
    if(__instance == null) {
      __instance = LangHandlerSingleton(currentLang: langCode);
      await __instance.loadTranslations();
    }
    return __instance;
  }

  Future<void> loadTranslations() async {
    this.translations =  await loadLang(currentLang);

  }
  Future<void> nextLang() async{
    List<String> availableLangs = this.langs.keys.toList();
    int currentId = availableLangs.indexOf(this.currentLang);
    this.currentLang = availableLangs[(currentId + 1) % availableLangs.length];
    await loadTranslations();
  }

  List<String> getAvailableLangs() => this.langs.keys;

  String getTranslationFor(String name){
    if(translations.containsKey(name)) return translations[name];
    else return 'null';
  }



}