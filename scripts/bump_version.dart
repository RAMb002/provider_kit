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
  var content = pubspecFile.readAsStringSync();

  final versionRegex = RegExp(r'^version:\s*(\d+)\.(\d+)\.(\d+)', multiLine: true);
  final match = versionRegex.firstMatch(content);
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

  // Update pubspec.yaml
  final newContent = content.replaceFirst(
    match.group(0)!,
    'version: $newVersion',
  );
  pubspecFile.writeAsStringSync(newContent);

  // ------------------------------------------------
  // 2. Update CHANGELOG.md safely
  // ------------------------------------------------
  final changelogFile = File('CHANGELOG.md');

  if (!changelogFile.existsSync()) {
    // If CHANGELOG.md is missing, create a basic one.
    changelogFile.writeAsStringSync('''
## Unreleased

- Initial release notes.

## $newVersion

- Initial release.

''');
  } else {
    var changelog = changelogFile.readAsStringSync();

    // Look for the "## Unreleased" section.
    const unreleasedHeader = '## Unreleased';
    if (changelog.contains(unreleasedHeader)) {
      // Replace the FIRST occurrence of "## Unreleased" with "## $newVersion"
      // This is safe because unreleased is usually at the top.
      changelog = changelog.replaceFirst(unreleasedHeader, '## $newVersion');
      // Now prepend a fresh "## Unreleased" section at the very top.
      changelog = '$unreleasedHeader\n\n$changelog';
    } else {
      // No "Unreleased" section – just prepend a new version entry.
      final newEntry = '## $newVersion\n\n- Automated release.\n\n';
      changelog = '$newEntry$changelog';
    }

    changelogFile.writeAsStringSync(changelog);
  }

  // Output the new version for GitHub Actions to capture.
  // ignore: avoid_print
  print(newVersion);
}