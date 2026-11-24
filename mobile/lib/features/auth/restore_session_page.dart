import 'package:flutter/material.dart';

import '../../app/role_selection_page.dart';
import '../../core/api/bacatepat_api.dart';
import 'account_home.dart';

class RestoreSessionPage extends StatefulWidget {
  const RestoreSessionPage({super.key});
  @override
  State<RestoreSessionPage> createState() => _RestoreSessionPageState();
}

class _RestoreSessionPageState extends State<RestoreSessionPage> {
  final api = BacaTepatApi();
  late Future<Map<String, dynamic>?> profile = api.restore();
  @override
  Widget build(BuildContext context) => FutureBuilder(
    future: profile,
    builder: (context, state) {
      if (state.connectionState != ConnectionState.done) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      if (state.hasError) {
        return Scaffold(
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Sesi belum bisa diperiksa.'),
                TextButton(
                  onPressed: () => setState(() => profile = api.restore()),
                  child: const Text('Coba lagi'),
                ),
                TextButton(
                  onPressed: () =>
                      Navigator.pushReplacementNamed(context, '/welcome'),
                  child: const Text('Masuk dengan akun lain'),
                ),
              ],
            ),
          ),
        );
      }
      if (state.data == null) return const RoleSelectionPage();
      return AccountHome(api: api, user: state.requireData!);
    },
  );
}
