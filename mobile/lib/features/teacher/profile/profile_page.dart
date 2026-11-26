import 'package:flutter/material.dart';

import '../../../core/api/learning_session.dart';
import '../../../core/api/bacatepat_api.dart';

import '../../../app/app_session.dart';
import '../../../core/theme/app_tokens.dart';
import '../teacher_demo_store.dart';
import '../teacher_widgets.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _email;
  late double _retention;

  @override
  void initState() {
    super.initState();
    final store = TeacherDemoStore.instance;
    _name = TextEditingController(text: store.teacherName);
    _email = TextEditingController(text: store.teacherEmail);
    _retention = store.audioRetentionDays.toDouble();
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = TeacherDemoStore.instance;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppTokens.space16,
        AppTokens.space16,
        AppTokens.space16,
        AppTokens.space24,
      ),
      children: [
        const TeacherPageHeading(
          section: 'Profil',
          title: 'Profil guru',
          subtitle: 'Informasi akun dan pengaturan kelas.',
        ),
        Row(
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: const Color(0xFFFBE7B5),
              child: Text(
                store.teacherName
                    .split(' ')
                    .map((part) => part.characters.first)
                    .take(2)
                    .join()
                    .toUpperCase(),
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppTokens.text,
                ),
              ),
            ),
            const SizedBox(width: AppTokens.space14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    store.teacherName,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppTokens.text,
                    ),
                  ),
                  const Text(
                    'Guru Kelas · SD Pelita Bangsa',
                    style: TextStyle(fontSize: 12, color: AppTokens.mutedText),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTokens.space16),
        TeacherPanel(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(AppTokens.space16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Informasi profil',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w500,
                          color: AppTokens.text,
                        ),
                      ),
                      const SizedBox(height: AppTokens.space12),
                      TextFormField(
                        key: const ValueKey('teacher-profile-name'),
                        controller: _name,
                        decoration: const InputDecoration(
                          labelText: 'Nama lengkap',
                        ),
                        validator: (value) =>
                            value == null || value.trim().length < 2
                            ? 'Nama minimal 2 karakter.'
                            : null,
                      ),
                      const SizedBox(height: AppTokens.space12),
                      TextFormField(
                        key: const ValueKey('teacher-profile-email'),
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(labelText: 'Email'),
                        validator: (value) =>
                            value == null ||
                                !value.contains('@') ||
                                !value.contains('.')
                            ? 'Masukkan email yang valid.'
                            : null,
                      ),
                      const SizedBox(height: AppTokens.space12),
                      FilledButton(
                        key: const ValueKey('save-teacher-profile'),
                        onPressed: _save,
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(0, 40),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        child: const Text('Simpan perubahan'),
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(height: 1, color: AppTokens.outline),
              Padding(
                padding: const EdgeInsets.all(AppTokens.space16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Keamanan',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w500,
                        color: AppTokens.text,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Perbarui kata sandi secara berkala.',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: AppTokens.mutedText,
                      ),
                    ),
                    const SizedBox(height: AppTokens.space12),
                    OutlinedButton(
                      onPressed: () => _changePassword(context),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 40),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                      ),
                      child: const Text('Ganti kata sandi'),
                    ),
                    const SizedBox(height: AppTokens.space16),
                    Text(
                      'Hapus rekaman yang sudah dievaluasi setelah ${_retention.round()} hari.',
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppTokens.mutedText,
                      ),
                    ),
                    Slider(
                      key: const ValueKey('audio-retention'),
                      value: _retention,
                      min: 90,
                      max: 180,
                      divisions: 3,
                      label: '${_retention.round()} hari',
                      onChanged: (value) => setState(() => _retention = value),
                      onChangeEnd: (value) =>
                          TeacherDemoStore.instance.updateProfile(
                            name: _name.text,
                            email: _email.text,
                            retentionDays: value.round(),
                          ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppTokens.outline),
              Material(
                color: Colors.transparent,
                child: ListTile(
                  key: const ValueKey('teacher-logout'),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  leading: const Icon(
                    Icons.logout_rounded,
                    size: 20,
                    color: AppTokens.primary,
                  ),
                  title: const Text(
                    'Keluar dari akun',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: () async {
                    if (LearningSession.enabled) {
                      try {
                        await LearningSession.logout();
                      } on ApiError catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context)
                              .showSnackBar(SnackBar(content: Text(e.message)));
                        }
                        return;
                      }
                      if (!context.mounted) return;
                    } else {
                      AppSession.end();
                    }

                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/welcome',
                      (_) => false,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    TeacherDemoStore.instance.updateProfile(
      name: _name.text.trim(),
      email: _email.text.trim(),
      retentionDays: _retention.round(),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profil pratinjau diperbarui.')),
    );
  }

  void _changePassword(BuildContext context) {
    final password = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Ganti kata sandi'),
        content: TextField(
          controller: password,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Kata sandi baru (minimal 8 karakter)',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              if (password.text.length < 8) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Kata sandi minimal 8 karakter.'),
                  ),
                );
                return;
              }
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Perubahan kata sandi disimulasikan.'),
                ),
              );
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    ).whenComplete(password.dispose);
  }
}
