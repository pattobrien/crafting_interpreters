import 'ast/interpreter.dart';
import 'token.dart';

class Environment {
  final Map<String, Object?> _values = {};

  final Environment? enclosing;

  Environment.global() : enclosing = null;

  Environment.fromParent(Environment this.enclosing);

  Object? get(Token name) {
    if (_values.containsKey(name)) return _values[name];
    if (enclosing != null) return enclosing?.get(name);
    throw DloxRuntimeError(name, 'Undefined variable "${name.lexeme}".');
  }

  ///
  void define(String name, Object? value) {
    if (value == null) {
      _values.remove(name);
      return;
    }
    _values.putIfAbsent(name, () => value);
  }

  /// Unlike [define], this function throws an error if a variable [name]
  /// doesn't already exist.
  void assign(Token name, Object? value) {
    if (_values.containsKey(name.lexeme)) {
      _values[name.lexeme] = value;
      return;
    }

    if (enclosing != null) {
      return enclosing!.assign(name, value);
    }

    throw DloxRuntimeError(name, 'Undefined variable "${name.lexeme}".');
  }
}
