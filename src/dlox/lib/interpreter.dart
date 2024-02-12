import 'dart:collection';

import 'ast/ast_nodes.dart';
import 'dlox.dart';
import 'environment.dart';
import 'functions/clock_callable.dart';
import 'models/lox_callable.dart';
import 'models/lox_class.dart';
import 'models/lox_function.dart';
import 'models/lox_instance.dart';
import 'models/token.dart';
import 'models/token_type.dart';

class Interpreter
    implements ExpressionVisitor<Object?>, StatementVisitor<void> {
  Interpreter() {
    globals.define('clock', const ClockCallable());
  }

  final Environment globals = Environment.global();

  Environment get environment => _selectedEnvironment ?? globals;

  Environment? _selectedEnvironment;

  /// Holds the depth of a local variable for each expression.
  final Map<Expression, int> _locals = HashMap();

  void interpret(List<Statement> statements) {
    try {
      for (final statement in statements) {
        execute(statement);
      }
    } on DloxRuntimeError catch (error) {
      DLox.runtimeError(error);
    }
  }

  void execute(Statement node) {
    node.accept(this);
  }

  /// Called by the [Resolver] to resolve the depth of a local variable.
  void resolve(Expression expr, int depth) {
    _locals[expr] = depth;
  }

  /// Evaluates the expression into a literal value.
  ///
  /// E.g. BinaryExpression of `1 + 1` evaluates to: `2`
  Object? evaluate(Expression node) {
    return node.accept(this);
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
  Object? visitBinaryExpression(BinaryExpression node) {
    Object? left = evaluate(node.left);
    Object? right = evaluate(node.right);

    switch (node.operator.type) {
      case TokenType.MINUS:
        checkNumberOperands(node.operator, left, right);
        return (left as num) - (right as num);
      case TokenType.SLASH:
        checkNumberOperands(node.operator, left, right);
        return (left as num) / (right as num);
      case TokenType.STAR:
        checkNumberOperands(node.operator, left, right);
        return (left as num) * (right as num);
      case TokenType.PLUS:
        if (left is num && right is num) return left + right;
        if (left is String && right is String) return left + right;

        throw DloxRuntimeError(
          node.operator,
          'Operands must be two numbers or two strings.',
        );
      case TokenType.GREATER:
        checkNumberOperands(node.operator, left, right);
        return (left as num) > (right as num);
      case TokenType.GREATER_EQUAL:
        checkNumberOperands(node.operator, left, right);
        return (left as num) >= (right as num);
      case TokenType.LESS:
        checkNumberOperands(node.operator, left, right);
        return (left as num) < (right as num);
      case TokenType.LESS_EQUAL:
        checkNumberOperands(node.operator, left, right);
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
  Object? visitGroupingExpression(GroupingExpression node) {
    return evaluate(node.expression);
  }

  @override
  Object? visitLiteralExpression(LiteralExpression node) {
    return node.value;
  }

  @override
  Object? visitUnaryExpression(UnaryExpression node) {
    Object? right = evaluate(node.right);

    switch (node.operator.type) {
      case TokenType.BANG:
        return !isTruthy(right);
      case TokenType.MINUS:
        checkNumberOperand(node.operator, right);
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
  Object? visitGetExpression(GetExpression node) {
    Object? object = evaluate(node.object);
    if (object is! LoxInstance) {
      throw DloxRuntimeError(
        node.name,
        'Only instances can have properties.',
      );
    }

    // note: dynamic dispatch, since we look up the name of the property during
    // runtime, rather than statically at compile time.
    return object.get(node.name);
  }

  @override
  Object? visitSetExpression(SetExpression node) {
    Object? object = evaluate(node.object);
    if (object is! LoxInstance) {
      throw DloxRuntimeError(
        node.name,
        'Only instances can have fields.',
      );
    }

    Object? value = evaluate(node.value);
    object.set(node.name, value);
    return value;
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
    // final value = environment.get(node.name);
    // return value;
    return lookUpVariable(node.name, node);
  }

  Object? lookUpVariable(Token name, Expression expr) {
    int? distance = _locals[expr];
    if (distance != null) {
      return _selectedEnvironment!.getAt(distance, name.lexeme);
    } else {
      return globals.get(name);
    }
  }

  @override
  Object? visitAssignmentExpression(
    AssignmentExpression node,
  ) {
    Object? value = evaluate(node.value);
    // environment.assign(node.name, value);
    // return value;

    int? distance = _locals[node];
    if (distance != null) {
      _selectedEnvironment!.assignAt(distance, node.name, value);
    } else {
      globals.assign(node.name, value);
    }

    return value;
  }

  @override
  void visitBlockStatement(BlockStatement node) {
    executeBlock(
      node.statements,
      Environment.fromParent(environment),
    );
  }

  void executeBlock(
    List<Statement> statements,
    Environment environment,
  ) {
    final previous = this.environment;
    try {
      _selectedEnvironment = environment;

      for (final statement in statements) {
        execute(statement);
      }
    } finally {
      _selectedEnvironment = previous;
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

  /// Continues to evaluate the condition until it's false, while executing the
  /// body of the [node].
  @override
  void visitWhileStatement(WhileStatement node) {
    while (isTruthy(evaluate(node.condition))) {
      execute(node.body);
    }
  }

  @override
  Object? visitCallExpression(CallExpression node) {
    Object? callee = evaluate(node.callee);
    List<Object?> arguments = [];
    for (final argument in node.arguments) {
      arguments.add(evaluate(argument));
    }

    if (callee is! LoxCallable) {
      throw DloxRuntimeError(
        node.closingParenthesis,
        'Can only call functions and classes.',
      );
    }

    if (arguments.length != callee.arity) {
      throw DloxRuntimeError(
        node.closingParenthesis,
        'Expected ${callee.arity} arguments but got ${arguments.length}.',
      );
    }
    return callee.call(this, arguments);
  }

  @override
  void visitFunctionStatement(FunctionStatement node) {
    LoxFunction function = LoxFunction(node, environment, isInitializer: false);
    environment.define(node.name.lexeme, function);
  }

  @override
  void visitReturnStatement(ReturnStatement node) {
    Object? value;
    if (node.expression != null) value = evaluate(node.expression!);

    throw Return(value);
  }

  /// Converts a [ClassStatement] node into a [LoxClass] instance.
  @override
  void visitClassStatement(ClassStatement node) {
    // evaluates the superclass (if one exists), and checks (at runtime) if
    // it's a class.
    Object? superclass;
    if (node.superclass != null) {
      superclass = evaluate(node.superclass!);
      if (superclass is! LoxClass) {
        throw DloxRuntimeError(
          node.superclass!.name,
          'Superclass must be a class.',
        );
      }
    }

    // creates a new scope for the class
    environment.define(node.name.lexeme, null);

    final methods = <String, LoxFunction>{};
    for (final method in node.methods) {
      methods[method.name.lexeme] = LoxFunction(
        method,
        environment,
        isInitializer: method.name.lexeme == 'init',
      );
    }

    final clazz = LoxClass(
      node.name.lexeme,
      methods,
      superclass: superclass as LoxClass?,
    );
    environment.assign(node.name, clazz);
  }

  @override
  Object? visitThisExpression(ThisExpression node) {
    return lookUpVariable(node.keyword, node);
  }
}

class DloxRuntimeError implements Exception {
  final Token token;
  final String message;

  const DloxRuntimeError(this.token, this.message);

  @override
  String toString() => message;
}

class Return implements Exception {
  final Object? value;

  const Return(this.value);
}
