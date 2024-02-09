import 'dart:io';

import 'package:path/path.dart';

Future<void> main(List<String> args) async {
  // if (args.length != 1) {
  //   stderr.writeln('Usage: generate_ast <output directory>');
  //   exit(64);
  // }
  // final outputDir = args.first;
  final outputDir =
      normalize(join(Directory.current.path, 'lib/ast/expression.dart'));

  final buffer = StringBuffer();
  defineAst(buffer, 'Expression', {
    'BinaryExpression': [
      (type: 'Expression', name: 'left'),
      (type: 'Token', name: 'operator'),
      (type: 'Expression', name: 'right'),
    ],
    'GroupingExpression': [
      (type: 'Expression', name: 'expression'),
    ],
    'LiteralExpression': [
      (type: 'Object', name: 'value'),
    ],
    'UnaryExpression': [
      (type: 'Token', name: 'operator'),
      (type: 'Expression', name: 'right'),
    ],
  });

  // write to file
  File(outputDir).writeAsStringSync(buffer.toString());
}

/// Outputs all AstNodes to the [writer].
///
/// Starts by creating a base class, then outputs the entire
/// map of [types].
void defineAst(
  StringBuffer writer,
  String baseName,
  Map<String, List<({String type, String name})>> types,
) {
  writer.write('''
import '../token.dart';

sealed class $baseName {
  const $baseName();
}

''');
  for (final typeEntry in types.entries) {
    final className = typeEntry.key;
    final parameters = typeEntry.value;
    writer.write('''
class $className extends $baseName {
  const $className(
${parameters.map((e) => '    this.${e.name},').join('\n')}
  );

${parameters.map((e) => '  final ${e.type} ${e.name};').join('\n')}
}

''');
  }
}

void defineVisitor(StringBuffer writer, String baseName,
    Map<String, List<({String type, String name})>> types) {
  writer.writeln('interface Visitor<T> {');

  for (final type in types.entries) {
    final name = type.key;
    writer.write('  T visit$name($name)');
  }

  writer.writeln('}');
}
