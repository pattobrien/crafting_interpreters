import 'package:dlox/ast/expression.dart';
import 'package:dlox/dlox.dart';
import 'package:dlox/token.dart';

import '../token_type.dart';

class Interpreter implements Visitor<Object?> {
  const Interpreter();

  void interpret(Expression expression) {
    try {
      Object? value = evaluate(expression);
      print(value);
    } on DloxRuntimeError catch (error) {
      DLox.runtimeError(error);
    }
  }

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
    throw DloxRuntimeError(operator, "Operands must be numbers.");
  }

  void checkNumberOperand(Token operator, Object? operand) {
    if (operand is num) return;
    throw DloxRuntimeError(operator, "Operand must be a number.");
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
}

class DloxRuntimeError implements Exception {
  final Token token;
  final String message;

  const DloxRuntimeError(this.token, this.message);

  @override
  String toString() => message;
}
