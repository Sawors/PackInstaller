/*import 'package:flutter/material.dart';*/
import 'package:flutter_app_test/modpack_installer/worker/pack_downloader.dart';

/*import 'dog_card.dart';
import 'dog_model.dart';*/

void main() {
  //runApp(const MyApp());
  ProfileManager.init();
  PackInstaller.downloadModpack(Uri.parse("https://github.com/Sawors/PackInstaller/raw/7275934d2325eb08ea531130917f7701eba14739/lib/modpack_installer/sample_modpack/sample_modpack.zip"));
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
