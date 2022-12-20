
import 'dart:convert';
import 'dart:io';
import 'dart:math';

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
  static final Directory profileCollectionRoot = Directory(gameRootPath+_pathSeparator+_profilesSubfolder);

  static void init(){
    // Ensures that the game directory is effectively found
    // (it should never fire but it is a safety check).
    if(gameRootPath == null) throw FileSystemException("The Minecraft root directory has not been found on your OS", gameRootPath);

    // Casting as String just for safety (this should cast from String? to String).
    try{
      ProfileManager.profileCollectionRoot.createSync();
    } catch (e){
      print(e);
    }

    _profileCollectionRoot = loadLauncherProfiles(_launcherProfiles.path);
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
  static Map<String, dynamic> loadLauncherProfiles(String path) {
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

  ProfileData({this.name = "New Profile", this.profilePicture = "Crafting_Table", this.versionId = "latest-release", this.ramAmount = 4}){
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

class ModPackData {

}

class PackInstaller {
  // The idea of this pack installer is not to be used as a regular way to download
  // modpacks from the internet but more like a tool to keep certain modpacks
  // for certain servers up to date.

  Future<ModPackData> downloadModpack(Uri source, Directory targetProfile) async {

    String downloadId = const Uuid().v1();

    final request = await HttpClient().getUrl(source);
    final response = await request.close();
    final String separator = Platform.pathSeparator;
    response.pipe(File("${targetProfile.path}${separator}temp-downloads$separator$downloadId").openWrite());

    return ModPackData();
  }

}