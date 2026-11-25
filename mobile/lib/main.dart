import 'package:flutter/material.dart';

import 'app/app.dart';
import 'core/api/learning_session.dart';
import 'core/api/bacatepat_api.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (LearningSession.enabled) {
    try {
      await LearningSession.restore();
    } on ApiError {
      LearningSession.clear();
    }
  }
  runApp(const BacaTepatApp());
}
