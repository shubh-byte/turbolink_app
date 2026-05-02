import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'screens/transfer_screen.dart';
import 'providers/theme_provider.dart';
import 'providers/navigation_provider.dart';

/// Root app widget with bottom navigation between Home and Transfer screens.
class TurboLinkApp extends ConsumerWidget {
  const TurboLinkApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);

    return MaterialApp(
      title: 'TurboLink',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: const MainScaffold(),
    );
  }
}

class MainScaffold extends ConsumerStatefulWidget {
  const MainScaffold({super.key});

  @override
  ConsumerState<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends ConsumerState<MainScaffold> {
  final _screens = const [
    HomeScreen(),
    TransferScreen(),
  ];

  void _showSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(AppTheme.radiusXl)),
          border: Border.all(color: Theme.of(context).dividerColor, width: 0.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'SYSTEM SETTINGS',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: AppTheme.spacingLg),
            Consumer(
              builder: (context, ref, _) {
                final isDark = ref.watch(themeProvider) == ThemeMode.dark;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                    color: AppTheme.cyan,
                  ),
                  title: Text(
                    'THEME MODE',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  subtitle: Text(
                    isDark ? 'DARK INDUSTRIAL' : 'LABORATORY WHITE',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  trailing: Switch(
                    value: isDark,
                    onChanged: (value) => ref.read(themeProvider.notifier).toggleTheme(),
                    activeThumbColor: AppTheme.cyan,
                    activeTrackColor: AppTheme.cyan.withValues(alpha: 0.3),
                  ),
                );
              },
            ),
            const SizedBox(height: AppTheme.spacingLg),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(navigationProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                gradient: AppTheme.cyanGradient,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(
                Icons.bolt_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'TURBOLINK',
              style: GoogleFonts.unbounded(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
        actions: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppTheme.cyan.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AppTheme.cyan,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'MOCK',
                  style: GoogleFonts.sourceCodePro(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.cyan,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: _showSettings,
          ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _screens[currentIndex],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).bottomNavigationBarTheme.backgroundColor,
          border: Border(
            top: BorderSide(color: Theme.of(context).dividerColor, width: 0.5),
          ),
        ),
        child: NavigationBar(
          selectedIndex: currentIndex,
          onDestinationSelected: (i) => ref.read(navigationProvider.notifier).state = i,
          height: 64,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.radar_rounded),
              selectedIcon: Icon(Icons.radar_rounded, color: AppTheme.cyan),
              label: 'DISCOVER',
            ),
            NavigationDestination(
              icon: Icon(Icons.swap_vert_rounded),
              selectedIcon: Icon(Icons.swap_vert_rounded, color: AppTheme.cyan),
              label: 'TRANSFERS',
            ),
          ],
        ),
      ),
    );
  }
}
