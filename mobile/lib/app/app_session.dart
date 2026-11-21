import 'navigation_plan.dart';

/// In-memory role state for the frontend preview only.
abstract final class AppSession {
  static AppRole? role;

  static void start(AppRole value) => role = value;

  static void end() => role = null;
}
