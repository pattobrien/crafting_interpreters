import 'ast/expression.dart';
import 'dlox.dart';
import 'token.dart';
import 'token_type.dart';

/// Takes a flat list of [tokens] and outputs AstNodes.
class Parser {
  Parser(this.tokens);

  List<Token> tokens;
  int current = 0;

  List<Statement> parse() {
    List<Statement> statements = [];
    while (!isAtEnd()) {
      final statement = parseDeclaration();
      if (statement != null) statements.add(statement);
    }
    return statements;
  }

  Statement? parseDeclaration() {
    try {
      if (match([TokenType.VAR])) return parseVarDeclaration();
      return parseStatement();
    } on ParserError {
      synchronize();
      return null;
    }
  }

  Statement? parseVarDeclaration() {
    Token name = consume(TokenType.IDENTIFIER, 'Expect variable name.');
    Expression? initializer;

    if (match([TokenType.EQUAL])) {
      initializer = parseExpression();
    }
    consume(TokenType.SEMICOLON, 'Expected ";" after variable declaration.');
    return VariableStatement(name, initializer);
  }

  Statement parseStatement() {
    if (match([TokenType.IF])) return parseIfStatement();
    if (match([TokenType.PRINT])) return parsePrintStatement();
    if (match([TokenType.LEFT_BRACE])) return BlockStatement(parseBlock());
    return parseExpressionStatement();
  }

  IfStatement parseIfStatement() {
    consume(TokenType.LEFT_PARENTHESIS, 'Expected "(" after "if".)');
    Expression condition = parseExpression();
    consume(TokenType.RIGHT_PARENTHESIS, 'Expected ")" after if condition.');

    Statement thenBranch = parseStatement();
    Statement? elseBranch;
    if (match([TokenType.ELSE])) {
      elseBranch = parseStatement();
    }

    return IfStatement(condition, thenBranch, elseBranch);
  }

  List<Statement> parseBlock() {
    List<Statement> statements = [];
    while (!check(TokenType.RIGHT_BRACE) && !isAtEnd()) {
      final declaration = parseDeclaration();
      if (declaration != null) {
        statements.add(declaration);
      }
    }
    consume(TokenType.RIGHT_BRACE, 'Expect "}" after block.');
    return statements;
  }

  PrintStatement parsePrintStatement() {
    Expression value = parseExpression();
    consume(TokenType.SEMICOLON, "Expect ';' after value.");
    return PrintStatement(value);
  }

  ExpressionStatement parseExpressionStatement() {
    Expression value = parseExpression();
    consume(TokenType.SEMICOLON, "Expect ';' after value.");
    return ExpressionStatement(value);
  }

  Expression parseExpression() {
    return parseAssignmentExpression();
  }

  // note: this function is right-associative, so we recursively call
  // [parseAssignmentExpression] to parse the right hand side.
  Expression parseAssignmentExpression() {
    Expression exp = parseEquality();
    if (match([TokenType.EQUAL])) {
      Token equals = getPreviousToken();
      Expression value = parseAssignmentExpression();

      if (exp is VariableExpression) {
        Token name = exp.name;
        return AssignmentExpression(name, value);
      }

      error(equals, 'Invalid assignment target.');
    }

    return exp;
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

  /// Checks if the next token is of [type], and otherwise throws an error
  /// with [message].
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

    if (match([TokenType.IDENTIFIER])) {
      return VariableExpression(getPreviousToken());
    }

    if (match([TokenType.LEFT_PARENTHESIS])) {
      Expression exp = parseExpression();
      consume(TokenType.RIGHT_PARENTHESIS, "Expect ')' after expression.");
      return GroupingExpression(exp);
    }

    throw error(peek(), 'Expect expression.');
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

  /// Returns true and advances if the next token matches any of [types].
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
