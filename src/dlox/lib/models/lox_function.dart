import '../ast/ast_nodes.dart';
import '../environment.dart';
import '../interpreter.dart';
import 'lox_callable.dart';

/// A user-defined Function.
///
/// Functions create their own environments before every call. see:
/// - https://craftinginterpreters.com/functions.html#function-objects
/// - param -> arg binding diagram: https://craftinginterpreters.com/image/functions/binding.png
class LoxFunction implements LoxCallable {
  const LoxFunction(this.functionDeclaration);

  final FunctionStatement functionDeclaration;

  @override
  int get arity => functionDeclaration.params.length;

  /// Where all user-defined function invocations are born.
  @override
  Object? call(Interpreter interpreter, List<Object?> arguments) {
    final environment = Environment.fromParent(interpreter.globals);
    for (var i = 0; i < functionDeclaration.params.length; i++) {
      environment.define(functionDeclaration.params[i].lexeme, arguments[i]);
    }

    interpreter.executeBlock(functionDeclaration.body, environment);
    return null;
  }

  @override
  String toString() {
    return '<fn ${functionDeclaration.name.lexeme}>';
  }
}
