// import 'expression.dart';

// /// Pretty prints recursive expressions into a simple output.
// ///
// /// Useful for ensuring a syntax tree has the expected structure.
// /// Example output is: `(* (- 123) (group 45.67))`
// class AstPrinter implements ExpressionVisitor<String> {
//   const AstPrinter();
//   String printNode(Expression exp) {
//     return exp.accept(this);
//   }

//   String parenthesize(String name, List<Expression> exps) {
//     final buffer = StringBuffer();
//     buffer.write('($name');
//     for (final exp in exps) {
//       buffer.write(' ${exp.accept(this)}');
//     }
//     buffer.write(')');
//     return buffer.toString();
//   }

//   @override
//   String visitBinaryExpression(BinaryExpression expression) {
//     return parenthesize(expression.operator.lexeme, [
//       expression.left,
//       expression.right,
//     ]);
//   }

//   @override
//   String visitGroupingExpression(GroupingExpression expression) {
//     return parenthesize('group', [
//       expression.expression,
//     ]);
//   }

//   @override
//   String visitLiteralExpression(LiteralExpression expression) {
//     return expression.value.toString();
//   }

//   @override
//   String visitUnaryExpression(UnaryExpression expression) {
//     return parenthesize(expression.operator.lexeme, [
//       expression.right,
//     ]);
//   }

//   @override
//   String visitVariableExpression(VariableExpression expressionVisitor) {
//     // TODO: implement visitVariableExpression
//     throw UnimplementedError();
//   }
// }
