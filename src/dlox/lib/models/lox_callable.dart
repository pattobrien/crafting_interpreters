import '../interpreter.dart';

/// Representation of any Lox object that can be called like a function.
///
/// This will include user-defined functions, but also class objects, since
/// classes are "called" to construct new instances.
abstract interface class LoxCallable {
  Object? call(Interpreter interpreter, List<Object?> arguments);

  int get arity;
}
