import 'package:flutter_riverpod/flutter_riverpod.dart';

// Stores whether the sidebar is collapsed
class SidebarCollapsedNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void toggle() {
    state = !state;
  }
  
  void setCollapsed(bool value) {
    state = value;
  }
}

final sidebarCollapsedProvider = NotifierProvider<SidebarCollapsedNotifier, bool>(() {
  return SidebarCollapsedNotifier();
});
