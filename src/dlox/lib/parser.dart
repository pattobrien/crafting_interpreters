import 'ast/ast_nodes.dart';
import 'dlox.dart';
import 'models/function_kind.dart';
import 'models/token.dart';
import 'models/token_type.dart';

/// Takes a flat list of [tokens] and outputs AstNodes.
class Parser {
  Parser(this.tokens);

  List<Token> tokens;
  int current = 0;

  Token get currentToken => tokens[current];

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
      if (match([TokenType.CLASS])) {
        return parseClassDeclaration();
      }
      if (match([TokenType.FUN])) {
        return parseFunctionDeclaration(FunctionKind.function);
      }
      if (match([TokenType.VAR])) return parseVarDeclaration();
      return parseStatement();
    } on ParserError {
      synchronize();
      return null;
    }
  }

  ClassStatement parseClassDeclaration() {
    Token name = consumeToken(TokenType.IDENTIFIER, 'Expect class name.');

    consumeToken(
      TokenType.LEFT_BRACE,
      'Expect "{" after class name.',
    );

    List<FunctionStatement> methods = [];
    while (!checkToken(TokenType.RIGHT_BRACE) && !isAtEnd()) {
      methods.add(parseFunctionDeclaration(FunctionKind.method));
    }

    consumeToken(
      TokenType.RIGHT_BRACE,
      'Expect "}" after class body.',
    );

    return ClassStatement(name, methods);
  }

  FunctionStatement parseFunctionDeclaration(FunctionKind kind) {
    Token name = consumeToken(
      TokenType.IDENTIFIER,
      'Expected ${kind.name} name.',
    );

    consumeToken(
      TokenType.LEFT_PARENTHESIS,
      'Expected "(" after ${kind.name} name.',
    );

    List<Token> parameters = [];
    if (!checkToken(TokenType.RIGHT_PARENTHESIS)) {
      do {
        if (parameters.length >= 255) {
          reportError(peek(), 'Cant\'t have more than 255 parameters.');
        }

        parameters.add(
          consumeToken(TokenType.IDENTIFIER, 'Expected paremeter name.'),
        );
      } while (match([TokenType.COMMA]));
    }
    consumeToken(TokenType.RIGHT_PARENTHESIS, 'Expected ")" after parameters.');

    // -- parse the body --
    consumeToken(
      TokenType.LEFT_BRACE,
      'Expected "{" before "${kind.name}" body.',
    );

    final body = parseBlock();

    return FunctionStatement(name, parameters, body);
  }

  Statement? parseVarDeclaration() {
    Token name = consumeToken(TokenType.IDENTIFIER, 'Expect variable name.');
    Expression? initializer;

    if (match([TokenType.EQUAL])) {
      initializer = parseExpression();
    }
    consumeToken(
        TokenType.SEMICOLON, 'Expected ";" after variable declaration.');
    return VariableStatement(name, initializer);
  }

  Statement parseStatement() {
    if (match([TokenType.FOR])) return parseForStatement();
    if (match([TokenType.IF])) return parseIfStatement();
    if (match([TokenType.RETURN])) return parseReturnStatement();
    if (match([TokenType.PRINT])) return parsePrintStatement();
    if (match([TokenType.LEFT_BRACE])) return BlockStatement(parseBlock());
    return parseExpressionStatement();
  }

  ReturnStatement parseReturnStatement() {
    Token keyword = getPreviousToken();
    Expression? value;
    if (!checkToken(TokenType.SEMICOLON)) {
      value = parseExpression();
    }

    consumeToken(TokenType.SEMICOLON, 'Expected ";" after return value.');

    return ReturnStatement(value, keyword);
  }

  Statement parseForStatement() {
    consumeToken(TokenType.LEFT_PARENTHESIS, 'Expect "(" after "for".');

    // -- initializer clause --
    Statement? initializer;
    if (match([TokenType.SEMICOLON])) {
      initializer = null;
    } else if (match([TokenType.VAR])) {
      initializer = parseVarDeclaration();
    } else {
      initializer = parseExpressionStatement();
    }

    // -- condition clause --
    Expression? condition;
    if (!checkToken(TokenType.SEMICOLON)) {
      condition = parseExpression();
    }
    consumeToken(TokenType.SEMICOLON, 'Expected ";" after loop condition.');

    // -- increment clause --
    Expression? increment;
    if (!checkToken(TokenType.RIGHT_PARENTHESIS)) {
      increment = parseExpression();
    }
    consumeToken(
      TokenType.RIGHT_PARENTHESIS,
      'Expected ")" after for clauses.',
    );

    Statement body = parseStatement();

    // below is where we "desugar" by turning the for loop syntax into
    // a while loop, with statements that manually set the variable and
    // increment it
    if (increment != null) {
      body = BlockStatement([
        body,
        ExpressionStatement(increment),
      ]);
    }

    condition ??= LiteralExpression(true);
    body = WhileStatement(condition, body);

    if (initializer != null) {
      body = BlockStatement([initializer, body]);
    }

    return body;
  }

  WhileStatement parseWhile() {
    consumeToken(TokenType.LEFT_PARENTHESIS, 'Expect "(" after "while".');
    Expression condition = parseExpression();
    consumeToken(TokenType.RIGHT_PARENTHESIS, 'Expect ")" after condition.');
    Statement body = parseStatement();
    return WhileStatement(condition, body);
  }

  /// Parses an `or` expression OR lower precedence (`and` exp and lower).
  Expression parseOr() {
    Expression expression = parseAnd();

    while (match([TokenType.OR])) {
      Token operator = getPreviousToken();
      Expression right = parseAnd();
      expression = LogicalExpression(expression, operator, right);
    }

    return expression;
  }

  /// Parses and returns an `and` expression OR lower precendence (i.e.
  /// assignment and lower).
  Expression parseAnd() {
    Expression exp = parseEquality();

    while (match([TokenType.AND])) {
      Token operator = getPreviousToken();
      Expression right = parseEquality();
      exp = LogicalExpression(exp, operator, right);
    }

    return exp;
  }

  IfStatement parseIfStatement() {
    consumeToken(TokenType.LEFT_PARENTHESIS, 'Expected "(" after "if".)');
    Expression condition = parseExpression();
    consumeToken(
        TokenType.RIGHT_PARENTHESIS, 'Expected ")" after if condition.');

    Statement thenBranch = parseStatement();
    Statement? elseBranch;
    if (match([TokenType.ELSE])) {
      elseBranch = parseStatement();
    }

    return IfStatement(condition, thenBranch, elseBranch);
  }

  List<Statement> parseBlock() {
    List<Statement> statements = [];
    while (!checkToken(TokenType.RIGHT_BRACE) && !isAtEnd()) {
      final declaration = parseDeclaration();
      if (declaration != null) {
        statements.add(declaration);
      }
    }
    consumeToken(TokenType.RIGHT_BRACE, 'Expect "}" after block.');
    return statements;
  }

  PrintStatement parsePrintStatement() {
    Expression value = parseExpression();
    consumeToken(TokenType.SEMICOLON, "Expect ';' after value.");
    return PrintStatement(value);
  }

  ExpressionStatement parseExpressionStatement() {
    Expression value = parseExpression();
    consumeToken(TokenType.SEMICOLON, "Expect ';' after value.");
    return ExpressionStatement(value);
  }

  Expression parseExpression() {
    return parseAssignmentExpression();
  }

  // note: this function is right-associative, so we recursively call
  // [parseAssignmentExpression] to parse the right hand side.
  Expression parseAssignmentExpression() {
    Expression leftHandExpr = parseOr();
    if (match([TokenType.EQUAL])) {
      Token equals = getPreviousToken();
      Expression rightHandExpr = parseAssignmentExpression();

      if (leftHandExpr is VariableExpression) {
        Token name = leftHandExpr.name;
        return AssignmentExpression(name, rightHandExpr);
      } else if (leftHandExpr is GetExpression) {
        return SetExpression(
          leftHandExpr.object,
          leftHandExpr.name,
          rightHandExpr,
        );
      }

      reportError(equals, 'Invalid assignment target.');
    }

    return leftHandExpr;
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

    // return parsePrimary();
    return parseCall();
  }

  Expression parseCall() {
    Expression exp = parsePrimary();
    while (true) {
      if (match([TokenType.LEFT_PARENTHESIS])) {
        exp = finishCall(exp);
      } else if (match([TokenType.DOT])) {
        Token name = consumeToken(
          TokenType.IDENTIFIER,
          'Expected property name after ".".',
        );
        exp = GetExpression(exp, name);
      } else {
        break;
      }
    }
    return exp;
  }

  Expression finishCall(Expression callee) {
    List<Expression> arguments = [];
    if (!checkToken(TokenType.RIGHT_PARENTHESIS)) {
      do {
        if (arguments.length >= 255) {
          reportError(peek(), 'Can\'t have more than 255 arguments.');
        }
        arguments.add(parseExpression());
      } while (match([TokenType.COMMA]));
    }

    Token closingParenthesis = consumeToken(
      TokenType.RIGHT_PARENTHESIS,
      'Expect ")" afer arguments.',
    );

    return CallExpression(callee, closingParenthesis, arguments);
  }

  /// Checks if the next token is of [type], and otherwise throws an error
  /// with [message].
  Token consumeToken(TokenType type, String message) {
    if (checkToken(type)) return advance();
    throw reportError(peek(), message);
  }

  /// Reports an error, but doesn't throw it.
  ParserError reportError(Token token, String message) {
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
      consumeToken(TokenType.RIGHT_PARENTHESIS, "Expect ')' after expression.");
      return GroupingExpression(exp);
    }

    throw reportError(peek(), 'Expect expression.');
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
    if (types.any((element) => checkToken(element))) {
      advance();
      return true;
    }
    return false;
  }

  bool checkToken(TokenType type) {
    if (isAtEnd()) return false;
    return peek().type == type;
  }

  Token advance() {
    if (!isAtEnd()) current++;
    return getPreviousToken();
  }

  /// Peeks at the next token, and returns true if it's the end of the file.
  bool isAtEnd() => peek().type == TokenType.EOF;

  Token peek() => tokens[current];

  Token getPreviousToken() => tokens[current - 1];
}

class ParserError implements Exception {
  const ParserError();
}
