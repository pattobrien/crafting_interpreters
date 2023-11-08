import 'dart:io';

import 'scanner.dart';

class DLox {
  bool hadError = false;

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

    // print tokens, for now
    for (final token in tokens) {
      print(token);
    }
  }
}
