import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/lost_found_model.dart';

class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton(onPressed: onRetry, child: const Text('Повторить')),
        ],
      ),
    ),
  );
}

Widget? dataState(BuildContext context, LostFoundModel model) {
  if (model.isLoading) return const Center(child: CircularProgressIndicator());
  if (model.error != null) {
    return ErrorView(
      message: model.error!,
      onRetry: () => context.read<LostFoundModel>().load(),
    );
  }
  return null;
}
