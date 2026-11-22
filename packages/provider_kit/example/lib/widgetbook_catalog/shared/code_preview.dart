import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/atom-one-dark.dart';

/// Identifies a real Dart source file bundled as a Flutter asset.
class WidgetbookSourceFile {
  const WidgetbookSourceFile(this.assetPath);

  /// Asset path and source path are intentionally identical.
  final String assetPath;

  String get displayPath => 'example/$assetPath';
}

/// Displays the live widget first, followed by the actual source files.
///
/// All content belongs to one [CustomScrollView]. Source blocks do not create
/// nested vertical or horizontal scroll views, so the use case scrolls as one
/// continuous documentation page.
class CodePreview extends StatelessWidget {
  const CodePreview({
    required this.title,
    required this.description,
    required this.preview,
    required this.sourceFiles,
    super.key,
  });

  final String title;
  final String description;
  final Widget preview;
  final List<WidgetbookSourceFile> sourceFiles;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              Text(title, style: theme.textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(
                description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              const _SectionHeading(
                icon: Icons.play_circle_outline,
                title: 'Preview',
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerLow,
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: SizedBox(
                  height: 300,
                  child: Scaffold(
                    body: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 680),
                          child: preview,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              const _SectionHeading(
                icon: Icons.code,
                title: 'Implementation',
              ),
              const SizedBox(height: 12),
              for (var index = 0; index < sourceFiles.length; index++) ...[
                _SourceCodeBlock(sourceFile: sourceFiles[index]),
                if (index != sourceFiles.length - 1) const SizedBox(height: 18),
              ],
            ]),
          ),
        ),
      ],
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(icon, size: 19, color: theme.colorScheme.primary),
        const SizedBox(width: 9),
        Text(title, style: theme.textTheme.titleMedium),
      ],
    );
  }
}

class _SourceCodeBlock extends StatefulWidget {
  const _SourceCodeBlock({required this.sourceFile});

  final WidgetbookSourceFile sourceFile;

  @override
  State<_SourceCodeBlock> createState() => _SourceCodeBlockState();
}

class _SourceCodeBlockState extends State<_SourceCodeBlock> {
  late Future<String> _source;
  bool _copied = false;

  @override
  void initState() {
    super.initState();
    _loadSource();
  }

  @override
  void didUpdateWidget(covariant _SourceCodeBlock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sourceFile.assetPath != widget.sourceFile.assetPath) {
      _loadSource();
      _copied = false;
    }
  }

  void _loadSource() {
    _source = rootBundle.loadString(widget.sourceFile.assetPath);
  }

  Future<void> _copy(String source) async {
    await Clipboard.setData(ClipboardData(text: source));
    if (mounted) setState(() => _copied = true);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF282C34),
        border: Border.all(color: const Color(0xFF414854)),
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 9, 8, 9),
            child: Row(
              children: [
                const Icon(
                  Icons.description_outlined,
                  size: 16,
                  color: Color(0xFFCBD5E1),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: SelectableText(
                    widget.sourceFile.displayPath,
                    style: const TextStyle(
                      color: Color(0xFFE2E8F0),
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                FutureBuilder<String>(
                  future: _source,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const SizedBox.shrink();

                    return TextButton.icon(
                      onPressed: () => _copy(snapshot.data!),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFFE2E8F0),
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 9),
                      ),
                      icon: Icon(
                        _copied ? Icons.check : Icons.copy_outlined,
                        size: 15,
                      ),
                      label: Text(_copied ? 'Copied' : 'Copy'),
                    );
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFF414854)),
          FutureBuilder<String>(
            future: _source,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(22),
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                );
              }

              if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Unable to load ${widget.sourceFile.assetPath}.\n'
                    'Add this file to flutter.assets in pubspec.yaml.\n\n'
                    '${snapshot.error}',
                    style: const TextStyle(color: Color(0xFFFFA6A6)),
                  ),
                );
              }

              final source = snapshot.data;
              if (source == null) return const SizedBox.shrink();

              return Container(
                width: double.infinity,
                color: const Color(0xFF282C34),
                child: SelectionArea(
                  child: SizedBox(
                    width: double.infinity,
                    child: HighlightView(
                      source,
                      language: 'dart',
                      theme: atomOneDarkTheme,
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
                      textStyle: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12.5,
                        height: 1.55,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
