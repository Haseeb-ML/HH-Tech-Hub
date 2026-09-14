import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/navigation_provider.dart';
import '../widgets/collapsible_sidebar.dart';
import '../widgets/top_app_bar.dart';
import '../widgets/spotlight_search_dialog.dart';

class ShellScreen extends ConsumerStatefulWidget {
  final StatefulNavigationShell navigationShell;

  const ShellScreen({
    super.key,
    required this.navigationShell,
  });

  @override
  ConsumerState<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends ConsumerState<ShellScreen> {
  @override
  Widget build(BuildContext context) {
    // Auto-collapse sidebar if screen is tablet width
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final width = MediaQuery.of(context).size.width;
      final isCurrentlyCollapsed = ref.read(sidebarCollapsedProvider);
      
      if (width < 1100 && !isCurrentlyCollapsed) {
        ref.read(sidebarCollapsedProvider.notifier).setCollapsed(true);
      } else if (width >= 1100 && isCurrentlyCollapsed) {
        ref.read(sidebarCollapsedProvider.notifier).setCollapsed(false);
      }
    });

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyK, control: true): () {
          showDialog(
            context: context,
            barrierColor: Colors.transparent,
            builder: (context) => const SpotlightSearchDialog(),
          );
        },
      },
      child: Scaffold(
        body: Row(
          children: [
            // Sidebar
            CollapsibleSidebar(navigationShell: widget.navigationShell),
            
            // Main Content Panel (Topbar + Module Content)
            Expanded(
              child: Column(
                children: [
                  // Top App Bar
                  TopAppBar(navigationShell: widget.navigationShell),
                  
                  // Screen content body
                  Expanded(
                    child: Container(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      child: widget.navigationShell,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
