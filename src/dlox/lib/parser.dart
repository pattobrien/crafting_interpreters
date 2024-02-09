import 'package:dlox/ast/expression.dart';
import 'package:dlox/dlox.dart';
import 'package:dlox/token.dart';
import 'package:dlox/token_type.dart';

class Parser {
  Parser(this.tokens);

  List<Token> tokens;
  int current = 0;

  Expression? parse() {
    try {
      return parseExpression();
    } on ParserError {
      return null;
    }
  }

  Expression parseExpression() {
    return parseEquality();
  }

  Expression parseEquality() {
    Expression expression = parseComparison();
    while (match([TokenType.BANG_EQUAL, TokenType.EQUAL_EQUAL])) {
      Token operator = getPreviousToken();
      Expression right = parseComparison();
      expression = BinaryExpression(expression, operator, right);
    }
    return expression;
  }

  Expression parseComparison() {
    Expression expression = parseTerm();

    while (match([
      TokenType.GREATER,
      TokenType.GREATER_EQUAL,
      TokenType.LESS,
      TokenType.LESS_EQUAL,
    ])) {
      Token operator = getPreviousToken();
      Expression rightExp = parseTerm();
      expression = BinaryExpression(expression, operator, rightExp);
    }

    return expression;
  }

  Expression parseTerm() {
    Expression currentExp = parseFactor();

    while (match([
      TokenType.MINUS,
      TokenType.PLUS,
    ])) {
      Token operator = getPreviousToken();
      Expression right = parseFactor();
      currentExp = BinaryExpression(currentExp, operator, right);
    }

    return currentExp;
  }

  Expression parseFactor() {
    Expression currentExp = parseUnary();

    while (match([
      TokenType.SLASH,
      TokenType.STAR,
    ])) {
      Token operator = getPreviousToken();
      Expression right = parseFactor();
      currentExp = BinaryExpression(currentExp, operator, right);
    }

    return currentExp;
  }

  Expression parseUnary() {
    if (match([TokenType.BANG, TokenType.MINUS])) {
      Token operator = getPreviousToken();
      Expression right = parseUnary();
      return UnaryExpression(operator, right);
    }

    return parsePrimary();
  }

  Token consume(TokenType type, String message) {
    if (check(type)) return advance();
    throw error(peek(), message);
  }

  ParserError error(Token token, String message) {
    DLox.error(token, message);
    return ParserError();
  }

  Expression parsePrimary() {
    if (match([TokenType.FALSE])) return LiteralExpression(false);
    if (match([TokenType.TRUE])) return LiteralExpression(true);
    if (match([TokenType.NIL])) return LiteralExpression(null);

    if (match([TokenType.NUMBER, TokenType.STRING])) {
      return LiteralExpression(getPreviousToken().literal);
    }

    if (match([TokenType.LEFT_PARENTHESIS])) {
      Expression exp = parseExpression();
      consume(TokenType.RIGHT_PARENTHESIS, "Expect ')' after expression.");
      return GroupingExpression(exp);
    }

    throw error(peek(), "Expect expression.");
  }

  /// After an error is thrown, this method should be called in order to discard
  /// the remaining tokens in the statement until the next statement is found.
  void synchronize() {
    advance();

    while (!isAtEnd()) {
      if (getPreviousToken().type == TokenType.SEMICOLON) return;

      switch (peek().type) {
        case TokenType.CLASS:
        case TokenType.FUN:
        case TokenType.VAR:
        case TokenType.FOR:
        case TokenType.IF:
        case TokenType.WHILE:
        case TokenType.PRINT:
        case TokenType.RETURN:
          return;
        default:
          advance();
      }
    }
  }

  bool match(List<TokenType> types) {
    if (types.any((element) => check(element))) {
      advance();
      return true;
    }
    return false;
  }

  bool check(TokenType type) {
    if (isAtEnd()) return false;
    return peek().type == type;
  }

  Token advance() {
    if (!isAtEnd()) current++;
    return getPreviousToken();
  }

  bool isAtEnd() => peek().type == TokenType.EOF;

  Token peek() => tokens[current];

  Token getPreviousToken() => tokens[current - 1];
}

class ParserError implements Exception {
  const ParserError();
}
