import 'package:flutter/material.dart';

export 'app.dart' show TeknoakisApp;

void bootstrap(Widget Function() builder) {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(builder());
}
