import '../token.dart';
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
abstract interface class ExpressionVisitor<T> {
  T visitBinaryExpression(BinaryExpression expressionVisitor);
  T visitGroupingExpression(GroupingExpression expressionVisitor);
  T visitLiteralExpression(LiteralExpression expressionVisitor);
  T visitUnaryExpression(UnaryExpression expressionVisitor);
  T visitVariableExpression(VariableExpression expressionVisitor);
}
abstract interface class StatementVisitor<T> {
  T visitExpressionStatement(ExpressionStatement statementVisitor);
  T visitPrintStatement(PrintStatement statementVisitor);
  T visitVariableStatement(VariableStatement statementVisitor);
}
