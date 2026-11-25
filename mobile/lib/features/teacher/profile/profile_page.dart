import 'package:flutter/material.dart';

import '../../../app/app_session.dart';
import '../../../core/api/bacatepat_api.dart';
import '../../../core/components/baca_button.dart';
import '../../../core/theme/app_tokens.dart';
import '../teacher_demo_store.dart';
import '../teacher_widgets.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({
    super.key,
    this.profile,
    this.onSave,
    this.onPassword,
    this.onLogout,
  });
  final Map<String, dynamic>? profile;
  final Future<void> Function(String, String, int)? onSave;
  final VoidCallback? onPassword, onLogout;

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
    _name = TextEditingController(
      text: widget.profile?['nama'] ?? store.teacherName,
    );
    _email = TextEditingController(
      text: widget.profile == null
          ? store.teacherEmail
          : widget.profile!['email'] ?? '',
    );
    _retention =
        (widget.profile?['retensi_audio_hari'] ?? store.audioRetentionDays)
            .toDouble();
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
        subtitle: 'Kelola informasi profil dan preferensi akun.',
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
                  (widget.profile?['nama'] as String? ??
                          TeacherDemoStore.instance.teacherName)
                      .trim()
                      .split(RegExp(r'\s+'))
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
                widget.profile?['nama'] ??
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
                onPressed: widget.onPassword ?? () => _changePassword(context),
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
              min: widget.profile == null ? 90 : 1,
              max: 180,
              divisions: widget.profile == null ? 3 : 179,
              label: '${_retention.round()} hari',
              onChanged: (value) => setState(() => _retention = value),
              onChangeEnd: widget.profile != null
                  ? null
                  : (value) => TeacherDemoStore.instance.updateProfile(
                      name: _name.text,
                      email: _email.text,
                      retentionDays: value.round(),
                    ),
            ),
            if (widget.profile == null)
              const Text(
                'Rentang 90–180 hari mengikuti kebijakan retensi pada BRD.',
              ),
          ],
        ),
      ),
      const SizedBox(height: AppTokens.space16),
      if (widget.profile == null)
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
          onTap:
              widget.onLogout ??
              () {
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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (widget.onSave != null) {
      try {
        await widget.onSave!(
          _name.text.trim(),
          _email.text.trim(),
          _retention.round(),
        );
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Profil diperbarui.')));
        }
      } on ApiError catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(e.message)));
        }
      }
      return;
    }
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
