import 'dart:io';

/// PUBLIC_INTERFACE
/// Copies the most suitable built APK from the standard Flutter/Android output
/// folders to the repository root and appends version info to the filename.
///
/// Output filename pattern:
///   vibe_coding_companion-vVERSIONNAME-cVERSIONCODE.apk
/// Example:
///   vibe_coding_companion-v1.2.3-c45.apk
///
/// Preference order:
/// 1) Universal release APK (e.g., app-release.apk)
/// 2) Any ABI split release APK (e.g., app-armeabi-v7a-release.apk)
/// 3) Universal debug APK (e.g., app-debug.apk)
/// 4) Any ABI split debug APK (e.g., app-armeabi-v7a-debug.apk)
///
/// Usage:
/// 1) Build an APK (e.g., flutter build apk --release)
/// 2) Run: dart run tool/copy_apk.dart
///
/// The script searches under build/app/outputs/apk/ and copies the selected
/// file to the repository root as a versioned filename.
Future<void> main(List<String> args) async {
  // Determine project boundaries:
  // This script resides in <repo>/flutter_frontend/tool/copy_apk.dart
  final scriptFile = Platform.script.toFilePath();
  final scriptDir = File(scriptFile).parent; // .../flutter_frontend/tool
  final flutterFrontendDir = scriptDir.parent; // .../flutter_frontend
  final repoRootDir = flutterFrontendDir.parent; // .../

  // Read version from pubspec.yaml (format: version: x.y.z+code)
  final pubspecFile = File('${flutterFrontendDir.path}/pubspec.yaml');
  if (!pubspecFile.existsSync()) {
    stderr.writeln('pubspec.yaml not found at ${pubspecFile.path}');
    exit(1);
  }

  final pubspecLines = pubspecFile.readAsLinesSync();
  String? versionName;
  String? versionCode;

  // Find the first "version:" line and extract name/code.
  for (final rawLine in pubspecLines) {
    final line = rawLine.trim();
    if (line.startsWith('version:')) {
      final value = line.substring('version:'.length).trim(); // e.g., 1.2.3+45
      final plusIdx = value.indexOf('+');
      if (plusIdx > 0) {
        versionName = value.substring(0, plusIdx);
        versionCode = value.substring(plusIdx + 1);
      } else {
        // No build code provided, default to 0.
        versionName = value;
        versionCode = '0';
      }
      break;
    }
  }

  if (versionName == null || versionCode == null) {
    stderr.writeln(
      'Could not parse version from pubspec.yaml. Expected "version: x.y.z+code".',
    );
    exit(1);
  }

  final outputsBase = Directory(
    '${flutterFrontendDir.path}/build/app/outputs/apk',
  );

  if (!outputsBase.existsSync()) {
    stderr.writeln('APK outputs folder not found: ${outputsBase.path}');
    stderr.writeln('Make sure you ran a build, for example:');
    stderr.writeln('  flutter build apk --release');
    exit(2);
  }

  // Collect candidate APKs in priority order
  final candidates = <File>[];

  // Helper to add APKs from a subfolder with a matcher
  void addApksMatching(Directory dir, bool Function(String) nameMatch) {
    if (!dir.existsSync()) return;
    for (final entity in dir.listSync(recursive: false, followLinks: false)) {
      if (entity is File && entity.path.toLowerCase().endsWith('.apk')) {
        final name = entity.uri.pathSegments.isNotEmpty
            ? entity.uri.pathSegments.last
            : entity.path.split(Platform.pathSeparator).last;
        if (nameMatch(name)) {
          candidates.add(entity);
        }
      }
    }
  }

  // Priority 1: universal release apk (app-release.apk)
  addApksMatching(
    Directory('${outputsBase.path}/release'),
    (name) => name == 'app-release.apk',
  );

  // Priority 2: any release split (e.g., app-armeabi-v7a-release.apk, app-universal-release.apk)
  addApksMatching(
    Directory('${outputsBase.path}/release'),
    (name) => name.endsWith('-release.apk') && name != 'app-release.apk',
  );

  // Some projects may output under nested flavor folders: apk/<flavor>/release
  if (candidates.isEmpty) {
    for (final flavorDir in outputsBase.listSync()) {
      if (flavorDir is Directory &&
          flavorDir.path != '${outputsBase.path}/release' &&
          flavorDir.path != '${outputsBase.path}/debug') {
        addApksMatching(
          Directory('${flavorDir.path}/release'),
          (name) => name == 'app-release.apk',
        );
        addApksMatching(
          Directory('${flavorDir.path}/release'),
          (name) => name.endsWith('-release.apk') && name != 'app-release.apk',
        );
      }
    }
  }

  // Priority 3: universal debug apk (app-debug.apk)
  if (candidates.isEmpty) {
    addApksMatching(
      Directory('${outputsBase.path}/debug'),
      (name) => name == 'app-debug.apk',
    );
  }

  // Priority 4: any debug split (e.g., app-armeabi-v7a-debug.apk)
  if (candidates.isEmpty) {
    addApksMatching(
      Directory('${outputsBase.path}/debug'),
      (name) => name.endsWith('-debug.apk') && name != 'app-debug.apk',
    );
  }

  // Also check nested flavor debug directories if still empty
  if (candidates.isEmpty) {
    for (final flavorDir in outputsBase.listSync()) {
      if (flavorDir is Directory &&
          flavorDir.path != '${outputsBase.path}/release' &&
          flavorDir.path != '${outputsBase.path}/debug') {
        addApksMatching(
          Directory('${flavorDir.path}/debug'),
          (name) => name == 'app-debug.apk',
        );
        addApksMatching(
          Directory('${flavorDir.path}/debug'),
          (name) => name.endsWith('-debug.apk') && name != 'app-debug.apk',
        );
      }
    }
  }

  if (candidates.isEmpty) {
    stderr.writeln('No APK found under ${outputsBase.path}');
    stderr.writeln('Searched common locations for release and debug outputs.');
    stderr.writeln('Build the APK first, for example:');
    stderr.writeln('  flutter build apk --release');
    exit(3);
  }

  // If multiple candidates in the same priority, pick the newest by modified time
  candidates.sort((a, b) {
    final am = a.lastModifiedSync();
    final bm = b.lastModifiedSync();
    return bm.compareTo(am); // newest first
  });

  final selected = candidates.first;

  final outName = 'vibe_coding_companion-v$versionName-c$versionCode.apk';
  final dest = File('${repoRootDir.path}/$outName');

  // Ensure any existing file with the same name is removed before copy
  if (dest.existsSync()) {
    try {
      dest.deleteSync();
    } catch (e) {
      stderr.writeln('Failed to remove existing ${dest.path}: $e');
      exit(4);
    }
  }

  stdout.writeln('Copying APK: ${selected.path}');
  stdout.writeln('        to: ${dest.path}');
  try {
    selected.copySync(dest.path);
  } catch (e) {
    stderr.writeln('Failed to copy APK: $e');
    exit(5);
  }

  stdout.writeln('Success: APK copied to ${dest.path}');
}
