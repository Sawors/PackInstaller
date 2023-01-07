import 'package:flutter/material.dart';
import 'package:random_string/random_string.dart';

void main(List<String> args) {
  runApp(const MainApp());



  //
  // For the pack-updater backend
  /*
  ProfileManager.init();
  // tiboise : https://github.com/Sawors/1.16.5-Tiboise/archive/refs/heads/main.zip
  String dlLink = args.isNotEmpty ? args[0] : "https://github.com/Sawors/PackInstaller/raw/main/lib/modpack_installer/sample_modpack/sample_modpack.zip";
  //"C:\Users\sosol\AppData\Roaming\.minecraft\.profiles\Sample 1.16.5 2"
  //PackUpdater.getUpdateContent(Directory("C:\\Users\\sosol\\AppData\\Roaming\\.minecraft\\.profiles\\1.16.5-Tiboise-main"), Directory("C:\\Users\\sosol\\AppData\\Roaming\\.minecraft\\.profiles\\forge 1.16.5 base\\1.16.5-Tiboise"));
  const String root = "C:\\Users\\sosol\\AppData\\Roaming\\.minecraft\\.profiles";
  //PackUpdater.getUpdate(Directory("$root\\Sample 1.16.5"), Directory("$root\\Sample 1.16.5 2"));
  PackInstaller.setupModpack(Uri.parse(dlLink));
  */
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});
  static const String windowTitle = "Sawors Test";

  @override
  Widget build(BuildContext context){
    ThemeData theme = ThemeData.dark();

    return MaterialApp(
      title: MainApp.windowTitle,
      theme: theme,
      color: Colors.green,
      home: const HomePage(title: MainApp.windowTitle,),
    );
  }
}



class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.title});
  final String title;
  @override
  State<HomePage> createState() => _HomePageState();
}



class _HomePageState extends State<HomePage> {

  static final Color highlightColor = Colors.indigo.shade700;

  @override
  Widget build(BuildContext context) {
      return SafeArea(
          child: Scaffold(
              body: Center(
                  child: Card(
                    child: Stack(
                      children: [
                        Wrap(
                          direction: Axis.vertical,
                          clipBehavior: Clip.hardEdge,
                          children: [...generateCards(randomBetween(15, 30))],
                        )
                      ],
                    ),
                  ),
              )
          ),
      );
  }


  List<Card> generateCards(int amount) {
    List<Card> outputList = [];
    for(int i = 0; i<amount; i++){
      outputList.add(
        Card(
        color: highlightColor,
        child: Padding(
          padding: const EdgeInsetsDirectional.only(
              start: 12,
              end: 12,
              top: 6,
              bottom: 6
            ),
          child: Text(randomAlpha(randomBetween(6, 10))),
          ),
        ),
      );
    }


    return outputList;
  }
}
