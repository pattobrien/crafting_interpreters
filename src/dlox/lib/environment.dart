import 'ast/interpreter.dart';
import 'token.dart';

class Environment {
  final Map<String, Object?> _values = {};

  Environment();

  Object? get(Token name) {
    if (_values.containsKey(name)) return _values[name];
    throw DloxRuntimeError(name, 'Undefined variable "${name.lexeme}".');
  }

  void define(String name, Object? value) {
    if (value == null) _values.remove(name);
    _values.putIfAbsent(name, () => value);
  }
}
