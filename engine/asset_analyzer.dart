import 'dart:io';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';

// Matches complete asset paths with all Flutter-supported extensions.
final _assetRegex = RegExp(
  r'assets/[a-zA-Z0-9_\-/.]+\.(png|jpg|jpeg|svg|webp|gif|json|ttf|otf|mp4|mp3|riv|lottie)',
);

void main() {
  final libDir = Directory('lib');
  if (!libDir.existsSync()) {
    stderr.writeln('[asset_analyzer] lib/ not found — run from project root.');
    return;
  }

  final dartFiles = libDir
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .toList();

  // ── Pass 1: build a global map of named identifiers → asset path ─────────────
  // Covers top-level variables and class/mixin/extension static fields.
  // Keys: plain field name ('logo') AND qualified name ('AppAssets.logo').
  final Map<String, String> namedAssets = {};
  for (final file in dartFiles) {
    _collectNamedAssets(file, namedAssets);
  }

  // ── Pass 2: resolve all asset usages across the entire codebase ──────────────
  final Set<String> usedAssets = {};
  for (final file in dartFiles) {
    _resolveUsages(file, namedAssets, usedAssets);
  }

  for (final path in usedAssets.toList()..sort()) {
    print(path);
  }
}

// ---------------------------------------------------------------------------
// Pass 1 — collect named declarations
// ---------------------------------------------------------------------------

void _collectNamedAssets(File file, Map<String, String> out) {
  final content = file.readAsStringSync();
  // Quick pre-filter: skip files that cannot contain an asset path.
  if (!content.contains('assets/')) return;

  CompilationUnit unit;
  try {
    unit = parseString(content: content, path: file.path).unit;
  } catch (_) {
    // Generated or malformed files are skipped gracefully.
    return;
  }

  for (final decl in unit.declarations) {
    switch (decl) {
      // const kLogoPath = 'assets/images/logo.png';
      case TopLevelVariableDeclaration():
        for (final v in decl.variables.variables) {
          _register(v.name.lexeme, v.initializer?.toSource(), null, out);
        }

      // class AppAssets { static const logo = 'assets/images/logo.png'; }
      case ClassDeclaration():
        _collectFromMembers(decl.name.lexeme, decl.members, out);

      // mixin AssetsMixin { ... }  /  extension AssetsExt on ... { ... }
      case MixinDeclaration():
        _collectFromMembers(decl.name.lexeme, decl.members, out);

      case ExtensionDeclaration():
        final name = decl.name?.lexeme;
        if (name != null) _collectFromMembers(name, decl.members, out);

      default:
        break;
    }
  }
}

void _collectFromMembers(
  String typeName,
  List<ClassMember> members,
  Map<String, String> out,
) {
  for (final member in members) {
    if (member is FieldDeclaration) {
      for (final v in member.fields.variables) {
        _register(v.name.lexeme, v.initializer?.toSource(), typeName, out);
      }
    }
  }
}

void _register(
  String name,
  String? initSource,
  String? typeName,
  Map<String, String> out,
) {
  if (initSource == null) return;
  final m = _assetRegex.firstMatch(initSource);
  if (m == null) return;
  final path = m.group(0)!;
  out[name] = path;
  if (typeName != null) out['$typeName.$name'] = path;
}

// ---------------------------------------------------------------------------
// Pass 2 — resolve usages
// ---------------------------------------------------------------------------

void _resolveUsages(
  File file,
  Map<String, String> namedAssets,
  Set<String> out,
) {
  final content = file.readAsStringSync();

  // 1. Direct literal paths — handles Image.asset('assets/...'), AssetImage('assets/...'), etc.
  for (final m in _assetRegex.allMatches(content)) {
    out.add(m.group(0)!);
  }

  // 2. Named references — word-boundary match to avoid false positives.
  //    Qualified names ('AppAssets.logo') are checked first and are precise.
  //    Plain names ('logo') are checked only if the path is not already resolved.
  for (final entry in namedAssets.entries) {
    if (out.contains(entry.value)) continue;
    final pattern = RegExp(r'\b' + RegExp.escape(entry.key) + r'\b');
    if (pattern.hasMatch(content)) {
      out.add(entry.value);
    }
  }
}
