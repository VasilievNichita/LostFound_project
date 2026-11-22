import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/lost_found_model.dart';
import 'data_state.dart';

// Прямой адрес может вести к вещи, которой нет на первой странице доски.
class ItemLoader extends StatefulWidget {
  const ItemLoader({super.key, required this.id, required this.child});
  final String id;
  final Widget child;
  @override
  State<ItemLoader> createState() => _ItemLoaderState();
}

class _ItemLoaderState extends State<ItemLoader> {
  String? error;
  bool loading = true;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => load());
  }

  Future<void> load() async {
    if (!mounted) return;
    setState(() {
      loading = true;
      error = null;
    });
    final result = await context.read<LostFoundModel>().ensureItem(widget.id);
    if (mounted) {
      setState(() {
        error = result;
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final model = context.watch<LostFoundModel>();
    if (model.byId(widget.id) != null) return widget.child;
    return Scaffold(
      appBar: AppBar(title: const Text('Объявление')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ErrorView(
              message: error ?? 'Объявление недоступно.',
              onRetry: load,
            ),
    );
  }
}
