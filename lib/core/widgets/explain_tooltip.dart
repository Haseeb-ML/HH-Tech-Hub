import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AutoExplainNotifier extends Notifier<bool> {
  @override
  bool build() => false;
  void toggle(bool value) => state = value;
}

final autoExplainProvider = NotifierProvider<AutoExplainNotifier, bool>(() => AutoExplainNotifier());

class ExplainTooltip extends ConsumerWidget {
  final String message;
  final Widget child;
  const ExplainTooltip({super.key, required this.message, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isEnabled = ref.watch(autoExplainProvider);
    if (!isEnabled) {
      return child;
    }

    return Tooltip(
      message: message,
      triggerMode: TooltipTriggerMode.tap, // Will still trigger on hover for desktop
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 4)),
        ],
      ),
      textStyle: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
      child: child,
    );
  }
}

