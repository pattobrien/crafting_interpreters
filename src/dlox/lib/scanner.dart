import 'dlox.dart';
import 'models/token.dart';
import 'models/token_type.dart';

class Scanner {
  final String source;
  final List<Token> tokens = [];

  Scanner(this.source);

  /// The index of the first character in the current lexeme being scanned.
  int startCharIndex = 0;

  /// The index of the current character being scanned.
  int currentCharIndex = 0;
  int currentLine = 1;

  bool isAtEnd() => currentCharIndex >= source.length;
  bool isNotAtEnd() => !isAtEnd();

  List<Token> scanTokens() {
    while (isNotAtEnd()) {
      // loop starts at the beginning of the next lexeme;
      startCharIndex = currentCharIndex;
      scanToken();
    }

    tokens.add(Token(TokenType.EOF, '', line: currentLine, literal: null));
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
      ' ' || '\r' || '\t' => () {},
      '\n' => currentLine++,
      '"' => handleString(),
      _ => () {
          if (isDigit(character)) {
            number();
          } else if (isAlpha(character)) {
            identifier();
          } else {
            DLox.reportError(currentLine, 'Unexpected character.');
          }
        }(),
    };
  }

  void identifier() {
    while (isAlphaNumeric(peek())) {
      advance();
    }

    final text = source.substring(startCharIndex, currentCharIndex);
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

    addToken(TokenType.NUMBER,
        double.parse(source.substring(startCharIndex, currentCharIndex)));
  }

  String peekNext() {
    if (currentCharIndex + 1 >= source.length) return '\\0';
    return source[currentCharIndex + 1];
  }

  bool isDigit(String character) {
    return character.compareTo('0') >= 0 && character.compareTo('9') <= 0;
  }

  void handleString() {
    while (peek() != '"' && !isAtEnd()) {
      if (peek() == '\\n') currentLine++;
      advance();
    }

    if (isAtEnd()) {
      DLox.reportError(currentLine, 'Unterminated string.');
      return;
    }

    advance();

    final stringValue =
        source.substring(startCharIndex + 1, currentCharIndex - 1);
    addToken(TokenType.STRING, stringValue);
  }

  /// A lookahead (i.e. does not consume any charcters, unlike [advance])
  String peek() {
    if (isAtEnd()) return '\\0';
    return source[currentCharIndex];
  }

  bool _isNextMatch(String expected) {
    if (isAtEnd()) return false;
    if (source[currentCharIndex] != expected) return false;

    currentCharIndex++;
    return true;
  }

  void addToken(TokenType type, [Object? literal]) {
    final lexeme = source.substring(startCharIndex, currentCharIndex);
    tokens.add(Token(type, lexeme, literal: literal, line: currentLine));
  }

  String advance() {
    return source[currentCharIndex++];
  }
}
