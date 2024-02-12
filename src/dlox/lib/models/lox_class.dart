import '../interpreter.dart';
import 'lox_callable.dart';
import 'lox_function.dart';
import 'lox_instance.dart';

class LoxClass implements LoxCallable {
  const LoxClass(
    this.name,
    this.methods,
  );

  final String name;
  final Map<String, LoxFunction> methods;

  /// Returns the list of arguments for the `init` method, or otherwise 0.
  @override
  int get arity {
    final initializer = findMethod('init');
    if (initializer == null) return 0;

    return initializer.arity;
  }

  @override
  Object? call(Interpreter interpreter, List<Object?> arguments) {
    final instance = LoxInstance(this);

    // -- initializer (i.e. constructor) --
    final initializer = findMethod('init');
    if (initializer != null) {
      initializer.bind(instance).call(interpreter, arguments);
    }
    return instance;
  }

  LoxFunction? findMethod(String name) {
    if (methods.containsKey(name)) {
      return methods[name];
    }
    return null;
  }

  @override
  String toString() => name;
}
