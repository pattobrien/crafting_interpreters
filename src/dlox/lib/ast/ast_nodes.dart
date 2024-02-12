import '../models/token.dart';
sealed class Expression {
  const Expression();

  T accept<T>(ExpressionVisitor<T> visitor);
}

class BinaryExpression extends Expression {
  const BinaryExpression(
    this.left,
    this.operator,
    this.right,
  );

  final Expression left;

  final Token operator;

  final Expression right;

  @override
  T accept<T>(ExpressionVisitor<T> visitor) {
    return visitor.visitBinaryExpression(this);
  }
}

class GroupingExpression extends Expression {
  const GroupingExpression(this.expression);

  final Expression expression;

  @override
  T accept<T>(ExpressionVisitor<T> visitor) {
    return visitor.visitGroupingExpression(this);
  }
}

class LiteralExpression extends Expression {
  const LiteralExpression(this.value);

  final Object? value;

  @override
  T accept<T>(ExpressionVisitor<T> visitor) {
    return visitor.visitLiteralExpression(this);
  }
}

class LogicalExpression extends Expression {
  const LogicalExpression(
    this.left,
    this.operator,
    this.right,
  );

  final Expression left;

  final Token operator;

  final Expression right;

  @override
  T accept<T>(ExpressionVisitor<T> visitor) {
    return visitor.visitLogicalExpression(this);
  }
}

class UnaryExpression extends Expression {
  const UnaryExpression(
    this.operator,
    this.right,
  );

  final Token operator;

  final Expression right;

  @override
  T accept<T>(ExpressionVisitor<T> visitor) {
    return visitor.visitUnaryExpression(this);
  }
}

class VariableExpression extends Expression {
  const VariableExpression(this.name);

  final Token name;

  @override
  T accept<T>(ExpressionVisitor<T> visitor) {
    return visitor.visitVariableExpression(this);
  }
}

class AssignmentExpression extends Expression {
  const AssignmentExpression(
    this.name,
    this.value,
  );

  final Token name;

  final Expression value;

  @override
  T accept<T>(ExpressionVisitor<T> visitor) {
    return visitor.visitAssignmentExpression(this);
  }
}

class CallExpression extends Expression {
  const CallExpression(
    this.callee,
    this.closingParenthesis,
    this.arguments,
  );

  final Expression callee;

  final Token closingParenthesis;

  final List<Expression> arguments;

  @override
  T accept<T>(ExpressionVisitor<T> visitor) {
    return visitor.visitCallExpression(this);
  }
}
sealed class Statement {
  const Statement();

  T accept<T>(StatementVisitor<T> visitor);
}

class ExpressionStatement extends Statement {
  const ExpressionStatement(this.expression);

  final Expression expression;

  @override
  T accept<T>(StatementVisitor<T> visitor) {
    return visitor.visitExpressionStatement(this);
  }
}

class PrintStatement extends Statement {
  const PrintStatement(this.expression);

  final Expression expression;

  @override
  T accept<T>(StatementVisitor<T> visitor) {
    return visitor.visitPrintStatement(this);
  }
}

class VariableStatement extends Statement {
  const VariableStatement(
    this.name,
    this.initializer,
  );

  final Token name;

  final Expression? initializer;

  @override
  T accept<T>(StatementVisitor<T> visitor) {
    return visitor.visitVariableStatement(this);
  }
}

class BlockStatement extends Statement {
  const BlockStatement(this.statements);

  final List<Statement> statements;

  @override
  T accept<T>(StatementVisitor<T> visitor) {
    return visitor.visitBlockStatement(this);
  }
}

class ClassStatement extends Statement {
  const ClassStatement(
    this.name,
    this.methods,
  );

  final Token name;

  final List<FunctionStatement> methods;

  @override
  T accept<T>(StatementVisitor<T> visitor) {
    return visitor.visitClassStatement(this);
  }
}

class FunctionStatement extends Statement {
  const FunctionStatement(
    this.name,
    this.params,
    this.body,
  );

  final Token name;

  final List<Token> params;

  final List<Statement> body;

  @override
  T accept<T>(StatementVisitor<T> visitor) {
    return visitor.visitFunctionStatement(this);
  }
}

class IfStatement extends Statement {
  const IfStatement(
    this.condition,
    this.thenBranch,
    this.elseBranch,
  );

  final Expression condition;

  final Statement thenBranch;

  final Statement? elseBranch;

  @override
  T accept<T>(StatementVisitor<T> visitor) {
    return visitor.visitIfStatement(this);
  }
}

class WhileStatement extends Statement {
  const WhileStatement(
    this.condition,
    this.body,
  );

  final Expression condition;

  final Statement body;

  @override
  T accept<T>(StatementVisitor<T> visitor) {
    return visitor.visitWhileStatement(this);
  }
}

class ReturnStatement extends Statement {
  const ReturnStatement(
    this.expression,
    this.keyword,
  );

  final Expression? expression;

  final Token keyword;

  @override
  T accept<T>(StatementVisitor<T> visitor) {
    return visitor.visitReturnStatement(this);
  }
}
abstract interface class ExpressionVisitor<T> {
  T visitBinaryExpression(BinaryExpression node);
  T visitGroupingExpression(GroupingExpression node);
  T visitLiteralExpression(LiteralExpression node);
  T visitLogicalExpression(LogicalExpression node);
  T visitUnaryExpression(UnaryExpression node);
  T visitVariableExpression(VariableExpression node);
  T visitAssignmentExpression(AssignmentExpression node);
  T visitCallExpression(CallExpression node);
}
abstract interface class StatementVisitor<T> {
  T visitExpressionStatement(ExpressionStatement node);
  T visitPrintStatement(PrintStatement node);
  T visitVariableStatement(VariableStatement node);
  T visitBlockStatement(BlockStatement node);
  T visitClassStatement(ClassStatement node);
  T visitFunctionStatement(FunctionStatement node);
  T visitIfStatement(IfStatement node);
  T visitWhileStatement(WhileStatement node);
  T visitReturnStatement(ReturnStatement node);
}
