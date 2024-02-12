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

  @override
  int get arity => 0;

  @override
  Object? call(Interpreter interpreter, List<Object?> arguments) {
    final instance = LoxInstance(this);
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
