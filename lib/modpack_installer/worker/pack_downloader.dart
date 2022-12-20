
import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:uuid/uuid.dart';

abstract class ProfileManager {
  static final String _pathSeparator = Platform.pathSeparator;
  static dynamic gameRootPath = "${Platform.environment['UserProfile'] ?? Platform.environment['HOME']}${_pathSeparator}AppData${_pathSeparator}Roaming$_pathSeparator.minecraft";
  static const String _launcherProfileFileName = "launcher_profiles.json";
  static Map<String, dynamic> _profileCollection = {};
  static Map<String, dynamic> _profileCollectionRoot = {};
  static const String _profilesSubfolder = ".profiles";

  static final Directory _root = Directory(gameRootPath as String);
  static final File _launcherProfiles = File(_root.path+_pathSeparator+_launcherProfileFileName);
  static final Directory profileCollectionRootDirectory = Directory(gameRootPath+_pathSeparator+_profilesSubfolder);

  static void init(){
    // Ensures that the game directory is effectively found
    // (it should never fire but it is a safety check).
    if(gameRootPath == null) throw FileSystemException("The Minecraft root directory has not been found on your OS", gameRootPath);

    // Casting as String just for safety (this should cast from String? to String).
    try{
      ProfileManager.profileCollectionRootDirectory.createSync();
    } catch (e){
      print(e);
    }

    _profileCollectionRoot = readJsonFile(_launcherProfiles.path);
    _profileCollection = _profileCollectionRoot['profiles'];

    print("Successfully fetched profile data : ${_profileCollection.values.length} profiles found");
  }

  Future<void> _saveProfile(ProfileData data) async {
    _profileCollection[data.name] = data.getSerializableFormat();
    _profileCollectionRoot['profiles'] = _profileCollection;
    String output = jsonEncode(_profileCollectionRoot);
    await File(_launcherProfiles.path).copy(_launcherProfiles.path.replaceAll(".json", "_SMD_backup.json"));
    await _launcherProfiles.writeAsString(output, mode: FileMode.write);
  }

  // Better to be synced since all remaining work will be done on this data structure
  static Map<String, dynamic> readJsonFile(String path) {
    if(!path.toLowerCase().endsWith(".json")) throw const FormatException("The file provided should be a json file !");
    if(!File(path).existsSync()) throw FileSystemException("Profile file not found !", path);
    String source = File(path).readAsStringSync(encoding: utf8);
    Map<String, dynamic> output = {};
    try{
      output = jsonDecode(source);
    } catch (e){
      print(e);
    }
    return output;
  }

}

class ProfileData {
  String name;
  String profilePicture;
  String versionId;
  int ramAmount;
  late Directory profileDirectory;

  // constants
  static const String profileType = "custom";
  final String created = DateTime.now().toIso8601String();

  ProfileData(
      {
        this.name = "New Profile",
        this.profilePicture = "Crafting_Table",
        this.versionId = "latest-release",
        this.ramAmount = 4
      }) {

    profileDirectory = Directory(ProfileManager._profilesSubfolder+Platform.pathSeparator+name);
  }


  Map<String, String> getSerializableFormat(){
    Map<String, String> output = {};
    output["created"] = created;
    output["gameDir"] = profileDirectory.path.replaceAll(Platform.pathSeparator, "${Platform.pathSeparator}${Platform.pathSeparator}");
    output["icon"] = profilePicture;
    output["javaArgs"] = "-Xmx{$ramAmount}G -XX:+UnlockExperimentalVMOptions -XX:+UseG1GC -XX:G1NewSizePercent=20 -XX:G1ReservePercent=20 -XX:MaxGCPauseMillis=50 -XX:G1HeapRegionSize=32M";
    output["lastUsed"] = created;
    output["lastVersionId"] = versionId;
    output["name"] = name;
    output["type"] = profileType;

    return output;
  }
}

enum ModLoader {
  forge, fabric, vanilla
}

class ModpackData {
  String name;
  String mcVersion;
  ModLoader loader;
  String loaderVersion;
  String miniature;
  String headline;
  String description;
  String packVersion;
  Uri? source;
  Uri? discord;
  String server;
  String author;
  int ram;

  ModpackData({
          this.name = "Unnamed",
          this.mcVersion = "1.12.2",
          this.loader = ModLoader.forge,
          this.loaderVersion = "14.23.5.2859",
          this.miniature = "pack.png",
          this.headline = "An unknown modpack",
          this.description = "Unknown modpack, tell the author to describe it",
          this.packVersion = "0.0",
          this.source,
          this.discord,
          this.server = "",
          this.author = "Unknown",
          this.ram = 0
        });

  String getProfileName(){
    return "$name $mcVersion";
  }
}

enum ModpackManifestField {
  name("name"),
  minecraftVersion("minecraft-version"),
  modLoader("modloader"),
  modLoaderVersion("modloader-version"),
  miniature("miniature"),
  headline("headline"),
  description("description"),
  modpackVersion("modpack-version"),
  source("source"),
  discord("discord"),
  serverIp("server"),
  authorName("author"),
  ram("suggested-ram-amount")
  ;

  final String serializableName;
  const ModpackManifestField(this.serializableName);
}

class PackInstaller {
  // The idea of this pack installer is not to be used as a regular way to download
  // modpacks from the internet but more like a tool to keep certain modpacks
  // for certain servers up to date.

  static const String messageSpacer = "    ";

  static void setupModpack(Uri source) async{
    // download the zip file
    print("-> Downloading modpack...");
    File modpackArchive = await _downloadModpack(source);
    print("-> Downloaded modpack !");
    // reads the manifest and unpacks the zip file to the (generated) profile directory
    print("-> Installing modpack...");
    ModpackData modpackData = await _installModpack(modpackArchive);
    print("-> Installed modpack !");
    // checks if the modloader version is present
    print("-> Searching versions...");
    String versionName = await _checkLauncherGameVersion(modpackData);
    print("-> Version search finished !");
    print("-> Generating profile...");
    List<int> imageData = [];
    int ram = 4;
    int systemRam = 34359738368 ~/ (1024*1024*1024);

    if(modpackData.ram > 0){
      // using suggested ram
      print("${messageSpacer}Using suggested ram amount for profile");
      ram = modpackData.ram;
      if(ram > systemRam*0.75){
        print("${messageSpacer}WARNING : You have less RAM than the suggested amount for this modpack (${systemRam}G is to few, suggested is ${ram}G)");
      }
    } else {
      print("${messageSpacer}Using automatic ram for profile");
      // using auto ram
      if(systemRam < 4){
        //TODO : add error handling
        print("${messageSpacer}ERROR : system has not enough RAM (${systemRam}G is to few)");
      } else if (systemRam <= 8){
        ram = 4;
      } else if (systemRam <= 16){
        ram = 8;
      } else if (systemRam > 16){
        ram = 10;
      }
    }

    ProfileData profile = ProfileData(
      name: modpackData.getProfileName(),
      profilePicture: base64Encode(imageData),
      versionId: versionName,
      ramAmount: ram
    );
    print("${messageSpacer}Profile name : ${profile.name}");
    print("${messageSpacer}Profile version : ${profile.versionId}");
    print("${messageSpacer}Profile RAM : ${profile.ramAmount}G");

    print("-> Profile generated !");
  }

  static Future<File> _downloadModpack(Uri source) async {
    // https://github.com/Sawors/PackInstaller/blob/7275934d2325eb08ea531130917f7701eba14739/lib/modpack_installer/sample_modpack/sample_modpack.zip
    final String separator = Platform.pathSeparator;
    String downloadId = const Uuid().v1();

    final request = await HttpClient().getUrl(source);
    final response = await request.close();

    final Directory downloadTarget = Directory("${Directory.systemTemp.path}${separator}sawors_modpack_installer");
    final File target = File("${downloadTarget.path}$separator$downloadId.zip");
    try{
      await target.create(recursive: true);
    } catch (e){
      print(e);
    }

    await response.pipe(target.openWrite());
    return target;
  }

  static Future<ModpackData> _installModpack(File modpackArchive) async {

    const String manifestFileName = "modpack.json";

    final String separator = Platform.pathSeparator;
    final Directory target = Directory(modpackArchive.parent.path+separator+_getFileName(modpackArchive));
    final InputFileStream input = InputFileStream(modpackArchive.path);
    final archive = ZipDecoder().decodeBuffer(input);
    for (var file in archive.files) {
      // If it's a file and not a directory
      if (file.isFile && file.name == manifestFileName) {
        final outputStream = OutputFileStream('${target.path}$separator${file.name}');
        file.writeContent(outputStream);
        outputStream.close();
      }
    }

    File manifest = File(target.path+separator+manifestFileName);

    Map<String, dynamic> packDataMap = ProfileManager.readJsonFile(manifest.path);

    ModpackData data = ModpackData(
      name: packDataMap[ModpackManifestField.name.serializableName] ?? "Unnamed",
      mcVersion: packDataMap[ModpackManifestField.minecraftVersion.serializableName] ?? "1.12.2",
      loader: ModLoader.values.firstWhere((element) => element.name == (packDataMap[ModpackManifestField.modLoader.serializableName] ?? "vanilla"), orElse: () => ModLoader.vanilla),
      loaderVersion: packDataMap[ModpackManifestField.modLoaderVersion.serializableName] ?? "",
      miniature: packDataMap[ModpackManifestField.miniature.serializableName] ?? "pack.png",
      headline: packDataMap[ModpackManifestField.headline.serializableName] ?? "An unknown modpack",
      description: packDataMap[ModpackManifestField.description.serializableName] ?? "Unknown modpack, tell the author to describe it",
      packVersion: packDataMap[ModpackManifestField.modpackVersion.serializableName] ?? "0.0",
      source: Uri.tryParse(packDataMap[ModpackManifestField.source.serializableName] ?? ""),
      discord: Uri.tryParse(packDataMap[ModpackManifestField.discord.serializableName] ?? ""),
      server: packDataMap[ModpackManifestField.serverIp.serializableName] ?? "",
      author: packDataMap[ModpackManifestField.authorName.serializableName] ?? "Unknown",
      ram: packDataMap[ModpackManifestField.ram.serializableName] ?? 0
    );

    String profileName = "${data.name} ${data.mcVersion}";
    Directory profileDirectory = Directory(ProfileManager.profileCollectionRootDirectory.path+separator+profileName);
    try{
      profileDirectory.create();
    } catch (e){
      print(e);
    }


    for (var file in archive.files) {
      if (file.isFile) {
        final outputStream = OutputFileStream('${profileDirectory.path}$separator${file.name}');
        file.writeContent(outputStream);
        outputStream.close();
      }
    }
    input.close();
    modpackArchive.delete();
    target.delete(recursive: true);

    return data;
  }

  static Future<String> _checkLauncherGameVersion(ModpackData reference) async {
    Stream<FileSystemEntity> versions = Directory("${ProfileManager._root.path}${Platform.pathSeparator}versions").list(recursive: false, followLinks: false);
    List<String> possibleVersions = [];

    String exactMatch = "";
    await versions.forEach((element) {
      List<String> pathParts = element.path.split(Platform.pathSeparator);
      String dirName = (pathParts[pathParts.length-1]);
      if(dirName.toLowerCase().contains(reference.mcVersion) && dirName.toLowerCase().contains(reference.loader.name)){
        possibleVersions.add(dirName);
        if(dirName.toLowerCase().contains(reference.loaderVersion)){
          exactMatch = dirName;
        }
      }
    });
    final String errorMessage = "No matching game version found, download the correct version at : "
        "${getModLoaderDownloadLink(reference.loader, reference.mcVersion, reference.loaderVersion)} ";
    if(exactMatch.isNotEmpty){
      print("${messageSpacer}Version $exactMatch found !");
    } else if(possibleVersions.isNotEmpty){
      String versionListPrint = "";
      for (var element in possibleVersions) {versionListPrint += "\n  $element";}
      print("$messageSpacer$errorMessage"
          "\nor use one of the following at your own risk : $versionListPrint");
    } else {
      print("$messageSpacer$errorMessage");
    }

    return exactMatch;
  }

  static Future<ProfileData> _generateProfile(ModpackData sourceData) async {



    return ProfileData();
  }

  static String _getFileName(File file) {
    final List<String> path = file.path.split(Platform.pathSeparator);
    final String name = path[path.length-1];
    return name.substring(0,name.indexOf("."));
  }

  static Uri? getModLoaderDownloadLink(ModLoader loader, String gameVersion, String loaderVersion){
    String source = "";
    switch(loader){
      case ModLoader.forge:
        String identifier = "$gameVersion-$loaderVersion";
        source = "https://maven.minecraftforge.net/net/minecraftforge/forge/$identifier/forge-$identifier-installer.jar";
        break;
      case ModLoader.fabric:
        source = "https://maven.fabricmc.net/net/fabricmc/fabric-installer/$loaderVersion/fabric-installer-$loaderVersion.jar";
        break;
        break;
      case ModLoader.vanilla:
        return null;
    }
    return Uri.tryParse(source);
  }

}