import '../token.dart';

sealed class Expression {
  const Expression();
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
}

class GroupingExpression extends Expression {
  const GroupingExpression(
    this.expression,
  );

  final Expression expression;
}

class LiteralExpression extends Expression {
  const LiteralExpression(
    this.value,
  );

  final Object value;
}

class UnaryExpression extends Expression {
  const UnaryExpression(
    this.operator,
    this.right,
  );

  final Token operator;
  final Expression right;
}

