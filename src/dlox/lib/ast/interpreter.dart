import '../dlox.dart';
import '../environment.dart';
import '../token.dart';
import '../token_type.dart';
import 'expression.dart';

class Interpreter
    implements ExpressionVisitor<Object?>, StatementVisitor<void> {
  Interpreter();

  Environment environment = Environment.global();

  void interpret(List<Statement> statements) {
    try {
      // Object? value = evaluate(expression);
      // print(value);
      for (final statement in statements) {
        execute(statement);
      }
    } on DloxRuntimeError catch (error) {
      DLox.runtimeError(error);
    }
  }

  void execute(Statement statement) {
    statement.accept(this);
  }

  /// Evaluates the expression into a literal value.
  ///
  /// E.g. BinaryExpression of `1 + 1` evaluates to: `2`
  Object? evaluate(Expression expression) {
    return expression.accept(this);
  }

  bool isTruthy(Object? object) {
    if (object == null) return false;
    if (object is bool) return object;
    return true;
  }

  void checkNumberOperands(Token operator, Object? left, Object? right) {
    if (left is num && right is num) return;
    throw DloxRuntimeError(operator, 'Operands must be numbers.');
  }

  void checkNumberOperand(Token operator, Object? operand) {
    if (operand is num) return;
    throw DloxRuntimeError(operator, 'Operand must be a number.');
  }

  /// Compares two objects for equality that may or may not have the same type.
  bool isEqual(Object? a, Object? b) {
    if (a == null && b == null) return true;
    if (a == null) return false;
    return a == b;
  }

  @override
  Object? visitBinaryExpression(BinaryExpression expression) {
    Object? left = evaluate(expression.left);
    Object? right = evaluate(expression.right);

    switch (expression.operator.type) {
      case TokenType.MINUS:
        checkNumberOperands(expression.operator, left, right);
        return (left as num) - (right as num);
      case TokenType.SLASH:
        checkNumberOperands(expression.operator, left, right);
        return (left as num) / (right as num);
      case TokenType.STAR:
        checkNumberOperands(expression.operator, left, right);
        return (left as num) * (right as num);
      case TokenType.PLUS:
        if (left is num && right is num) return left + right;
        if (left is String && right is String) return left + right;

        throw DloxRuntimeError(
          expression.operator,
          'Operands must be two numbers or two strings.',
        );
      case TokenType.GREATER:
        checkNumberOperands(expression.operator, left, right);
        return (left as num) > (right as num);
      case TokenType.GREATER_EQUAL:
        checkNumberOperands(expression.operator, left, right);
        return (left as num) >= (right as num);
      case TokenType.LESS:
        checkNumberOperands(expression.operator, left, right);
        return (left as num) < (right as num);
      case TokenType.LESS_EQUAL:
        checkNumberOperands(expression.operator, left, right);
        return (left as num) <= (right as num);
      case TokenType.BANG_EQUAL:
        return !isEqual(left, right);
      case TokenType.EQUAL_EQUAL:
        double.infinity;
        return isEqual(left, right);
      default:
    }
    // TODO: handle error
    return null;
  }

  @override
  Object? visitGroupingExpression(GroupingExpression expression) {
    return evaluate(expression.expression);
  }

  @override
  Object? visitLiteralExpression(LiteralExpression expression) {
    return expression.value;
  }

  @override
  Object? visitUnaryExpression(UnaryExpression expression) {
    Object? right = evaluate(expression.right);

    switch (expression.operator.type) {
      case TokenType.BANG:
        return !isTruthy(right);
      case TokenType.MINUS:
        checkNumberOperand(expression.operator, right);
        return -(right as num);
      default:
        // TODO: handle error
        return null;
    }
  }

  @override
  void visitExpressionStatement(ExpressionStatement node) {
    evaluate(node.expression);
  }

  @override
  void visitPrintStatement(PrintStatement node) {
    Object? value = evaluate(node.expression);
    print(value);
  }

  @override
  void visitVariableStatement(VariableStatement node) {
    Object? value;

    if (node.initializer != null) {
      value = evaluate(node.initializer!);
    }
    environment.define(node.name.lexeme, value);
  }

  @override
  Object? visitVariableExpression(VariableExpression node) {
    return environment.get(node.name);
  }

  @override
  Object? visitAssignmentExpression(
    AssignmentExpression node,
  ) {
    Object? value = evaluate(node.value);
    environment.assign(node.name, node.value);
    return value;
  }

  @override
  void visitBlockStatement(BlockStatement statementVisitor) {
    executeBlock(
      statementVisitor.statements,
      Environment.fromParent(environment),
    );
  }

  void executeBlock(
    List<Statement> statements,
    Environment environment,
  ) {
    final previous = this.environment;
    try {
      this.environment = environment;

      for (final statement in statements) {
        execute(statement);
      }
    } finally {
      this.environment = previous;
    }
  }

  @override
  void visitIfStatement(IfStatement node) {
    if (isTruthy(evaluate(node.condition))) {
      execute(node.thenBranch);
    } else {
      if (node.elseBranch != null) {
        execute(node.elseBranch!);
      }
    }
  }

  /// Evaluates the left expression and returns early depending on the value
  /// and whether the operator is an AND or OR token.
  @override
  Object? visitLogicalExpression(LogicalExpression node) {
    Object? leftValue = evaluate(node.left);

    switch (node.operator.type) {
      case TokenType.OR when isTruthy(leftValue):
        return leftValue;
      case TokenType.AND when !isTruthy(leftValue):
        return leftValue;
      default:
        return evaluate(node.right);
    }
  }
}

class DloxRuntimeError implements Exception {
  final Token token;
  final String message;

  const DloxRuntimeError(this.token, this.message);

  @override
  String toString() => message;
}
