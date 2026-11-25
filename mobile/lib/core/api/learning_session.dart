import '../../app/app_router.dart';
import '../../app/app_session.dart';
import '../../features/student/student_demo_store.dart';
import '../../features/teacher/teacher_demo_store.dart';
import 'bacatepat_api.dart';

/// Enable the live data source by supplying the API origin at build time.
abstract final class LearningSession {
  static const enabled = String.fromEnvironment('API_BASE_URL') != '';
  static final api = BacaTepatApi();
  static int _generation = 0;
  static bool busy = false;

  static Future<void> login(
    String username,
    String password,
    String role,
  ) async {
    if (busy) throw const ApiError('Sedang masuk.', 0);
    busy = true;
    try {
      final profile = await api.login(username, password, role);
      await _start(profile);
    } finally {
      busy = false;
    }
  }

  static Future<void> restore() async {
    final profile = await api.restore();
    if (profile != null) await _start(profile);
  }

  static Future<void> _start(Map<String, dynamic> user) async {
    try {
      await refresh();
      if (user['role'] == 'guru') {
        AppSession.startTeacher(user: user['id'], teacher: user['id']);
      } else {
        AppSession.startStudent(user: user['id'], student: user['siswa_id']);
      }
      api.onExpired = () {
        clear();
        AppRouter.navigatorKey.currentState?.pushNamedAndRemoveUntil(
          '/welcome',
          (_) => false,
        );
      };
    } catch (_) {
      await api.forget();
      clear();
      rethrow;
    }
  }

  static Future<void> refresh() async {
    final generation = _generation;
    final data = (await api.request('auth/learning-data'))['data'];
    if (generation != _generation) {
      throw const ApiError('Sesi sudah berakhir.', 401);
    }
    TeacherDemoStore.instance.loadAccount(data);
    StudentDemoStore.instance.loadAccount(data);
  }

  static void clear() {
    _generation++;
    AppSession.end();
    api.onExpired = null;
  }

  static Future<void> logout() async {
    await api.logout();
    clear();
  }
}
