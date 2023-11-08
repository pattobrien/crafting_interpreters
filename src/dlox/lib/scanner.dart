import 'package:dlox/dlox.dart';
import 'package:dlox/token.dart';
import 'package:dlox/token_type.dart';

class Scanner {
  final String source;
  final List<Token> tokens = [];

  Scanner(this.source);

  int start = 0;
  int current = 0;
  int line = 1; // used for track line numbers used in errors

  bool isAtEnd() {
    return current >= source.length;
  }

  List<Token> scanTokens() {
    while (!isAtEnd()) {
      // loop starts at the beginning of the next lexeme;
      start = current;
      scanToken();
    }

    tokens.add(Token(TokenType.EOF, '', line: line, literal: null));
    return tokens;
  }

  void scanToken() {
    final character = advance();
    return switch (character) {
      '(' => addToken(TokenType.LEFT_PARENTHESIS),
      ')' => addToken(TokenType.RIGHT_PARENTHESIS),
      '{' => addToken(TokenType.LEFT_BRACE),
      '}' => addToken(TokenType.RIGHT_BRACE),
      ',' => addToken(TokenType.COMMA),
      '.' => addToken(TokenType.DOT),
      '-' => addToken(TokenType.MINUS),
      '+' => addToken(TokenType.PLUS),
      ';' => addToken(TokenType.SEMICOLON),
      '*' => addToken(TokenType.STAR),
      '!' =>
        addToken(_isNextMatch('=') ? TokenType.BANG_EQUAL : TokenType.BANG),
      '=' =>
        addToken(_isNextMatch('=') ? TokenType.EQUAL_EQUAL : TokenType.EQUAL),
      '<' =>
        addToken(_isNextMatch('=') ? TokenType.LESS_EQUAL : TokenType.LESS),
      '>' => addToken(
          _isNextMatch('=') ? TokenType.GREATER_EQUAL : TokenType.GREATER),
      '/' => () {
          // check for a comment, which goes until the end of the line
          if (_isNextMatch('/')) {
            while (peek() != '\n' && !isAtEnd()) {
              advance();
            }
          } else {
            addToken(TokenType.SLASH);
          }
        }(),
      ' ' || '\\r' || '\\t' => () {},
      '\\n' => line++,
      '"' => handleString(),
      _ => () {
          if (isDigit(character)) {
            number();
          } else if (isAlpha(character)) {
            identifier();
          } else {
            DLox.reportError(line, 'Unexpected character.');
          }
        }(),
    };
  }

  void identifier() {
    while (isAlphaNumeric(peek())) {
      advance();
    }

    final text = source.substring(start, current);
    final type = keywords[text] ?? TokenType.IDENTIFIER;
    addToken(type);
  }

  static const keywords = {
    'and': TokenType.AND,
    'class': TokenType.CLASS,
    'else': TokenType.ELSE,
    'false': TokenType.FALSE,
    'for': TokenType.FOR,
    'fun': TokenType.FUN,
    'if': TokenType.IF,
    'nil': TokenType.NIL,
    'or': TokenType.OR,
    'print': TokenType.PRINT,
    'return': TokenType.RETURN,
    'super': TokenType.SUPER,
    'this': TokenType.THIS,
    'true': TokenType.TRUE,
    'var': TokenType.VAR,
    'while': TokenType.WHILE,
  };

  bool isAlpha(String c) {
    return (c.compareTo('a') >= 0 && c.compareTo('z') <= 0) ||
        (c.compareTo('A') >= 0 && c.compareTo('Z') <= 0) ||
        c == '_';
  }

  bool isAlphaNumeric(String c) {
    return isAlpha(c) || isDigit(c);
  }

  void number() {
    while (isDigit(peek())) {
      advance();
    }

    // Look for a fractional part.
    if (peek() == '.' && isDigit(peekNext())) {
      // Consume the "."
      advance();

      while (isDigit(peek())) {
        advance();
      }
    }

    addToken(TokenType.NUMBER, double.parse(source.substring(start, current)));
  }

  String peekNext() {
    if (current + 1 >= source.length) return '\\0';
    return source[current + 1];
  }

  bool isDigit(String character) {
    return character.compareTo('0') >= 0 && character.compareTo('9') <= 0;
  }

  void handleString() {
    while (peek() != '"' && !isAtEnd()) {
      if (peek() == '\\n') line++;
      advance();
    }

    if (isAtEnd()) {
      DLox.reportError(line, 'Unterminated string.');
      return;
    }

    advance();

    final stringValue = source.substring(start + 1, current - 1);
    addToken(TokenType.STRING, stringValue);
  }

  /// A lookahead (i.e. does not consume any charcters, unlike [advance])
  String peek() {
    if (isAtEnd()) return '\\0';
    return source[current];
  }

  bool _isNextMatch(String expected) {
    if (isAtEnd()) return false;
    if (source[current] != expected) return false;

    current++;
    return true;
  }

  void addToken(TokenType type, [Object? literal]) {
    final lexeme = source.substring(start, current);
    tokens.add(Token(type, lexeme, literal: literal, line: line));
  }

  String advance() {
    return source[current++];
  }
}
