import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/ls45_app.dart';

void main() {
  // ProviderScope hosts the Riverpod state graph for the whole app.
  runApp(const ProviderScope(child: Ls45App()));
}
