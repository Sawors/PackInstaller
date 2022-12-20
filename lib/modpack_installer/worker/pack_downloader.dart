
import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
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
  forge, fabric, quilt, vanilla
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
          this.author = "Unknown"
        });
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
  authorName("author")
  ;

  final String serializableName;
  const ModpackManifestField(this.serializableName);
}

class PackInstaller {
  // The idea of this pack installer is not to be used as a regular way to download
  // modpacks from the internet but more like a tool to keep certain modpacks
  // for certain servers up to date.

  static Future<ModpackData> downloadModpack(Uri source) async {
    // https://github.com/Sawors/PackInstaller/blob/7275934d2325eb08ea531130917f7701eba14739/lib/modpack_installer/sample_modpack/sample_modpack.zip
    final String separator = Platform.pathSeparator;
    String downloadId = const Uuid().v1();

    print(source);

    final request = await HttpClient().getUrl(source);
    final response = await request.close();

    final Directory downloadTarget = Directory("${Directory.systemTemp.path}${separator}sawors_modpack_installer");
    final File target = File("${downloadTarget.path}$separator$downloadId.zip");
    try{
      await target.create(recursive: true);
    } catch (e){
      print(e);
    }

    ModpackData data = ModpackData();

    await response.pipe(target.openWrite());

    data = await _installModpack(target);
    print(data.name);
    print(data.mcVersion);
    print(data.loader);
    print(data.loaderVersion);
    print(data.miniature);
    print(data.headline);
    print(data.description);
    print(data.packVersion);
    print(data.source);
    print(data.discord);
    print(data.server);
    print(data.author);
    return data;
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
      loader: ModLoader.values.firstWhere((element) => element.toString() == (packDataMap[ModpackManifestField.modLoader.serializableName] ?? "vanilla"), orElse: () => ModLoader.vanilla),
      loaderVersion: packDataMap[ModpackManifestField.modLoaderVersion.serializableName] ?? "14.23.5.2859",
      miniature: packDataMap[ModpackManifestField.miniature.serializableName] ?? "pack.png",
      headline: packDataMap[ModpackManifestField.headline.serializableName] ?? "An unknown modpack",
      description: packDataMap[ModpackManifestField.description.serializableName] ?? "Unknown modpack, tell the author to describe it",
      packVersion: packDataMap[ModpackManifestField.modpackVersion.serializableName] ?? "0.0",
      source: Uri.tryParse(packDataMap[ModpackManifestField.source.serializableName] ?? ""),
      discord: Uri.tryParse(packDataMap[ModpackManifestField.discord.serializableName] ?? ""),
      server: packDataMap[ModpackManifestField.serverIp.serializableName] ?? "",
      author: packDataMap[ModpackManifestField.authorName.serializableName] ?? "Unknown",
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

  static String _getFileName(File file) {
    final List<String> path = file.path.split(Platform.pathSeparator);
    final String name = path[path.length-1];
    return name.substring(0,name.indexOf("."));
  }

}