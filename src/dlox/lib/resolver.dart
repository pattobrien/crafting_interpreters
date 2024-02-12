import 'ast/ast_nodes.dart';
import 'dlox.dart';
import 'interpreter.dart';
import 'models/token.dart';

/// Determines where variables and functions are declared and what they refer to.
///
/// Unlike the [Interpreter], [Resolver] touches every AstNode once, regardless
/// of control flow, to ensure that all variables are properly declared and
/// used.
///
/// The most interesting visit methods are: [visitVariableStatement],
/// [visitVariableExpression], [visitFunctionStatement], and [visitReturnStatement].
///
/// The resolver is initialized and run by the [DLox.run] method.
class Resolver implements ExpressionVisitor<void>, StatementVisitor<void> {
  Resolver(this.interpreter);

  final Interpreter interpreter;

  final _scopes = <Map<String, bool>>[];
  FunctionType _currentFunction = FunctionType.none;

  /// Walks a list of statements and resolves each one.
  void resolveStatements(List<Statement> statements) {
    for (final statement in statements) {
      resolveStatement(statement);
    }
  }

  /// Apply the visitor to a statement.
  void resolveStatement(Statement statement) {
    statement.accept(this);
  }

  /// Apply the visitor to an expression.
  void resolveExpression(Expression expression) {
    expression.accept(this);
  }

  /// Resolves a function's parameters and body.
  ///
  /// To be used for both function and method declarations.
  void resolveFunction(FunctionStatement node, FunctionType type) {
    final enclosingFunction = _currentFunction;
    _currentFunction = type;

    beginScope();
    for (final param in node.params) {
      declareIdentifier(param);
      defineIdentifier(param);
    }
    resolveStatements(node.body);
    endScope();

    _currentFunction = enclosingFunction;
  }

  void beginScope() {
    _scopes.add({});
  }

  void endScope() {
    _scopes.removeLast();
  }

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    resolveExpression(node.value);
    resolveLocal(node, node.name);
  }

  @override
  void visitBinaryExpression(BinaryExpression node) {
    resolveExpression(node.left);
    resolveExpression(node.right);
  }

  @override
  void visitBlockStatement(BlockStatement node) {
    beginScope();
    resolveStatements(node.statements);
    endScope();
  }

  @override
  void visitCallExpression(CallExpression node) {
    resolveExpression(node.callee);
    node.arguments.forEach(resolveExpression);
  }

  @override
  void visitExpressionStatement(ExpressionStatement node) {
    resolveExpression(node.expression);
  }

  @override
  void visitFunctionStatement(FunctionStatement node) {
    declareIdentifier(node.name);
    defineIdentifier(node.name);

    resolveFunction(node, FunctionType.function);
  }

  @override
  void visitGroupingExpression(GroupingExpression node) {
    resolveExpression(node.expression);
  }

  @override
  void visitIfStatement(IfStatement node) {
    resolveExpression(node.condition);
    resolveStatement(node.thenBranch);
    if (node.elseBranch != null) {
      resolveStatement(node.elseBranch!);
    }
  }

  /// Note: Literals don't mention any variables, and therefore there is no
  /// work to be done here.
  @override
  void visitLiteralExpression(LiteralExpression node) {}

  @override
  void visitLogicalExpression(LogicalExpression node) {
    resolveExpression(node.left);
    resolveExpression(node.right);
  }

  @override
  void visitPrintStatement(PrintStatement node) {
    resolveExpression(node.expression);
  }

  @override
  void visitReturnStatement(ReturnStatement node) {
    if (_currentFunction == FunctionType.none) {
      DLox.error(node.keyword, 'Cannot return from top-level code.');
    }
    if (node.expression != null) {
      resolveExpression(node.expression!);
    }
  }

  @override
  void visitUnaryExpression(UnaryExpression node) {
    resolveExpression(node.right);
  }

  @override
  void visitVariableExpression(VariableExpression node) {
    if (_scopes.isNotEmpty && _scopes.last[node.name.lexeme] == false) {
      throw DloxRuntimeError(
        node.name,
        'Cannot read local variable in its own initializer.',
      );
    }

    resolveLocal(node, node.name);
  }

  @override
  void visitClassStatement(ClassStatement node) {
    declareIdentifier(node.name);
    defineIdentifier(node.name);
  }

  /// Looks up the variable with [name] in any scope, starting from the innermost scope.
  void resolveLocal(Expression expression, Token name) {
    for (var i = _scopes.length - 1; i >= 0; i--) {
      if (_scopes[i].containsKey(name.lexeme)) {
        interpreter.resolve(expression, _scopes.length - 1 - i);
        return;
      }
    }
  }

  @override
  void visitVariableStatement(VariableStatement node) {
    declareIdentifier(node.name);
    if (node.initializer != null) {
      resolveExpression(node.initializer!);
    }
    defineIdentifier(node.name);
  }

  /// Adds the identifier (i.e. a class, function, or variable name) to the
  /// innermost scope.
  ///
  /// The variable is marked as `not ready yet` by setting its value to `false`.
  void declareIdentifier(Token name) {
    if (_scopes.isEmpty) return;
    final scope = _scopes.last;

    if (scope.containsKey(name.lexeme)) {
      DLox.error(name, 'Already an identifier with this name in this scope.');
    }

    scope[name.lexeme] = false;
    _scopes[_scopes.length - 1] = scope;
  }

  /// Marks the identifier as `ready` (i.e. it has been initialized).
  void defineIdentifier(Token name) {
    if (_scopes.isEmpty) return;
    final scope = _scopes.last;
    scope[name.lexeme] = true;
    _scopes[_scopes.length - 1] = scope;
  }

  @override
  void visitWhileStatement(WhileStatement node) {
    resolveExpression(node.condition);
    resolveStatement(node.body);
  }
}

enum FunctionType { none, function }
