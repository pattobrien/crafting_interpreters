import 'interpreter.dart';
import 'models/token.dart';

/// Used for scoping variables to a particular block.
///
/// A single environment is created using [Environment.fromParent] for every
/// block.
class Environment {
  final Map<String, Object?> _values = {};

  final Environment? enclosing;

  Environment.global() : enclosing = null;

  Environment.fromParent(Environment this.enclosing);

  /// Retrieves the value of a variable.
  ///
  /// If the variable is not found in the current environment, the enclosing
  /// environments are searched in order.
  Object? get(Token name) {
    if (_values.containsKey(name.lexeme)) return _values[name.lexeme];
    if (enclosing != null) return enclosing?.get(name);
    throw DloxRuntimeError(name, 'Undefined identifier "${name.lexeme}".');
  }

  /// Retrieves the value of a variable at a specific [distance] from the current environment.
  ///
  /// Unlike [get], which recursively searches nested environments for a variable,
  /// this function returns the value of a variable at a specific [distance]
  /// from the current environment.
  Object? getAt(int distance, String name) {
    return ancestorAt(distance)._values[name]!;
  }

  /// Get the [Environment] at a specific [distance] from the current environment.
  Environment ancestorAt(int distance) {
    Environment environment = this;
    for (int i = 0; i < distance; i++) {
      environment = environment.enclosing!;
    }

    return environment;
  }

  /// Adds a variable / function declaration to this environment.
  void define(String name, Object? value) {
    if (value == null) {
      _values[name] = null;
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

    throw DloxRuntimeError(name, 'Undefined identifier "${name.lexeme}".');
  }

  /// Assigns a variable at a specific [distance] from the current environment.
  void assignAt(int distance, Token name, Object? value) {
    ancestorAt(distance)._values[name.lexeme] = value;
  }
}
