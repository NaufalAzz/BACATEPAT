import 'package:flutter/material.dart';

import '../../../app/app_session.dart';
import '../../../core/components/baca_button.dart';
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
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(AppTokens.space16),
    children: [
      const TeacherPageHeading(
        title: 'Profil Guru',
        subtitle: 'Kelola informasi profil dan preferensi pratinjau.',
      ),
      TeacherPanel(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              CircleAvatar(
                radius: 36,
                backgroundColor: AppTokens.sunshine,
                child: Text(
                  TeacherDemoStore.instance.teacherName
                      .split(' ')
                      .map((part) => part.characters.first)
                      .take(2)
                      .join()
                      .toUpperCase(),
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF7B5C15),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                TeacherDemoStore.instance.teacherName,
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const Text(
                'Guru Kelas',
                style: TextStyle(color: AppTokens.mutedText, fontSize: 12),
              ),
              const SizedBox(height: AppTokens.space16),
              TextFormField(
                key: const ValueKey('teacher-profile-name'),
                controller: _name,
                decoration: const InputDecoration(labelText: 'Nama Guru'),
                validator: (value) => value == null || value.trim().length < 2
                    ? 'Nama minimal 2 karakter.'
                    : null,
              ),
              const SizedBox(height: AppTokens.space16),
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
              const SizedBox(height: AppTokens.space16),
              BacaButton(
                key: const ValueKey('save-teacher-profile'),
                label: 'Simpan profil',
                icon: Icons.save_outlined,
                onPressed: _save,
              ),
              const SizedBox(height: AppTokens.space8),
              TextButton.icon(
                onPressed: () => _changePassword(context),
                icon: const Icon(Icons.lock_outline_rounded),
                label: const Text('Ganti kata sandi'),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: AppTokens.space16),
      TeacherPanel(
        title: 'Retensi rekaman',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hapus rekaman yang sudah dievaluasi setelah ${_retention.round()} hari.',
            ),
            Slider(
              key: const ValueKey('audio-retention'),
              value: _retention,
              min: 90,
              max: 180,
              divisions: 3,
              label: '${_retention.round()} hari',
              onChanged: (value) => setState(() => _retention = value),
              onChangeEnd: (value) => TeacherDemoStore.instance.updateProfile(
                name: _name.text,
                email: _email.text,
                retentionDays: value.round(),
              ),
            ),
            const Text(
              'Rentang 90–180 hari mengikuti kebijakan retensi pada BRD.',
            ),
          ],
        ),
      ),
      const SizedBox(height: AppTokens.space16),
      const TeacherPanel(
        title: 'Akun pratinjau',
        child: Text(
          'Profil dan pengaturan hanya tersimpan selama aplikasi berjalan. Tidak ada data yang dikirim ke server.',
        ),
      ),
      const SizedBox(height: AppTokens.space16),
      Card(
        child: ListTile(
          key: const ValueKey('teacher-logout'),
          leading: const Icon(Icons.logout_rounded, color: AppTokens.primary),
          title: const Text(
            'Keluar dari akun',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          onTap: () {
            AppSession.end();
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/welcome',
              (_) => false,
            );
          },
        ),
      ),
    ],
  );

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
