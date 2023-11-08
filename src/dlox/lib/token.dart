import 'package:dlox/token_type.dart';

class Token {
  final TokenType type;
  final String lexeme;
  final Object? literal;
  final int line;

  const Token(
    this.type,
    this.lexeme, {
    required this.literal,
    required this.line,
  });

  @override
  String toString() {
    return '${type.name} $lexeme $literal';
  }
}
