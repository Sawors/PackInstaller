
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:archive/archive_io.dart';
import 'package:intl/intl.dart';
import 'package:io/io.dart';
import 'package:uuid/uuid.dart';


const String messageSpacer = "    ";
final String separator = Platform.pathSeparator;

abstract class ProfileManager {
  static dynamic gameRootPath = "${Platform.environment['UserProfile'] ?? Platform.environment['HOME']}${separator}AppData${separator}Roaming$separator.minecraft";
  static const String _launcherProfileFileName = "launcher_profiles.json";
  static Map<String, dynamic> _profileCollection = {};
  static Map<String, dynamic> _profileCollectionRoot = {};
  static const String _profilesSubfolder = ".profiles";

  static final Directory _root = Directory(gameRootPath as String);
  static final File _launcherProfiles = File(_root.path+separator+_launcherProfileFileName);
  static final Directory profileCollectionRootDirectory = Directory(gameRootPath+separator+_profilesSubfolder);

  static void init(){
    // Ensures that the game directory is effectively found
    // (it should never fire but it is a safety check).
    if(gameRootPath == null) throw FileSystemException("The Minecraft root directory has not been found on your OS", gameRootPath);

    // Casting as String just for safety (this should cast from String? to String).
    try{
      ProfileManager.profileCollectionRootDirectory.createSync();
    } on FileSystemException catch (e){
      print(e);
    }

    _profileCollectionRoot = readJsonFile(_launcherProfiles.path);
    _profileCollection = _profileCollectionRoot['profiles'];

    print("Successfully fetched profile data : ${_profileCollection.values.length} profiles found");
  }

  static Future<void> _saveProfile(_ProfileData data) async {
    _profileCollection[data.name] = data.getSerializableFormat();
    _profileCollectionRoot['profiles'] = _profileCollection;

    String output = const JsonEncoder.withIndent("    ").convert(_profileCollectionRoot);
    await File(_launcherProfiles.path).copy(_launcherProfiles.path.replaceAll(".json", "_smd_backup.json"));
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




class _ProfileData {
  String name;
  String profilePicture;
  String versionId;
  int ramAmount;
  Directory directory;

  // constants
  static const String profileType = "custom";
  final String created = DateTime.now().toIso8601String();

  _ProfileData(
      {
        this.name = "New Profile",
        this.profilePicture = "Crafting_Table",
        this.versionId = "latest-release",
        this.ramAmount = 4
      })
      : directory = Directory(ProfileManager.profileCollectionRootDirectory.path+separator+name);


  Map<String, String> getSerializableFormat(){
    Map<String, String> output = {};
    output["created"] = created;
    output["gameDir"] = directory.path;
    output["icon"] = profilePicture;
    output["javaArgs"] = "-Xmx${ramAmount}G -XX:+UnlockExperimentalVMOptions -XX:+UseG1GC -XX:G1NewSizePercent=20 -XX:G1ReservePercent=20 -XX:MaxGCPauseMillis=50 -XX:G1HeapRegionSize=32M";
    output["lastUsed"] = created;
    output["lastVersionId"] = versionId;
    output["name"] = name;
    output["type"] = profileType;

    return output;
  }
}




enum _ModLoader {
  forge, fabric, vanilla
}




class _ModpackData {
  static const manifestFileName = "modpack.json";
  String name;
  String mcVersion;
  _ModLoader loader;
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
  bool noManifest;

  _ModpackData({
          this.name = "Unnamed",
          this.mcVersion = "latest-release",
          this.loader = _ModLoader.vanilla,
          this.loaderVersion = "14.23.5.2859",
          this.miniature = "pack.png",
          this.headline = "An unknown modpack",
          this.description = "Unknown modpack, tell the author to describe it",
          this.packVersion = "0.0",
          this.source,
          this.discord,
          this.server = "",
          this.author = "Unknown",
          this.ram = 0,
          this.noManifest = true
        });

  String getDefaultProfileName(){
    return "$name $mcVersion";
  }

  _ModpackData.fromFile(File manifest) :
        name = "Unnamed",
        mcVersion = "latest-release",
        loader = _ModLoader.vanilla,
        loaderVersion = "",
        miniature = "",
        headline = "An unknown modpack",
        description = "Unknown modpack, tell the author to describe it",
        packVersion = "0.0",
        source = null,
        discord = null,
        server = "",
        author = "Unknown",
        ram = 0,
        noManifest = true {
    bool hasManifest = manifest.existsSync() && PackInstaller._getFileName(manifest,true).toLowerCase() == manifestFileName;

    Map<String, dynamic> packDataMap = hasManifest ? ProfileManager.readJsonFile(manifest.path) : {};

    name = packDataMap[_ModpackManifestField.name.serializableName];
    mcVersion = packDataMap[_ModpackManifestField.minecraftVersion.serializableName] ?? mcVersion;
    loader = _ModLoader.values.firstWhere((element) => element.name == (packDataMap[_ModpackManifestField.modLoader.serializableName] ?? "vanilla"), orElse: () => loader);
    loaderVersion = packDataMap[_ModpackManifestField.modLoaderVersion.serializableName] ?? loaderVersion;
    miniature = packDataMap[_ModpackManifestField.miniature.serializableName] ?? miniature;
    headline = packDataMap[_ModpackManifestField.headline.serializableName] ?? headline;
    description = packDataMap[_ModpackManifestField.description.serializableName] ?? description;
    packVersion = packDataMap[_ModpackManifestField.modpackVersion.serializableName] ?? packVersion;
    source = Uri.tryParse(packDataMap[_ModpackManifestField.source.serializableName] ?? "");
    discord = Uri.tryParse(packDataMap[_ModpackManifestField.discord.serializableName] ?? "");
    server = packDataMap[_ModpackManifestField.serverIp.serializableName] ?? server;
    author = packDataMap[_ModpackManifestField.authorName.serializableName] ?? author;
    ram = packDataMap[_ModpackManifestField.ram.serializableName] != null ? int.tryParse(packDataMap[_ModpackManifestField.ram.serializableName]) ?? ram : ram;
    noManifest = !hasManifest;
  }

}




enum _ModpackManifestField {
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
  ram("suggested-ram-amount");

  final String serializableName;
  const _ModpackManifestField(this.serializableName);
}




class PackInstaller {
  // The idea of this pack installer is not to be used as a regular way to download
  // modpacks from the internet but more like a tool to keep certain modpacks
  // for certain servers up to date.


  static void setupModpack(Uri source) async{
    // download the zip file
    print("-> Downloading modpack...");
    File modpackArchive = await _downloadModpack(source);
    print("-> Downloaded modpack !");
    // reads the manifest and unpacks the zip file to the (generated) profile directory
    print("-> Installing modpack...");
    _ModpackData modpackData = await _installModpack(modpackArchive);
    print("-> Installed modpack !");
    // checks if the modloader version is present
    print("-> Searching versions...");
    String versionName = await _checkLauncherGameVersion(modpackData);
    print("-> Version search finished !");
    // profile generation
    print("-> Generating profile...");
    _ProfileData profile = await _generateProfile(modpackData);
    print("-> Profile generated !");

    // profile registering
    print("-> Registering profile in the launcher...");
    ProfileManager._saveProfile(profile);
    print("-> Profile registered in the launcher !");
    // copying general infos (options.txt, optionsof.txt, shaderpacks/, resourcepacks/)
    print("-> Copying default profile options...");
    bool copyOptions = true;
    bool copyOptionsOf = true;
    bool copyServers = true;
    bool copyResourcePacks = true;
    bool copyShaderPacks = true;

    String sourcePath = ProfileManager._root.path;
    String targetPath = profile.directory.path;
    if(copyOptions){
      try{
        String delta = "${separator}options.txt";
        File base = File("$sourcePath$delta");
        File result = File("$targetPath$delta");
        if (result.existsSync()){
          print("${messageSpacer}The file $delta is already provided by the modpack, override ? PROMPT Y/N".replaceAll(separator, ""));
          base.copySync(result.path);
        } else {
          base.copySync(result.path);
        }
        print("${messageSpacer}Copied $delta".replaceAll(separator, ""));
      } on FileSystemException catch (e){
        print(e);
      }
    }
    if(copyOptionsOf){
      try{
        String delta = "${separator}optionsof.txt";
        File base = File("$sourcePath$delta");
        File result = File("$targetPath$delta");
        if (result.existsSync()){
          print("${messageSpacer}The file $delta is already provided by the modpack, override ? PROMPT Y/N".replaceAll(separator, ""));
          base.copySync(result.path);
        } else {
          base.copySync(result.path);
        }
        print("${messageSpacer}Copied $delta".replaceAll(separator, ""));
      } on FileSystemException catch (e) {
        print(e);
      }
    }
    if(copyServers){
      try{
        String delta = "${separator}servers.dat";
        File base = File("$sourcePath$delta");
        File result = File("$targetPath$delta");
        if (result.existsSync()){
          print("${messageSpacer}The file $delta is already provided by the modpack, override ? PROMPT Y/N".replaceAll(separator, ""));
          base.copySync(result.path);
        } else {
          base.copySync(result.path);
        }
        print("${messageSpacer}Copied $delta".replaceAll(separator, ""));
      } on FileSystemException catch (e){
        print(e);
      }
    }
    // TODO : Copy shaderpacks and resourcepacks
    print("-> Copied default profile options !");

  }

  static Future<File> _downloadModpack(Uri source) async {
    // https://github.com/Sawors/PackInstaller/blob/7275934d2325eb08ea531130917f7701eba14739/lib/modpack_installer/sample_modpack/sample_modpack.zip
    String downloadId = const Uuid().v1();

    final request = await HttpClient().getUrl(source);
    final response = await request.close();

    final Directory downloadTarget = Directory("${Directory.systemTemp.path}${separator}sawors_modpack_installer");
    final File target = File("${downloadTarget.path}$separator$downloadId.zip");
    try{
      await target.create(recursive: true);
    } on FileSystemException catch (e){
      print(e);
    }

    await response.pipe(target.openWrite());
    return target;
  }


  static Future<_ModpackData> _installModpack(File modpackArchive) async {

    // TODO : UPDATE HANDLING
    //  - check if a modpack.json already exists in the target installation directory
    //  - if so compare versions
    //  - if updatable -> propose to choose : update or reinstall (could be specified by default)
    //  - handle non-destructive updates (ie only replacing updated files)

    const String manifestFileName = _ModpackData.manifestFileName;

    final String downloadId = _getFileName(modpackArchive);
    final Directory target = Directory(modpackArchive.parent.path+separator+downloadId);
    final InputFileStream input = InputFileStream(modpackArchive.path);
    final archive = ZipDecoder().decodeBuffer(input);
    File manifest = File(target.path+separator+manifestFileName);


    for (var file in archive.files) {
      // If it's a file and not a directory
      if (file.isFile) {
        final outputStream = OutputFileStream('${target.path}$separator${file.name}');
        file.writeContent(outputStream);
        if(file.name == manifestFileName){
          manifest = File(outputStream.path);
        }
        outputStream.close();
      }
    }
    input.close();

    bool hasManifest = manifest.existsSync();

    // new job : find root
    final Directory baseDir = Directory(manifest.parent.path);
    Directory modpackRoot = Directory(baseDir.path);
    if(!hasManifest){
      List subFiles = await baseDir.list(recursive: true, followLinks: false).toList();
      for(var file in subFiles){
        if(
        file.path.endsWith("mods")
            || file.path.endsWith("shaderpacks")
            || file.path.endsWith("resourcepacks")
            || file.path.endsWith("options.txt")
            || file.path.endsWith("servers.dat"))
        {
          print("${messageSpacer}Profile directory found");
          modpackRoot = file.parent;
          break;
        }
        if(file.path.endsWith(manifestFileName)){
          manifest = File(file.path);
          modpackRoot = file.parent;
          hasManifest = true;
          break;
        }
      }
    }

    _ModpackData data = _ModpackData.fromFile(manifest);

    String profileName = hasManifest ? "${data.name} ${data.mcVersion}" : _getFileName(modpackRoot);
    if(!hasManifest){
      data.name = _getFileName(modpackRoot);
    }
    Directory profileDirectory = Directory(ProfileManager.profileCollectionRootDirectory.path+separator+profileName);

    try{
      profileDirectory.create();
    } on FileSystemException catch (e){
      print(e);
    }

    await copyPath(modpackRoot.path, profileDirectory.path);

    try{if(target.existsSync()) target.delete(recursive: true);} on FileSystemException catch (e){print(e);}
    try{if(modpackArchive.existsSync()) modpackArchive.delete();} on FileSystemException catch (e){print(e);}

    print("${messageSpacer}Modpack is located at ${profileDirectory.path}$separator");

    return data;
  }

  static Future<String> _checkLauncherGameVersion(_ModpackData reference, [bool printResult = false]) async {
    Stream<FileSystemEntity> versions = Directory("${ProfileManager._root.path}${separator}versions").list(recursive: false, followLinks: false);
    List<String> possibleVersions = [];

    String exactMatch = "";
    await versions.forEach((element) {
      List<String> pathParts = element.path.split(separator);
      String dirName = (pathParts[pathParts.length-1]);
      if(dirName.toLowerCase().contains(reference.mcVersion) && dirName.toLowerCase().contains(reference.loader.name)){
        possibleVersions.add(dirName);
        if(dirName.toLowerCase().contains(reference.loaderVersion)){
          exactMatch = dirName;
        }
      }
    });
    exactMatch = exactMatch.isNotEmpty ? exactMatch : "latest-release";
   if(printResult){
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
   }

    return exactMatch;
  }

  static Future<_ProfileData> _generateProfile(_ModpackData sourceData) async {

    int ram = 4;
    int systemRam = 34359738368 ~/ (1024*1024*1024);

    if(sourceData.ram > 0){
      // using suggested ram
      print("${messageSpacer}Using suggested ram amount for profile");
      ram = sourceData.ram;
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

    _ProfileData profile = _ProfileData(
        name: sourceData.noManifest ? sourceData.name : sourceData.getDefaultProfileName(),
        versionId: await _checkLauncherGameVersion(sourceData, false),
        ramAmount: ram
    );

    final Directory baseDir = profile.directory;
    String encodedImage = "";
    const String defaultImage = "pack.png";
    final String packImagePath = sourceData.miniature.isNotEmpty ? sourceData.miniature : defaultImage;
    for(var file in await baseDir.list().toList()){
      if(file.path.endsWith(packImagePath)){
        // icon file found
        encodedImage = base64Encode(await File(file.path).readAsBytes());
        break;
      }
    }
    if(encodedImage.isNotEmpty){
      profile.profilePicture = "data:image/${defaultImage.substring(defaultImage.lastIndexOf("."))};base64,$encodedImage";
    }

    print("${messageSpacer}Profile name : ${profile.name}");
    print("${messageSpacer}Profile version : ${profile.versionId.length > 1 ? profile.versionId : "latest-release"}");
    print("${messageSpacer}Profile RAM : ${profile.ramAmount}G");

    return profile;
  }

  static String _getFileName(FileSystemEntity file, [bool includeExtension = false]) {
    final List<String> path = file.path.split(separator);
    final String name = path[path.length-1];
    if(file is Directory || includeExtension) return name;
    return name.substring(0,name.lastIndexOf("."));
  }

  static Uri? getModLoaderDownloadLink(_ModLoader loader, String gameVersion, String loaderVersion){
    String source = "";
    switch(loader){
      case _ModLoader.forge:
        String identifier = "$gameVersion-$loaderVersion";
        source = "https://maven.minecraftforge.net/net/minecraftforge/forge/$identifier/forge-$identifier-installer.jar";
        break;
      case _ModLoader.fabric:
        source = "https://maven.fabricmc.net/net/fabricmc/fabric-installer/$loaderVersion/fabric-installer-$loaderVersion.jar";
        break;
        break;
      case _ModLoader.vanilla:
        return null;
    }
    return Uri.tryParse(source);
  }
}


enum _UpdateState {
  added, removed, modified
}

class _UpdateContent {
  Set<FileSystemEntity> added = {};
  Set<FileSystemEntity> removed = {};
  Set<FileSystemEntity> modified = {};
  String oldDirectoryPath = "";
  String updateDirectoryPath = "";
  String baseVersion = "";
  String newVersion = "";

  Future<_UpdateContent> getFromFile({required final Directory oldVersionRoot, required final Directory newVersionRoot}) async {

    oldDirectoryPath = oldVersionRoot.path;
    updateDirectoryPath = newVersionRoot.path;
    const String manifestFileName = _ModpackData.manifestFileName;
    File oldManifest = File(oldDirectoryPath+separator+manifestFileName);
    File newManifest = File(updateDirectoryPath+separator+manifestFileName);

    if(oldManifest.existsSync() && PackInstaller._getFileName(oldManifest,true).toLowerCase() == manifestFileName && newManifest.existsSync() && PackInstaller._getFileName(newManifest,true).toLowerCase() == manifestFileName){
      // the old and new modpacks have manifests
      Map<String, dynamic> oldPackDataMap =  ProfileManager.readJsonFile(oldManifest.path);
      baseVersion = oldPackDataMap[_ModpackManifestField.modpackVersion.serializableName] ?? "";
      final List<String> baseVersionTree = baseVersion.split(".");

      Map<String, dynamic> newPackDataMap = ProfileManager.readJsonFile(newManifest.path);
      newVersion = newPackDataMap[_ModpackManifestField.modpackVersion.serializableName] ?? "";
      final List<String> newVersionTree = newVersion.split(".");

      for(int i = 0; i<min(baseVersionTree.length, newVersionTree.length); i++){
        int baseTag = int.tryParse(baseVersionTree[i]) ?? -1;
        int updateTag = int.tryParse(newVersionTree[i]) ?? -1;
        if(baseTag == updateTag) continue;
        if(baseTag < updateTag) break;
        if(baseTag > updateTag){
          // This case is an error. Reversing the versions
          final String tempVersion = baseVersion;
          baseVersion = newVersion;
          newVersion = tempVersion;

          final String tempDir = oldDirectoryPath;
          oldDirectoryPath = updateDirectoryPath;
          updateDirectoryPath = tempDir;
          print(oldDirectoryPath);
          print(updateDirectoryPath);
          break;
        }
      }

    }

    Map<_UpdateState, Map<String, FileSystemEntity>> content = await _getUpdateContent(oldVersionRoot, newVersionRoot);
    added = content[_UpdateState.added]!.values.toSet();
    removed = content[_UpdateState.removed]!.values.toSet();
    modified = content[_UpdateState.modified]!.values.toSet();

    return this;
  }


  static Future<Map<_UpdateState, Map<String, FileSystemEntity>>> _getUpdateContent(Directory oldVersionRoot, Directory newVersionRoot) async{
    Map<_UpdateState, Map<String, FileSystemEntity>> updateContent = {};
    final String oldRootPath = oldVersionRoot.path;
    final String newRootPath = newVersionRoot.path;
    final Map<String, FileSystemEntity> oldContent = {
      for (var e in await oldVersionRoot.list(recursive: true,followLinks: false).toList())
        e.path.replaceAll(oldRootPath, "") : e
    };
    final Map<String, FileSystemEntity> newContent = {
      for (var e in await newVersionRoot.list(recursive: true,followLinks: false).toList())
        e.path.replaceAll(newRootPath, "") : e
    };


    // blacklist loading :
    // the blacklist from the "updated" directory is first loaded, then
    // the blacklist coming from the user's directory is added to it (removing duplicates)

    // TODO : add a config for this list (add-ignore.json)
    Set<String> ignoreAdded = {};
    const Set<String> defaultIgnoreAdded = {
      ".git*",
      ".mixin.out*",
      ".replay_cache*",
      "backups*",
      "crash-reports*",
      "Distant_Horizons_server_data*",
      "etched-sounds*",
      "logs*",
      "replay_recordings*",
      "screenshots*",
      "*.bak"
    };
    // TODO : add a config for this list (remove-ignore.json)
    Set<String> ignoreRemoved = {};
    const Set<String> defaultIgnoreRemoved = {
      ".git*",
      ".mixin.out*",
      ".replay_cache*",
      "backups*",
      "crash-reports*",
      "Distant_Horizons_server_data*",
      "etched-sounds*",
      "logs*",
      "replay_recordings*",
      "resourcepacks*",
      "shaderpacks*",
      "screenshots*",
      "servers.dat_old",
      "usercache.json",
      "usernamecache.json",
      "*.bak"
    };

    // TODO : add a config for this list (edit-ignore.json)
    Set<String> ignoreModified = {};
    const Set<String> defaultIgnoreModified = {
      "*.zip",
      "*.jar",
      "*.exe",
      "*.fsh",
      "*.vsh",
      "*.glsl",
      "*.placebo",
      "*.bak",
      "options.txt",
      "optionsof.txt",
      "servers.dat"
    };

    // loading blacklists
    Set<String> blacklistSources = {oldRootPath,newRootPath};
    for(String rootPath in blacklistSources){
      Directory configDirectory = Directory("$rootPath${separator}updater-config");
      if(configDirectory.existsSync()){
        File blacklistsFile = File("${configDirectory.path}${separator}blacklists.json");
        if(blacklistsFile.existsSync()){
          Map<String, dynamic> configData =  ProfileManager.readJsonFile(blacklistsFile.path);
          //.addAll((configData["added-blacklist"] ?? []));
          List<dynamic> read = (configData["ignore-added"] ?? []);
          for (var element in read) {ignoreAdded.add(element.toString());}
          read = (configData["ignore-removed"] ?? []);
          for (var element in read) {ignoreRemoved.add(element.toString());}
          read = (configData["ignore-modified"] ?? []);
          for (var element in read) {ignoreModified.add(element.toString());}

        }
      }
    }
    if(ignoreAdded.isEmpty) ignoreAdded.addAll(defaultIgnoreAdded);
    if(ignoreRemoved.isEmpty) ignoreRemoved.addAll(defaultIgnoreRemoved);
    if(ignoreModified.isEmpty) ignoreModified.addAll(defaultIgnoreModified);

    print(ignoreAdded);
    print(ignoreRemoved);
    print(ignoreModified);

    final Map<String, FileSystemEntity> addedContent = {};
    for(var entry in newContent.entries){
      if(!oldContent.containsKey(entry.key) && !isBlacklisted(entry.key, ignoreAdded)){
        addedContent[entry.key] = entry.value;
      }
    }
    final Map<String, FileSystemEntity> removedContent ={};
    for(var entry in oldContent.entries){
      if(!newContent.containsKey(entry.key) && !isBlacklisted(entry.key, ignoreRemoved)){

        removedContent[entry.key] = entry.value;
      }
    }
    final Map<String, FileSystemEntity> modifiedContent ={};
    for(var entry in oldContent.entries){
      if(!removedContent.containsKey(entry.key) && !addedContent.containsKey(entry.key) && newContent.containsKey(entry.key) && newContent[entry.key] is File && oldContent[entry.key] is File && !isBlacklisted(entry.key, ignoreRemoved)){
        try{
          String oldData = await File(oldContent[entry.key]!.path).readAsString();
          String newData = await File(newContent[entry.key]!.path).readAsString();
          if(oldData != newData){
            modifiedContent[entry.key] = entry.value;
          }
        } catch (e){
          List<int> oldData = await File(oldContent[entry.key]!.path).readAsBytes();
          List<int> newData = await File(newContent[entry.key]!.path).readAsBytes();
          if(oldData.length != newData.length){
            modifiedContent[entry.key] = entry.value;
          }
        }
      }
    }

    updateContent[_UpdateState.added] = addedContent;
    updateContent[_UpdateState.removed] = removedContent;
    updateContent[_UpdateState.modified] = modifiedContent;

    return updateContent;
  }

  static bool isBlacklisted(String toCheck, Set<String> blacklist) {
    String toCheckFormatted = toCheck.replaceAll("\\", "/");
    if(toCheckFormatted.isNotEmpty && toCheckFormatted.split("")[0] == "/"){
      toCheckFormatted = toCheckFormatted.replaceFirst("/", "");
    }
    for(String ref in blacklist){
      //if(ref.isEmpty) continue;
      String refStripped = ref.replaceAll("*", "").replaceAll("\\", "/");
      if(refStripped.endsWith("/")){
        refStripped = refStripped.substring(0,refStripped.length-1);
      }
      if(ref.startsWith("*") && toCheckFormatted.endsWith(refStripped)){
        return toCheckFormatted.endsWith(refStripped);
      } else if(ref.endsWith("*") && toCheckFormatted.startsWith(refStripped)){
        return toCheckFormatted.startsWith(refStripped);
      } else if (toCheckFormatted == refStripped){
        return toCheckFormatted == refStripped;
      }
    }

    return false;
  }


  String generatePatchNote() {
    String patchNote = "";
    final String topBreak =    "------------------------PATCHNOTE [${DateFormat('dd/MM/yyyy - HH:mm:ss').format(DateTime.now())}]------------------------";
    const String bottomBreak = "----------------------------------PATCHNOTE END----------------------------------";
    if(baseVersion.isNotEmpty || newVersion.isNotEmpty){
      patchNote += "\nVersion : $baseVersion => $newVersion";
    }
    patchNote += "\nAdded content :";
    for(FileSystemEntity added in added){
      patchNote += "\n$messageSpacer+ ${added.path.replaceAll(updateDirectoryPath, "").replaceFirst(separator, "")}";
    }
    patchNote += "\nRemoved content :";
    for(FileSystemEntity added in removed){
      patchNote += "\n$messageSpacer- ${added.path.replaceAll(oldDirectoryPath, "").replaceFirst(separator, "")}";
    }
    patchNote += "\nModified content :";
    for(FileSystemEntity added in modified){
      patchNote += "\n$messageSpacer~ ${added.path.replaceAll(oldDirectoryPath, "").replaceFirst(separator, "")}";
    }

    return "$topBreak$patchNote\n$bottomBreak";
  }
}

class PackUpdater {

//     [Old File], [New File]
    static void getUpdate(Directory source, Directory update) async {
      _UpdateContent content = await _UpdateContent().getFromFile(oldVersionRoot: source, newVersionRoot: update);
      print(content.generatePatchNote());
    }
}