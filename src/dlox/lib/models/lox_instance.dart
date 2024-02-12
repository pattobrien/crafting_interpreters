import '../interpreter.dart';
import 'lox_class.dart';
import 'token.dart';

class LoxInstance {
  final LoxClass clazz;
  final Map<String, Object?> _fields = {};

  LoxInstance(this.clazz);

  Object? get(Token name) {
    if (_fields.containsKey(name.lexeme)) {
      return _fields[name.lexeme];
    }

    final method = clazz.findMethod(name.lexeme);
    if (method != null) return method.bind(this);

    throw DloxRuntimeError(
      name,
      'Undefined property ${name.lexeme}.',
    );
  }

  void set(Token name, Object? value) {
    _fields[name.lexeme] = value;
  }

  @override
  String toString() => '${clazz.name} instance';
}
