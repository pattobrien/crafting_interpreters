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
    this.closure, {
    required this.isInitializer,
  });

  final FunctionStatement functionDeclaration;
  final Environment closure;
  final bool isInitializer;

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
      // if we get a Return exception from within an initializer, then return
      // `this` instead of the value (which would otherwise be null).
      if (isInitializer) {
        return closure.getAt(0, 'this');
      }
      return e.value;
    }

    if (isInitializer) return closure.getAt(0, 'this');

    return null;
  }

  LoxFunction bind(LoxInstance instance) {
    final environment = Environment.fromParent(closure);
    environment.define('this', instance);
    return LoxFunction(
      functionDeclaration,
      environment,
      isInitializer: isInitializer,
    );
  }

  @override
  String toString() {
    return '<fn ${functionDeclaration.name.lexeme}>';
  }
}
