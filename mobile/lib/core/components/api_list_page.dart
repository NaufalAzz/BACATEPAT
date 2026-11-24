import 'package:flutter/material.dart';

import '../api/bacatepat_api.dart';

/// A paginated server list. An action can refresh the current page after a write.
class ApiListPage extends StatefulWidget {
  const ApiListPage({
    super.key,
    required this.api,
    required this.title,
    required this.path,
    required this.empty,
    required this.tile,
  });
  final BacaTepatApi api;
  final String title, path, empty;
  final Widget Function(BuildContext, Map<String, dynamic>, VoidCallback) tile;
  @override
  State<ApiListPage> createState() => _ApiListPageState();
}

class _ApiListPageState extends State<ApiListPage> {
  int page = 1;
  late Future<Map<String, dynamic>> rows = load();
  Future<Map<String, dynamic>> load() => widget.api.request(
    '${widget.path}${widget.path.contains('?') ? '&' : '?'}page=$page',
  );
  void refresh() {
    if (mounted) setState(() => rows = load());
  }

  void turn(int step) {
    page += step;
    refresh();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.title),
      actions: [
        IconButton(
          tooltip: 'Muat ulang',
          onPressed: refresh,
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    body: FutureBuilder(
      future: rows,
      builder: (context, state) {
        if (state.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.hasError) return Center(child: Text(state.error.toString()));
        final response = state.requireData;
        return ListView(
          children: [
            if ((response['data'] as List).isEmpty)
              ListTile(title: Text(widget.empty)),
            for (final row in response['data'])
              widget.tile(context, row, refresh),
            if (page > 1)
              TextButton(
                onPressed: () => turn(-1),
                child: const Text('Sebelumnya'),
              ),
            if (page < response['last_page'])
              TextButton(
                onPressed: () => turn(1),
                child: const Text('Berikutnya'),
              ),
          ],
        );
      },
    ),
  );
}
