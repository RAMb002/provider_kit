import 'dart:io';

// Usage: dart scripts/bump_version.dart <patch|minor|major>
void main(List<String> args) {
  if (args.isEmpty) {
    // ignore: avoid_print
    print('Usage: dart scripts/bump_version.dart <patch|minor|major>');
    exit(1);
  }

  final type = args[0];

  // ------------------------------------------------
  // 1. Bump version in pubspec.yaml
  // ------------------------------------------------
  final pubspecFile = File('pubspec.yaml');
  var pubspec = pubspecFile.readAsStringSync();

  final versionRegex =
      RegExp(r'^version:\s*(\d+)\.(\d+)\.(\d+)', multiLine: true);

  final match = versionRegex.firstMatch(pubspec);

  if (match == null) {
    // ignore: avoid_print
    print('Could not find version in pubspec.yaml');
    exit(1);
  }

  int major = int.parse(match.group(1)!);
  int minor = int.parse(match.group(2)!);
  int patch = int.parse(match.group(3)!);

  switch (type) {
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

    default:
      // ignore: avoid_print
      print('Invalid bump type: $type. Use patch, minor, or major.');
      exit(1);
  }

  final newVersion = '$major.$minor.$patch';

  pubspec = pubspec.replaceFirst(
    match.group(0)!,
    'version: $newVersion',
  );

  pubspecFile.writeAsStringSync(pubspec);

  // ------------------------------------------------
  // 2. Update CHANGELOG.md
  // ------------------------------------------------
  final changelogFile = File('CHANGELOG.md');

  if (!changelogFile.existsSync()) {
    changelogFile.writeAsStringSync('''
## Unreleased

- Initial release notes.

## $newVersion

- Initial release.

''');
  } else {
    var changelog = changelogFile.readAsStringSync();

    const unreleasedHeader = '## Unreleased';

    if (changelog.contains(unreleasedHeader)) {
      changelog = changelog.replaceFirst(
        unreleasedHeader,
        '## $newVersion',
      );
    } else {
      changelog = '''
## $newVersion

- Automated release.

$changelog
''';
    }

    changelogFile.writeAsStringSync(changelog);
  }

  // ------------------------------------------------
  // 3. Update README.md dependency version
  // ------------------------------------------------
  final readmeFile = File('README.md');

  if (readmeFile.existsSync()) {
    var readme = readmeFile.readAsStringSync();

    final dependencyRegex = RegExp(
      r'(^\s*provider_kit:\s*\^)\d+\.\d+\.\d+',
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

  // ------------------------------------------------
  // Done
  // ------------------------------------------------

  // ignore: avoid_print
  print(newVersion);
}
