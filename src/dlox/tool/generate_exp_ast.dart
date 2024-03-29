import 'dart:io';

import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:path/path.dart';

Future<void> main(List<String> args) async {
  // if (args.length != 1) {
  //   stderr.writeln('Usage: generate_ast <output directory>');
  //   exit(64);
  // }
  // final outputDir = args.first;
  final outputDir = normalize(
    join(Directory.current.path, 'lib/ast/ast_nodes.dart'),
  );

  final buffer = StringBuffer();

  buffer.writeCode(Directive.import('../models/token.dart'));

  final expressionTypes = <String, List<ExpDetail>>{
    'BinaryExpression': [
      (type: 'Expression', name: 'left'),
      (type: 'Token', name: 'operator'),
      (type: 'Expression', name: 'right'),
    ],
    'GroupingExpression': [
      (type: 'Expression', name: 'expression'),
    ],
    'LiteralExpression': [
      (type: 'Object?', name: 'value'),
    ],
    'LogicalExpression': [
      (type: 'Expression', name: 'left'),
      (type: 'Token', name: 'operator'),
      (type: 'Expression', name: 'right'),
    ],
    'UnaryExpression': [
      (type: 'Token', name: 'operator'),
      (type: 'Expression', name: 'right'),
    ],
    'VariableExpression': [
      (type: 'Token', name: 'name'),
    ],
    'AssignmentExpression': [
      (type: 'Token', name: 'name'),
      (type: 'Expression', name: 'value'),
    ],
    'CallExpression': [
      (type: 'Expression', name: 'callee'),
      (type: 'Token', name: 'closingParenthesis'),
      (type: 'List<Expression>', name: 'arguments'),
    ],
    'GetExpression': [
      (type: 'Expression', name: 'object'),
      (type: 'Token', name: 'name'),
    ],
    'SetExpression': [
      (type: 'Expression', name: 'object'),
      (type: 'Token', name: 'name'),
      (type: 'Expression', name: 'value'),
    ],
    'ThisExpression': [
      (type: 'Token', name: 'keyword'),
    ],
    'SuperExpression': [
      (type: 'Token', name: 'keyword'),
      (type: 'Token', name: 'method'),
    ],
  };

  defineAst(buffer, 'Expression', expressionTypes);

  final statementTypes = <String, List<ExpDetail>>{
    'ExpressionStatement': [
      (type: 'Expression', name: 'expression'),
    ],
    'PrintStatement': [
      (type: 'Expression', name: 'expression'),
    ],
    'VariableStatement': [
      (type: 'Token', name: 'name'),
      (type: 'Expression?', name: 'initializer'),
    ],
    'BlockStatement': [
      (type: 'List<Statement>', name: 'statements'),
    ],
    'ClassStatement': [
      (type: 'Token', name: 'name'),
      (type: 'List<FunctionStatement>', name: 'methods'),
      (type: 'VariableExpression?', name: 'superclass'),
    ],
    'FunctionStatement': [
      (type: 'Token', name: 'name'),
      (type: 'List<Token>', name: 'params'),
      (type: 'List<Statement>', name: 'body'),
    ],
    'IfStatement': [
      (type: 'Expression', name: 'condition'),
      (type: 'Statement', name: 'thenBranch'),
      (type: 'Statement?', name: 'elseBranch'),
    ],
    'WhileStatement': [
      (type: 'Expression', name: 'condition'),
      (type: 'Statement', name: 'body'),
    ],
    'ReturnStatement': [
      (type: 'Expression?', name: 'expression'),
      (type: 'Token', name: 'keyword'),
    ],
  };

  defineAst(buffer, 'Statement', statementTypes);

  defineVisitor(buffer, 'ExpressionVisitor', expressionTypes);
  defineVisitor(buffer, 'StatementVisitor', statementTypes);

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
  Map<String, List<ExpDetail>> types,
) {
  writer.writeCode(Library((builder) {
    builder.body.addAll([
      // -- BASE CLASS --
      Class((builder) {
        builder.sealed = true;
        builder.name = baseName;

        // -- single, unnamed constructor --
        builder.constructors.add(Constructor((builder) {
          builder.constant = true;
        }));

        builder.methods.add(
          Method((builder) {
            builder.name = 'accept';
            builder.returns = refer('T');
            builder.types.add(refer('T'));
            builder.requiredParameters.add(
              Parameter((builder) {
                builder.name = 'visitor';
                builder.type = TypeReference((builder) {
                  builder.symbol = '${baseName}Visitor';
                  builder.types.add(refer('T'));
                });
              }),
            );
          }),
        );
      }),

      // -- TYPES IMPLEMENTATIONS --
      for (final MapEntry(key: typeName, value: fields) in types.entries)
        Class((builder) {
          builder.name = typeName;
          builder.extend = refer(baseName);

          // -- single, unnamed constructor --
          builder.constructors.addAll([
            Constructor((builder) {
              builder.constant = true;
              builder.requiredParameters.addAll(fields.map((e) {
                return Parameter((builder) {
                  builder.toThis = true;
                  builder.name = e.name;
                });
              }));
            }),
          ]);

          // -- fields --
          builder.fields.addAll(fields.map((e) {
            return Field((builder) {
              builder.name = e.name;
              builder.type = refer(e.type);
              builder.modifier = FieldModifier.final$;
            });
          }));

          // -- visit method implementation --
          builder.methods.add(
            Method((builder) {
              builder.annotations.add(refer('override'));
              builder.name = 'accept';
              builder.types.add(refer('T'));
              builder.returns = refer('T');
              builder.requiredParameters.add(
                Parameter((builder) {
                  builder.name = 'visitor';
                  builder.type = refer('${baseName}Visitor<T>');
                }),
              );

              // -- method body --
              builder.body = Block((builder) {
                final visitMethodName = 'visit$typeName';
                builder.addExpression(
                  refer('visitor').property(visitMethodName).call(
                    [refer('this')],
                  ).returned,
                );
              });
            }),
          );
        }),
    ]);
  }));
}

void defineVisitorMethod(
  StringBuffer writer,
  String baseName,
) {}

void defineVisitor(
  StringBuffer writer,
  String baseName,
  Map<String, List<ExpDetail>> types,
) {
  final clazz = Class((builder) {
    builder.abstract = true;
    builder.modifier = ClassModifier.interface;
    builder.name = baseName;
    builder.types.add(refer('T'));

    // -- visit methods --
    builder.methods.addAll([
      for (final MapEntry(key: typeName) in types.entries)
        Method((builder) {
          builder.name = 'visit$typeName';
          builder.returns = refer('T');
          builder.requiredParameters.add(
            Parameter((builder) {
              builder.type = refer(typeName);
              builder.name = 'node';
            }),
          );
        }),
    ]);
  });

  writer.writeCode(clazz);
}

typedef ExpDetail = ({String type, String name});

extension BufferCodeWriter on StringBuffer {
  void writeCode(Spec spec) {
    final emitter = DartEmitter(useNullSafetySyntax: true);
    final formatter = DartFormatter();

    final validatedCode = spec.accept(emitter);
    write(formatter.format(validatedCode.toString()));
  }
}
