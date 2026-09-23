import 'dart:io';

Never fail(String message) {
  stderr.writeln('❌ $message');
  exit(1);
}

void main(List<String> args) {
  if (args.length != 2) {
    fail(
      'Usage: dart tool/bump_version.dart '
      '<package-path> <patch|minor|major>',
    );
  }

  final packagePath = args[0];
  final bumpType = args[1];

  const validBumps = {'patch', 'minor', 'major'};

  if (!validBumps.contains(bumpType)) {
    fail(
      'Invalid bump type: $bumpType. '
      'Use patch, minor, or major.',
    );
  }

  final packageDirectory = Directory(packagePath);

  if (!packageDirectory.existsSync()) {
    fail('Package directory not found: $packagePath');
  }

  final separator = Platform.pathSeparator;

  final pubspecFile = File('${packageDirectory.path}${separator}pubspec.yaml');

  if (!pubspecFile.existsSync()) {
    fail('pubspec.yaml not found: ${pubspecFile.path}');
  }

  var pubspec = pubspecFile.readAsStringSync();

  // ------------------------------------------------
  // 1. Read package name
  // ------------------------------------------------

  final nameMatch = RegExp(
    r'^name:\s*([a-z0-9_]+)\s*$',
    multiLine: true,
  ).firstMatch(pubspec);

  if (nameMatch == null) {
    fail('Could not find package name in pubspec.yaml.');
  }

  final packageName = nameMatch.group(1)!;

  // ------------------------------------------------
  // 2. Read current version
  // ------------------------------------------------

  final versionRegex = RegExp(
    r'^version:\s*(\d+)\.(\d+)\.(\d+)',
    multiLine: true,
  );

  final versionMatch = versionRegex.firstMatch(pubspec);

  if (versionMatch == null) {
    fail('Could not find version in pubspec.yaml.');
  }

  var major = int.parse(versionMatch.group(1)!);
  var minor = int.parse(versionMatch.group(2)!);
  var patch = int.parse(versionMatch.group(3)!);

  switch (bumpType) {
    case 'major':
      major++;
      minor = 0;
      patch = 0;
      break;

    case 'minor':
      minor++;
      patch = 0;
      break;

    case 'patch':
      patch++;
      break;
  }

  final newVersion = '$major.$minor.$patch';

  // ------------------------------------------------
  // 3. CHANGELOG is mandatory
  // ------------------------------------------------

  final changelogFile = File(
    '${packageDirectory.path}${separator}CHANGELOG.md',
  );

  if (!changelogFile.existsSync()) {
    fail(
      'CHANGELOG.md not found for $packageName.\n'
      'CHANGELOG.md is mandatory for automated releases.',
    );
  }

  var changelog = changelogFile.readAsStringSync();

  // ------------------------------------------------
  // 4. Require ## Unreleased
  // ------------------------------------------------

  final unreleasedRegex = RegExp(r'^##\s+Unreleased\s*$', multiLine: true);

  final unreleasedMatch = unreleasedRegex.firstMatch(changelog);

  if (unreleasedMatch == null) {
    fail(
      "'## Unreleased' section not found in "
      '$packageName/CHANGELOG.md.',
    );
  }

  final contentAfterUnreleased = changelog.substring(unreleasedMatch.end);

  final nextHeaderMatch = RegExp(
    r'^##\s+.+$',
    multiLine: true,
  ).firstMatch(contentAfterUnreleased);

  final unreleasedContent = contentAfterUnreleased.substring(
    0,
    nextHeaderMatch?.start ?? contentAfterUnreleased.length,
  );

  if (unreleasedContent.trim().isEmpty) {
    fail(
      "'## Unreleased' section in "
      '$packageName/CHANGELOG.md is empty.',
    );
  }

  // ------------------------------------------------
  // 5. Update version
  // ------------------------------------------------

  pubspec = pubspec.replaceRange(
    versionMatch.start,
    versionMatch.end,
    'version: $newVersion',
  );

  pubspecFile.writeAsStringSync(pubspec);

  // ------------------------------------------------
  // 6. Promote Unreleased → version
  // ------------------------------------------------

  changelog = changelog.replaceRange(
    unreleasedMatch.start,
    unreleasedMatch.end,
    '## $newVersion',
  );

  changelogFile.writeAsStringSync(changelog);

  // ------------------------------------------------
  // 7. Update matching dependency in README
  // ------------------------------------------------

  final readmeFile = File(
  '${packageDirectory.path}${separator}README.md',
);

  if (readmeFile.existsSync()) {
    var readme = readmeFile.readAsStringSync();

    final dependencyRegex = RegExp(
      '(^\\s*${RegExp.escape(packageName)}:\\s*\\^)'
      '\\d+\\.\\d+\\.\\d+',
      multiLine: true,
    );

    if (dependencyRegex.hasMatch(readme)) {
      readme = readme.replaceFirstMapped(
        dependencyRegex,
        (match) => '${match.group(1)}$newVersion',
      );

      readmeFile.writeAsStringSync(readme);
    }
  }

  stdout.writeln(newVersion);
}
