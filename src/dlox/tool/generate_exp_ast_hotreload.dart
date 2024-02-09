import 'package:analyzer_utils/hotreloader.dart';

import 'generate_exp_ast.dart' as app;

Future<void> main() async {
  await runFromFunction((p0) => app.main(p0), []);
}
