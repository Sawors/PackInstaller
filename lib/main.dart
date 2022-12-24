/*import 'package:flutter/material.dart';*/
import 'dart:io';

import 'package:flutter_app_test/modpack_installer/worker/pack_downloader.dart';

/*import 'dog_card.dart';
import 'dog_model.dart';*/

void main(List<String> args) {
  //runApp(const MyApp());
  ProfileManager.init();
  // tiboise : https://github.com/Sawors/1.16.5-Tiboise/archive/refs/heads/main.zip
  String dlLink = args.isNotEmpty ? args[0] : "https://github.com/Sawors/PackInstaller/raw/main/lib/modpack_installer/sample_modpack/sample_modpack.zip";
  //"C:\Users\sosol\AppData\Roaming\.minecraft\.profiles\Sample 1.16.5 2"
  //PackUpdater.getUpdateContent(Directory("C:\\Users\\sosol\\AppData\\Roaming\\.minecraft\\.profiles\\1.16.5-Tiboise-main"), Directory("C:\\Users\\sosol\\AppData\\Roaming\\.minecraft\\.profiles\\forge 1.16.5 base\\1.16.5-Tiboise"));
  PackUpdater.getUpdate(Directory("C:\\Users\\sosol\\AppData\\Roaming\\.minecraft\\.profiles\\Sample 1.16.5"), Directory("C:\\Users\\sosol\\AppData\\Roaming\\.minecraft\\.profiles\\Sample 1.16.5 2"));
  //PackInstaller.setupModpack(Uri.parse(dlLink));
}



/*
class MyApp extends StatelessWidget {
  const MyApp({super.key});
  static const String title = "We Rate Dogs";

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: title,
      theme: ThemeData(
        brightness: Brightness.dark
      ),
      home: const MyHomePage(title: title),
    );
  }
}



class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}



class _MyHomePageState extends State<MyHomePage> {
  List<Dog> initialDogs = [
    Dog("Ruby", "Geneva, GE, Switzerland", "Ruby is a very good doggo, a bit annoying tho"),
    Dog("Rex", "Sion, VS, Switzerland", "Absolute killer, has one time almost caught a legless rabbit"),
    Dog("Rod", "Lausanne, VD, Switzerland", "Very good dog. Likes to eat Vacherin and drink a lot of undrinkable wine"),
    Dog("Bob", "Payerne, VD, Switzerland", "Bob is my dog, and my dog is Bob. I like my dog like I like my life. Bob4tw"),
    Dog("Donkey", "Zurich, ZH, Switzerland", "Absolute idiot"),
    Dog("Doug", "Paradise Falls, ??, Somewhere in South America", "Very talkative, no really, this dog can talk. Despite his adorable face this filthy bastard can commit the worst treason"),
    Dog("Bonker", "Austin, TX, United-States", "Bonker is lit !!!!!!! :fire: :fire: :fire: Gigachad :stone_face: :stone_face: :gorilla: :gorilla:")
  ]







  ;


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        child: DogCard(initialDogs[1]),
      )
    );
  }
}
*/
