import 'dart:io';

import 'package:dlox/token.dart';
import 'package:dlox/token_type.dart';

import 'ast/expression.dart';
import 'ast/interpreter.dart';
import 'parser.dart';
import 'scanner.dart';

class DLox {
  static bool hadError = false;
  static bool hadRuntimeError = false;

  static final interpreter = Interpreter();

  void main(List<String> args) {
    if (args.length > 1) {
      print('Usage: dlox [script]');
      exit(64);
    }
    // a `path` was passed in the args
    else if (args.length == 1) {
      runFile(args[0]);
    }
    // run the REPL
    else {
      runPrompt();
    }
  }

  static void reportError(int line, String message) {
    _report(line, "", message);
  }

  static void error(Token token, String message) {
    if (token.type == TokenType.EOF) {
      _report(token.line, " at end", message);
    } else {
      _report(token.line, " at '${token.lexeme}'", message);
    }
  }

  static void runtimeError(DloxRuntimeError error) {
    _report(error.token.line, "", error.message);
    hadRuntimeError = true;
  }

  static void _report(
    int line,
    String where,
    String message,
  ) {
    print('[ line $line] Error$where: $message');
  }

  void runFile(String path) {
    final file = File(path);
    run(file.readAsStringSync());

    // Indicate an error in the exit code.
    if (hadError) exit(65);
    if (hadRuntimeError) exit(70);
  }

  void runPrompt() {
    final input = stdin;

    while (true) {
      print('> ');
      final line = input.readLineSync();
      if (line == null) break;
      run(line);
      hadError = false;
    }
  }

  /// Execute our scanner and parser on some source code.
  void run(String source) {
    final scanner = Scanner(source);
    final tokens = scanner.scanTokens();
    final parser = Parser(tokens);
    List<Statement>? expression = parser.parse();

    // if (hadError) return;
    interpreter.interpret(expression!);

    // print(const AstPrinter().printNode(expression));

    // // print tokens, for now
    // for (final token in tokens) {
    //   print(token);
    // }
  }
}
