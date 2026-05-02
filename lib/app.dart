import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'user_interfaces/industrial/screens/industrial_home_screen.dart';
import 'user_interfaces/industrial/screens/industrial_transfer_screen.dart';
import 'providers/theme_provider.dart';
import 'providers/ui_theme_provider.dart';
import 'providers/navigation_provider.dart';
import 'providers/mock_mode_provider.dart';
import 'main.dart'; // For RestartWidget

/// Root app widget with bottom navigation between Home and Transfer screens.
class TurboLinkApp extends ConsumerStatefulWidget {
  const TurboLinkApp({super.key});

  @override
  ConsumerState<TurboLinkApp> createState() => _TurboLinkAppState();
}

class _TurboLinkAppState extends ConsumerState<TurboLinkApp> {
  late UIAesthetic _activeAesthetic;

  @override
  void initState() {
    super.initState();
    // Lock in the aesthetic on startup/restart. 
    // This prevents the UI from instantly rebuilding if "Later" is pressed.
    _activeAesthetic = ref.read(uiThemeProvider);
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);

    return MaterialApp(
      title: 'TurboLink',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.getTheme(_activeAesthetic, Brightness.light),
      darkTheme: AppTheme.getTheme(_activeAesthetic, Brightness.dark),
      themeMode: themeMode,
      home: MainScaffold(aesthetic: _activeAesthetic),
    );
  }
}

class MainScaffold extends ConsumerStatefulWidget {
  final UIAesthetic aesthetic;
  const MainScaffold({super.key, required this.aesthetic});

  @override
  ConsumerState<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends ConsumerState<MainScaffold> {
  // We can dynamically resolve screens based on aesthetic here.
  // Currently, we only have Industrial screens implemented.
  List<Widget> _getScreens(UIAesthetic aesthetic) {
    // In the future: if (aesthetic == UIAesthetic.cyberpunk) return [CyberpunkHomeScreen(), ...];
    return const [
      HomeScreen(),
      TransferScreen(),
    ];
  }

  void _showModeDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return Consumer(
          builder: (context, ref, _) {
            final isMock = ref.watch(mockModeProvider);
            final colors = AppTheme.colors(context);

            return AlertDialog(
              backgroundColor: Theme.of(context).cardTheme.color,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                side: BorderSide(color: Theme.of(context).dividerColor, width: 0.5),
              ),
              title: Text('SELECT ENVIRONMENT', style: Theme.of(context).textTheme.headlineMedium),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RadioListTile<bool>(
                    title: Text('Demo Mode (DM)', style: Theme.of(context).textTheme.titleMedium),
                    subtitle: Text('Populates UI with mock data for testing.'),
                    value: true,
                    groupValue: isMock,
                    activeColor: colors.primaryGlow,
                    onChanged: (val) {
                      ref.read(mockModeProvider.notifier).state = val!;
                      Navigator.pop(context);
                    },
                  ),
                  RadioListTile<bool>(
                    title: Text('Release Mode (RM)', style: Theme.of(context).textTheme.titleMedium),
                    subtitle: Text('Uses real native backend via MethodChannels.'),
                    value: false,
                    groupValue: isMock,
                    activeColor: colors.primaryGlow,
                    onChanged: (val) {
                      ref.read(mockModeProvider.notifier).state = val!;
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _changeAesthetic(UIAesthetic newAesthetic) {
    if (newAesthetic == ref.read(uiThemeProvider)) return;
    
    // Pop the settings bottom sheet first
    Navigator.pop(context);

    // Show restart prompt
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardTheme.color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          side: BorderSide(color: Theme.of(context).dividerColor, width: 0.5),
        ),
        title: Text('RESTART REQUIRED', style: Theme.of(context).textTheme.headlineMedium),
        content: Text(
          'Changing the UI Aesthetic requires an application restart to fully rebuild the interface layout.\n\nRestart now?',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () {
              ref.read(uiThemeProvider.notifier).setAesthetic(newAesthetic);
              Navigator.pop(ctx);
            },
            child: Text('LATER', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.colors(context).primaryGlow,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
            ),
            onPressed: () {
              ref.read(uiThemeProvider.notifier).setAesthetic(newAesthetic);
              Navigator.pop(ctx);
              RestartWidget.restartApp(context);
            },
            child: Text('RESTART NOW', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Theme.of(context).colorScheme.onPrimary)),
          ),
        ],
      )
    );
  }

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
                final currentAesthetic = ref.watch(uiThemeProvider);
                final colors = AppTheme.colors(context);

                return Column(
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.palette_outlined, color: colors.primaryGlow),
                      title: Text('UI AESTHETIC', style: Theme.of(context).textTheme.titleMedium),
                      subtitle: Text('Select overall interface style', style: Theme.of(context).textTheme.bodySmall),
                      trailing: DropdownButton<UIAesthetic>(
                        value: currentAesthetic,
                        underline: const SizedBox(),
                        icon: Icon(Icons.keyboard_arrow_down, color: colors.primaryGlow),
                        dropdownColor: Theme.of(context).cardTheme.color,
                        items: UIAesthetic.values.map((aesthetic) {
                          return DropdownMenuItem(
                            value: aesthetic,
                            child: Text(
                              aesthetic.displayName,
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: currentAesthetic == aesthetic ? colors.primaryGlow : Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            _changeAesthetic(val);
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingMd),
                    Consumer(
                      builder: (context, ref, _) {
                        final isDark = ref.watch(themeProvider) == ThemeMode.dark;
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                            isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                            color: colors.primaryGlow,
                          ),
                          title: Text(
                            'THEME MODE',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          subtitle: Text(
                            isDark ? 'DARK MODE' : 'LIGHT MODE',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          trailing: Switch(
                            value: isDark,
                            onChanged: (value) => ref.read(themeProvider.notifier).toggleTheme(),
                            activeThumbColor: colors.primaryGlow,
                            activeTrackColor: colors.primaryGlowDim,
                          ),
                        );
                      },
                    ),
                  ],
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
    final screens = _getScreens(widget.aesthetic);
    final colors = AppTheme.colors(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldExit = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: Theme.of(context).cardTheme.color,
            title: Text('EXIT TURBOLINK', style: Theme.of(context).textTheme.headlineMedium),
            content: Text(
              'Are you sure you want to exit? Any active transfers will be terminated.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('CANCEL', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5))),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.colors(context).error),
                onPressed: () => Navigator.pop(context, true),
                child: Text('EXIT', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Theme.of(context).colorScheme.onError)),
              ),
            ],
          ),
        );
        if (shouldExit ?? false) {
          // You could also stop services here if necessary
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: colors.primaryGlow,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                Icons.bolt_rounded,
                color: Theme.of(context).colorScheme.onPrimary,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Text('TURBOLINK'),
          ],
        ),
        actions: [
          Consumer(
            builder: (context, ref, _) {
              final isMock = ref.watch(mockModeProvider);
              return GestureDetector(
                onTap: _showModeDialog,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isMock ? colors.primaryGlowDim : colors.secondaryGlowDim,
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: isMock ? colors.primaryGlow : colors.secondaryGlow,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isMock ? 'DM' : 'RM',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: isMock ? colors.primaryGlow : colors.secondaryGlow,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: _showSettings,
          ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: screens[currentIndex],
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
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.radar_rounded),
              selectedIcon: Icon(Icons.radar_rounded, color: colors.primaryGlow),
              label: 'DISCOVER',
            ),
            NavigationDestination(
              icon: const Icon(Icons.swap_vert_rounded),
              selectedIcon: Icon(Icons.swap_vert_rounded, color: colors.primaryGlow),
              label: 'TRANSFERS',
            ),
          ],
        ),
      ),
      ),
    );
  }
}
