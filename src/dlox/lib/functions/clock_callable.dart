import '../interpreter.dart';
import '../models/lox_callable.dart';

class ClockCallable implements LoxCallable {
  const ClockCallable();

  @override
  int get arity => 0;

  @override
  Object call(Interpreter interpreter, List<Object?> arguments) {
    return DateTime.now().millisecondsSinceEpoch / 1000;
  }

  @override
  String toString() {
    return '<native fn>';
  }
}
