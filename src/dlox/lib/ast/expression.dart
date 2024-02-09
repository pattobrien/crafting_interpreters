import '../token.dart';

sealed class Expression {
  const Expression();

  T accept<T>(Visitor<T> visitor);
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
  T accept<T>(Visitor<T> visitor) {
    return visitor.visitBinaryExpression(this);
  }
}

class GroupingExpression extends Expression {
  const GroupingExpression(this.expression);

  final Expression expression;

  @override
  T accept<T>(Visitor<T> visitor) {
    return visitor.visitGroupingExpression(this);
  }
}

class LiteralExpression extends Expression {
  const LiteralExpression(this.value);

  final Object? value;

  @override
  T accept<T>(Visitor<T> visitor) {
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
  T accept<T>(Visitor<T> visitor) {
    return visitor.visitUnaryExpression(this);
  }
}
abstract interface class Visitor<T> {
  T visitBinaryExpression(BinaryExpression expression);
  T visitGroupingExpression(GroupingExpression expression);
  T visitLiteralExpression(LiteralExpression expression);
  T visitUnaryExpression(UnaryExpression expression);
}
