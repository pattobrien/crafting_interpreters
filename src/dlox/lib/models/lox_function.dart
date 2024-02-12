import '../ast/ast_nodes.dart';
import '../environment.dart';
import '../interpreter.dart';
import 'lox_callable.dart';
import 'lox_instance.dart';

/// A user-defined Function.
///
/// Functions create their own environments before every call. see:
/// - https://craftinginterpreters.com/functions.html#function-objects
/// - param -> arg binding diagram: https://craftinginterpreters.com/image/functions/binding.png
class LoxFunction implements LoxCallable {
  const LoxFunction(
    this.functionDeclaration,
    this.closure,
  );

  final FunctionStatement functionDeclaration;
  final Environment closure;

  @override
  int get arity => functionDeclaration.params.length;

  /// Where all user-defined function invocations are born.
  @override
  Object? call(Interpreter interpreter, List<Object?> arguments) {
    final environment = Environment.fromParent(closure);
    for (var i = 0; i < functionDeclaration.params.length; i++) {
      environment.define(functionDeclaration.params[i].lexeme, arguments[i]);
    }

    try {
      interpreter.executeBlock(functionDeclaration.body, environment);
    } on Return catch (e) {
      return e.value;
    }

    return null;
  }

  LoxFunction bind(LoxInstance instance) {
    final environment = Environment.fromParent(closure);
    environment.define('this', instance);
    return LoxFunction(functionDeclaration, environment);
  }

  @override
  String toString() {
    return '<fn ${functionDeclaration.name.lexeme}>';
  }
}
