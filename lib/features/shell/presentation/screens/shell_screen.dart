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
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    // Auto-collapse sidebar if screen is tablet width
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!isMobile) {
        final isCurrentlyCollapsed = ref.read(sidebarCollapsedProvider);
        if (screenWidth < 1100 && !isCurrentlyCollapsed) {
          ref.read(sidebarCollapsedProvider.notifier).setCollapsed(true);
        } else if (screenWidth >= 1100 && isCurrentlyCollapsed) {
          ref.read(sidebarCollapsedProvider.notifier).setCollapsed(false);
        }
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
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        drawer: isMobile
            ? Drawer(
                child: CollapsibleSidebar(
                  navigationShell: widget.navigationShell,
                  isDrawer: true,
                ),
              )
            : null,
        body: isMobile
            ? SafeArea(
                child: Column(
                  children: [
                    TopAppBar(navigationShell: widget.navigationShell, isMobile: true),
                    Expanded(
                      child: Container(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        child: widget.navigationShell,
                      ),
                    ),
                  ],
                ),
              )
            : Row(
                children: [
                  CollapsibleSidebar(navigationShell: widget.navigationShell),
                  Expanded(
                    child: Column(
                      children: [
                        TopAppBar(navigationShell: widget.navigationShell, isMobile: false),
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
