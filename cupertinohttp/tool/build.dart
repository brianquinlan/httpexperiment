// ~/dart/dart-sdk1/sdk/xcodebuild/DebugARM64/dart-sdk/bin/dart run tool/build.dart build --abi=ios_arm64
// $pwd/ios/Frameworks/libmylib_dylib

import 'dart:convert';
import 'dart:io';

import 'package:logging/logging.dart';
import 'package:native_library/native_library.dart';

const packageName = 'mylib_dylib';
const sharedLibraryNames = [packageName, 'mylib_dylib_dependency'];
const fatAbis = [
  [macOSArm64, macOSX64],
  [iOSArm, iOSArm64, iOSSimulatorX64],
];
final packageRootUri =
    Uri.directory(File.fromUri(packageConfigSync).parent.parent.path);
final srcUri = packageRootUri.resolve('src/');
Uri buildUri(Abi abi) => packageRootUri.resolve('out/$abi/');
List<Uri> targetUris(Abi abi) => [
      if (abi.os.isDesktop) packageRootUri.resolve('native/lib/$abi/'),
      if (abi.os == OS.android)
        packageRootUri.resolve(
            'android/src/main/jniLibs/${abi.architecture.cmakeAndroid}/'),
    ];
List<Uri> fatTargetUris(Abi abi) => [
      if (abi.os == OS.iOS) packageRootUri.resolve('ios/Frameworks/'),
      if (abi.os == OS.macOS) packageRootUri.resolve('macos/Frameworks/'),
    ];

final _logger = Logger(packageName);

void main(List<String> args) async {
  final arguments = argParser.parse(args);
  final command = arguments.command;
  if (argParser.printHelp(arguments) || command == null) {
    return;
  }

  Logger.root.level = arguments.logLevel;
  Logger.root.onRecord.listen((record) {
    var message = record.message;
    if (!message.endsWith('\n')) message += '\n';
    if (record.level.value < Level.SEVERE.value) {
      stdout.write(message);
    } else {
      stderr.write(message);
    }
  });

  final abis = arguments.abis;
  switch (command.name) {
    case 'build':
      if (command['clean'] == true) {
        await clean(abis);
      }
      print('abis: $abis');
      final unduplicatedAbis = abis.unduplicateFatAbis(fatAbis);
      _logger.info('Building for ${abis.expandFatAbis(fatAbis)}.');
      try {
        for (var i = 0; i < unduplicatedAbis.length; ++i) {
          await build(unduplicatedAbis[i]);
        }
//        await Future.wait(unduplicatedAbis.map(build));
      } on Exception {
        _logger.severe('One or more builds failed, check logs.');
        rethrow;
      }
      break;
    case 'clean':
      await clean(abis);
      break;
  }
}

Future<void> build(Abi abi) async {
  if (abi.os == OS.macOS || abi.os == OS.iOS) {
    return buildMacOsOrIOS(abi);
  }
  if (abi.os == OS.android || abi.os == OS.linux || abi.os == OS.windows) {
    return cmakeBuildSingleArch(abi);
  }

  _logger.severe(
      "Cross compilation from '${Abi.current}' to '$abi' not yet implemented.");
}

/// Builds (non-fat) binaries.
///
/// On iOS, assumes arm64 is building for device and x64 is building for
/// simulator.
Future<void> cmakeBuildSingleArch(Abi abi) async {
  await runProcess(
    (await cmake).path,
    [
      '-S',
      srcUri.toFilePath(),
      '-B',
      buildUri(abi).toFilePath(),
      if (abi.os == OS.android) ...[
        '-DCMAKE_SYSTEM_NAME=Android',
        '-DCMAKE_SYSTEM_VERSION=28',
        '-DCMAKE_ANDROID_ARCH_ABI=${abi.architecture.cmakeAndroid}',
        '-DCMAKE_ANDROID_NDK=${(await androidNdk).path}',
      ],
      if (Abi.current == windowsX64) ...[
        '-GNinja',
        '-DCMAKE_MAKE_PROGRAM=${(await ninja).path}',
      ],
      if (abi == windowsX64) '-DCMAKE_C_COMPILER=${(await clang).path}',
      if (abi == windowsIA32 || abi == linuxIA32) ...[
        '-DCMAKE_C_FLAGS=-m32',
      ],
      if (abi == linuxArm) '-DCMAKE_C_COMPILER=arm-linux-gnueabihf-gcc',
      if (abi == linuxArm64) '-DCMAKE_C_COMPILER=aarch64-linux-gnu-gcc',
      if (abi.os == OS.iOS) ...[
        '-GXcode',
        '-DCMAKE_SYSTEM_NAME=iOS',
        '-DCMAKE_OSX_DEPLOYMENT_TARGET=10.0',
        '-DCMAKE_INSTALL_PREFIX=`pwd`/_install',
        '-DCMAKE_XCODE_ATTRIBUTE_ONLY_ACTIVE_ARCH=NO',
        '-DCMAKE_IOS_INSTALL_COMBINED=YES',
      ],
      if (abi.os == OS.iOS || abi.os == OS.macOS) ...[
        '-DCMAKE_OSX_ARCHITECTURES=${abi.architecture.cmakeOsx}',
      ],
    ],
  );

  await runProcess(
    (await cmake).path,
    [
      '--build',
      buildUri(abi).toFilePath(),
      '--target',
      ...sharedLibraryNames,
      if (abi.os == OS.iOS) ...[
        '--',
        '-sdk',
        abi.iOSSdk!.xcodebuildSdk,
      ],
    ],
  );

  await copyFiles(
    buildUri(abi),
    targetUris(abi),
    [
      for (final sharedLibraryName in sharedLibraryNames)
        dylibFileName(sharedLibraryName, os: abi.os)
    ],
  );
}

/// Build for iOS or MacOS.
///
/// On iOS, the resulting fat dylib is linked against the device for arm64 and
/// linked against the simulator for x64.
Future<void> buildMacOsOrIOS(Abi abi) async {
  print('Building with Abi: $abi');
  print('fatAbis: $fatAbis');
  final targetAbis = fatAbis.firstWhere((List<Abi> l) => l.contains(abi));
  print('Target is Abi: $targetAbis');
  await Future.wait(targetAbis.map(cmakeBuildSingleArch));
  print('Build complete for $abi => $targetAbis');
  final frameworkUri = fatTargetUris(abi).single;
  final frameworkDir = Directory.fromUri(frameworkUri);
  if (!await frameworkDir.exists()) {
    await frameworkDir.create(recursive: true);
  }
  await Future.wait(sharedLibraryNames.map((String libraryName) async {
    final libraryFileName = dylibFileName(libraryName, os: OS.iOS);
    final singleTargetLibUrls = <Uri>[];
    await Future.wait(targetAbis.map((Abi abi) async {
      final lib = () {
        if (abi.os == OS.iOS) {
          final targetOs = abi.iOSSdk!.xcodebuildSdk;
          return buildUri(abi).resolve('Debug-$targetOs/$libraryFileName');
        }
        return buildUri(abi).resolve(libraryFileName);
      }();
      if (!await File.fromUri(lib).exists()) {
        final message = "File missing: '${lib.toFilePath()}'.";
        _logger.severe(message);
        throw Exception(message);
      }
      singleTargetLibUrls.add(lib);
    }));

    // TODO(dacoharkes): We're compiling a fat binary with the arm64
    // slice always targeting the device. So we can't run the simulator
    // on M1 this way.
    //
    // Trying to do an xcframework for dylib runs into:
    // > [!] Invalid XCFramework slice type `.dylib`
    final combinedLib = frameworkUri.resolve(libraryFileName);
    await runProcess('lipo', [
      '-create',
      for (final uri in singleTargetLibUrls) uri.toFilePath(),
      '-output',
      combinedLib.toFilePath(),
    ]);
  }));
}

Future<void> runProcess(String executable, List<String> arguments) async {
  final commandString = [executable, ...arguments].join(' ');
  _logger.config('Running `$commandString`.');
  final process = await Process.start(
    executable,
    arguments,
    runInShell: true,
    includeParentEnvironment: true,
  ).then((process) {
    process.stdout.transform(utf8.decoder).forEach(_logger.fine);
    process.stderr.transform(utf8.decoder).forEach(_logger.severe);
    return process;
  });
  final exitCode = await process.exitCode;
  if (exitCode != 0) {
    final message = 'Command `$commandString` failed with exit code $exitCode.';
    _logger.severe(message);
    throw Exception(message);
  }
  _logger.fine('Command `$commandString` done.');
}

Future<void> copyFiles(
    Uri sourceUri, Iterable<Uri> targetUris, Iterable<String> fileNames) async {
  await Future.wait(targetUris.map((Uri targetUri) async {
    final targetDir = Directory.fromUri(targetUri);
    if (!await targetDir.exists()) {
      await targetDir.create(recursive: true);
    }
    await Future.wait(fileNames.map((String fileName) async {
      final fileUri = sourceUri.resolve(fileName);
      final file = File.fromUri(fileUri);
      if (!await file.exists()) {
        final message =
            "File not in expected location: '${fileUri.toFilePath()}'.";
        _logger.severe(message);
        throw Exception(message);
      }
      final targetFile = targetUri.resolve(fileUri.pathSegments.last);
      await file.copy(targetFile.toFilePath());
    }));
  }));
}

Future<void> clean(List<Abi> abis) async {
  final expandedAbis = abis.expandFatAbis(fatAbis);
  _logger.info('Deleting built artifacts for $expandedAbis.');
  final paths = {
    for (final abi in expandedAbis) ...[
      buildUri(abi),
      ...targetUris(abi),
      ...fatTargetUris(abi),
    ],
  }.toList()
    ..sort((Uri a, Uri b) => a.path.compareTo(b.path));
  await Future.wait(paths.map((path) async {
    _logger.config('Deleting `${path.toFilePath()}`.');
    final dir = Directory.fromUri(path);
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
  }));
}
