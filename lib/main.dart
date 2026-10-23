import 'package:flutter/material.dart';
import 'app.dart';
import 'core/push_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await PushService.instance.init();
  runApp(const ZenjiGoDriverApp());
}
