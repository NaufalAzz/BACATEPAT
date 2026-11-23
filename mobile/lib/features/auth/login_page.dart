import 'package:flutter/material.dart';

import '../../app/app_session.dart';
import '../../app/navigation_plan.dart';
import '../../core/components/baca_tepat_mark.dart';
import '../../core/theme/app_tokens.dart';
import '../teacher/teacher_demo_store.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({required this.role, super.key});
  final AppRole role;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  late bool _isTeacher;
  bool _obscurePassword = true;

  String get _homePath => _isTeacher ? '/guru' : '/siswa';

  @override
  void initState() {
    super.initState();
    _isTeacher = widget.role == AppRole.teacher;
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _enterPreview() {
    if (!_formKey.currentState!.validate()) return;
    final store = TeacherDemoStore.instance;
    final username = _usernameController.text.trim();
    final password = _passwordController.text;
    if (_isTeacher) {
      if (!store.authenticateTeacher(username, password)) {
        _showInvalidLogin();
        return;
      }
      final teacherId = store.demoTeacherId!;
      AppSession.startTeacher(user: teacherId, teacher: teacherId);
    } else {
      final student = store.studentByUsername(username);
      if (!store.authenticateStudent(username, password) || student == null) {
        _showInvalidLogin();
        return;
      }
      AppSession.startStudent(user: student.userId, student: student.id);
    }
    Navigator.pushNamedAndRemoveUntil(context, _homePath, (_) => false);
  }

  void _selectRole(bool teacher) {
    if (_isTeacher == teacher) return;
    setState(() => _isTeacher = teacher);
  }

  void _showInvalidLogin() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Nama pengguna atau kata sandi tidak sesuai.'),
      ),
    );
  }

  void _simulateExpiredSession() {
    AppSession.end();
    Navigator.pushNamedAndRemoveUntil(context, '/welcome', (_) => false);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _isTeacher
        ? const Color(0xFFF1F7F8)
        : const Color(0xFFFFF9EF),
    body: SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final page = SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: constraints.maxHeight * .215),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: _brandName(context),
                  ),
                  const SizedBox(height: 42),
                  _formPanel(context),
                ],
              ),
            ),
          );
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: page,
            ),
          );
        },
      ),
    ),
  );

  Widget _brandName(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      const BacaTepatMark(size: 34),
      const SizedBox(width: 8),
      Text(
        'BacaTepat',
        style: Theme.of(context).textTheme.titleLarge
            ?.copyWith(fontSize: 18, fontWeight: FontWeight.w900),
      ),
    ],
  );

  Widget _formPanel(BuildContext context) => Form(
    key: _formKey,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          _isTeacher ? 'PORTAL GURU' : 'SELAMAT DATANG, TEMAN!',
          style: const TextStyle(
            color: AppTokens.primary,
            fontSize: 10,
            letterSpacing: 1.15,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          _isTeacher ? 'Masuk ke ruang kelas' : 'Siap membaca hari ini?',
          style: const TextStyle(
            color: AppTokens.text,
            fontSize: 25,
            height: 1.2,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _isTeacher
              ? 'Gunakan akun yang diberikan pengelola.'
              : 'Masukkan nama pengguna dari gurumu.',
          style: const TextStyle(
            color: AppTokens.mutedText,
            fontSize: 14,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 26),
        const _LoginLabel('Nama pengguna'),
        const SizedBox(height: 6),
        TextFormField(
          key: const ValueKey('login-username'),
          controller: _usernameController,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            hintText: 'Nama pengguna',
            contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          ),
          validator: (value) => value == null || value.trim().isEmpty
              ? 'Isi nama pengguna untuk pratinjau'
              : null,
        ),
        const SizedBox(height: 16),
        const _LoginLabel('Kata sandi'),
        const SizedBox(height: 6),
        TextFormField(
          key: const ValueKey('login-password'),
          controller: _passwordController,
          obscureText: _obscurePassword,
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => _enterPreview(),
          decoration: InputDecoration(
            hintText: 'Kata sandi',
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 13,
            ),
            suffixIcon: IconButton(
              tooltip: _obscurePassword
                  ? 'Tampilkan kata sandi'
                  : 'Sembunyikan kata sandi',
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
              ),
            ),
          ),
          validator: (value) => value == null || value.isEmpty
              ? 'Isi kata sandi untuk pratinjau'
              : null,
        ),
        const SizedBox(height: 18),
        SizedBox(
          height: 48,
          child: FilledButton(
            key: const ValueKey('login-submit'),
            onPressed: _enterPreview,
            style: FilledButton.styleFrom(
              backgroundColor: _isTeacher
                  ? AppTokens.secondary
                  : AppTokens.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(9),
              ),
              elevation: 2,
            ),
            child: Text(
              _isTeacher ? 'Masuk' : 'Mulai belajar',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 4,
          runSpacing: 0,
          children: [
            TextButton(
              onPressed: _showInvalidLogin,
              style: TextButton.styleFrom(
                foregroundColor: AppTokens.secondary,
                padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
                minimumSize: const Size(30, 28),
                textStyle: const TextStyle(
                  fontSize: 9,
                  decoration: TextDecoration.underline,
                  fontWeight: FontWeight.w700,
                ),
              ),
              child: const Text('Simulasi kredensial salah'),
            ),
            TextButton(
              onPressed: _simulateExpiredSession,
              style: TextButton.styleFrom(
                foregroundColor: AppTokens.secondary,
                padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
                minimumSize: const Size(30, 28),
                textStyle: const TextStyle(
                  fontSize: 9,
                  decoration: TextDecoration.underline,
                  fontWeight: FontWeight.w700,
                ),
              ),
              child: const Text('Simulasi sesi berakhir'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Divider(height: 1, color: Color(0xFFDDE5E2)),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: Text(
                _isTeacher
                    ? 'Ingin melihat aplikasi Siswa?'
                    : 'Ingin melihat ruang Guru?',
                style: const TextStyle(
                  color: AppTokens.mutedText,
                  fontSize: 11,
                ),
              ),
            ),
            TextButton(
              key: const ValueKey('login-toggle-role'),
              onPressed: () => _selectRole(!_isTeacher),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                minimumSize: const Size(48, 36),
              ),
              child: Text(
                _isTeacher ? 'Buka demo Siswa  ›' : 'Buka demo Guru  ›',
                style: const TextStyle(
                  color: AppTokens.secondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _LoginLabel extends StatelessWidget {
  const _LoginLabel(this.label);
  final String label;
  @override
  Widget build(BuildContext context) => Text(
    label,
    style: const TextStyle(
      color: AppTokens.text,
      fontSize: 12,
      fontWeight: FontWeight.w800,
    ),
  );
}
