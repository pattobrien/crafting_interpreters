import '../interpreter.dart';
import 'lox_callable.dart';
import 'lox_instance.dart';

class LoxClass implements LoxCallable {
  final String name;

  const LoxClass(this.name);

  @override
  String toString() => name;

  @override
  int get arity => 0;

  @override
  Object? call(Interpreter interpreter, List<Object?> arguments) {
    final instance = LoxInstance(this);
    return instance;
  }
}
