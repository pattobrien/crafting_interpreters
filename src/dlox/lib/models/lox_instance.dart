import 'lox_class.dart';

class LoxInstance {
  final LoxClass clazz;

  LoxInstance(this.clazz);

  @override
  String toString() => '${clazz.name} instance';
}
