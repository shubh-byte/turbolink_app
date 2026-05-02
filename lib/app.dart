import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme_engine/base_theme.dart';
import 'user_interface/screens/home_screen.dart';
import 'user_interface/screens/transfer_screen.dart';
import 'providers/theme_provider.dart';
import 'providers/aesthetic_provider.dart';
import 'providers/navigation_provider.dart';
import 'providers/mock_mode_provider.dart';
import 'providers/connectivity_provider.dart';
import 'providers/settings_provider.dart';
import 'main.dart'; // For RestartWidget

/// Root app widget with bottom navigation between Home and Transfer screens.
class TurboLinkApp extends ConsumerStatefulWidget {
  const TurboLinkApp({super.key});

  @override
  ConsumerState<TurboLinkApp> createState() => _TurboLinkAppState();
}

class _TurboLinkAppState extends ConsumerState<TurboLinkApp> {
  late Aesthetic _activeAesthetic;

  @override
  void initState() {
    super.initState();
    // Lock in the aesthetic on startup/restart. 
    // This prevents the UI from instantly rebuilding if "Later" is pressed.
    _activeAesthetic = ref.read(aestheticProvider);
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);

    return MaterialApp(
      title: 'TurboLink',
      debugShowCheckedModeBanner: false,
      theme: _activeAesthetic.getTheme(Brightness.light),
      darkTheme: _activeAesthetic.getTheme(Brightness.dark),
      themeMode: themeMode,
      home: MainScaffold(aesthetic: _activeAesthetic),
    );
  }
}

class MainScaffold extends ConsumerStatefulWidget {
  final Aesthetic aesthetic;
  const MainScaffold({super.key, required this.aesthetic});

  @override
  ConsumerState<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends ConsumerState<MainScaffold> {
  /// Returns the common screens. Theme controls the visual aesthetic entirely.
  List<Widget> _getScreens(Aesthetic aesthetic) {
    return const [BaseHomeScreen(), BaseTransferScreen()];
  }

  void _showModeDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return Consumer(
          builder: (context, ref, _) {
            final isMock = ref.watch(mockModeProvider);
            final colors = BaseTheme.colors(context);

            return AlertDialog(
              backgroundColor: Theme.of(context).cardTheme.color,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(BaseTheme.radiusMd),
                side: BorderSide(color: Theme.of(context).dividerColor, width: 0.5),
              ),
              title: Text('SELECT ENVIRONMENT', style: Theme.of(context).textTheme.headlineMedium),
              content: RadioGroup<bool>(
                groupValue: isMock,
                onChanged: (val) {
                  ref.read(mockModeProvider.notifier).state = val!;
                  Navigator.pop(context);
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RadioListTile<bool>(
                      title: Text('Mock Mode (MOC)', style: Theme.of(context).textTheme.titleMedium),
                      subtitle: Text('Populates UI with mock data for testing.'),
                      value: true,
                      activeColor: colors.primaryGlow,
                    ),
                    RadioListTile<bool>(
                      title: Text('Release Mode (REL)', style: Theme.of(context).textTheme.titleMedium),
                      subtitle: Text('Uses real native backend via MethodChannels.'),
                      value: false,
                      activeColor: colors.primaryGlow,
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _changeAesthetic(Aesthetic newAesthetic) {
    if (newAesthetic == ref.read(aestheticProvider)) return;
    
    // Pop the settings bottom sheet first
    Navigator.pop(context);

    // Show restart prompt
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardTheme.color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(BaseTheme.radiusMd),
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
              ref.read(aestheticProvider.notifier).setAesthetic(newAesthetic);
              Navigator.pop(ctx);
            },
            child: Text('LATER', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: BaseTheme.colors(context).primaryGlow,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
            ),
            onPressed: () {
              ref.read(aestheticProvider.notifier).setAesthetic(newAesthetic);
              Navigator.pop(ctx);
              RestartWidget.restartApp(context);
            },
            child: Text('RESTART NOW', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Theme.of(context).colorScheme.onPrimary)),
          ),
        ],
      )
    );
  }

  Future<void> _handleModeChange(ConnectivityMode mode) async {
    final theme = Theme.of(context);
    final colors = BaseTheme.colors(context);
    final success = await ref.read(connectivityModeProvider.notifier).setMode(mode);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.transparent,
          elevation: 0,
          content: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: theme.brightness == Brightness.dark 
                  ? theme.colorScheme.surfaceContainerHighest
                  : (success ? colors.primaryGlow : colors.error),
              borderRadius: BorderRadius.circular(BaseTheme.radiusMd),
              border: Border.all(
                color: success ? colors.primaryGlow : colors.error,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: (success ? colors.primaryGlow : colors.error).withValues(alpha: 0.2),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(
                  success ? Icons.check_circle_outline_rounded : Icons.error_outline_rounded,
                  color: success ? colors.primaryGlow : colors.error,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    success 
                        ? 'STRATEGY UPDATED: ${mode.name.toUpperCase()}' 
                        : 'HARDWARE INCOMPATIBLE: ${mode.name.toUpperCase()}',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  void _showSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      enableDrag: false, // Give full control to DraggableScrollableSheet
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.0,
        maxChildSize: 0.95,
        snap: true,
        snapSizes: const [0.5, 0.95],
        snapAnimationDuration: const Duration(milliseconds: 150),
        expand: false,
        builder: (context, scrollController) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final colors = BaseTheme.colors(context);
          
          return Container(
            padding: const EdgeInsets.all(BaseTheme.spacingLg),
            decoration: BoxDecoration(
              // In dark mode, we use a slightly LIGHTER surface to pop against the background
              color: isDark 
                  ? Theme.of(context).colorScheme.surfaceContainerLow 
                  : Theme.of(context).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(BaseTheme.radiusXl)),
              border: Border.all(
                color: isDark ? colors.primaryGlow.withValues(alpha: 0.15) : Theme.of(context).dividerColor, 
                width: 0.5,
              ),
              boxShadow: isDark ? [
                BoxShadow(
                  color: colors.primaryGlow.withValues(alpha: 0.08),
                  blurRadius: 30,
                  spreadRadius: 2,
                ),
              ] : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                ),
              ],
            ),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: BaseTheme.spacingLg),
                    decoration: BoxDecoration(
                      color: Theme.of(context).dividerColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  'SYSTEM SETTINGS',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: BaseTheme.spacingLg),
                Consumer(
                  builder: (context, ref, _) {
                    final currentAesthetic = ref.watch(aestheticProvider);
                    final colors = BaseTheme.colors(context);

                    return Column(
                      children: [
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(Icons.palette_outlined, color: colors.primaryGlow),
                          title: Text('UI AESTHETIC', style: Theme.of(context).textTheme.titleMedium),
                          subtitle: Text('Select overall interface style', style: Theme.of(context).textTheme.bodySmall),
                          trailing: DropdownButton<Aesthetic>(
                            value: currentAesthetic,
                            underline: const SizedBox(),
                            icon: Icon(Icons.keyboard_arrow_down, color: colors.primaryGlow),
                            dropdownColor: Theme.of(context).cardTheme.color,
                            items: Aesthetic.values.map((aesthetic) {
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
                        const SizedBox(height: BaseTheme.spacingMd),
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
                        const SizedBox(height: BaseTheme.spacingMd),
                        Consumer(
                          builder: (context, ref, _) {
                            final mode = ref.watch(connectivityModeProvider);
                            final colors = BaseTheme.colors(context);

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(bottom: BaseTheme.spacingMd),
                                  child: Text(
                                    'CONNECTIVITY STRATEGY',
                                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                      color: colors.primaryGlow,
                                      letterSpacing: 1.2,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                _StrategyCard(
                                  title: 'PERFORMANCE MODE',
                                  description: 'Uses Wi-Fi Direct for massive throughput.',
                                  pros: ['Speed up to 250Mbps+', 'Ideal for 4K video/Large files'],
                                  cons: ['May disconnect from current Wi-Fi'],
                                  icon: Icons.speed_rounded,
                                  isSelected: mode == ConnectivityMode.performance,
                                  onTap: () => _handleModeChange(ConnectivityMode.performance),
                                ),
                                const SizedBox(height: BaseTheme.spacingMd),
                                _StrategyCard(
                                  title: 'CONNECTED MODE',
                                  description: 'Uses Wi-Fi Aware to keep you online.',
                                  pros: ['Stay connected to your router', 'Background transfers'],
                                  cons: ['Lower peak speeds than P2P'],
                                  icon: Icons.wifi_tethering_rounded,
                                  isSelected: mode == ConnectivityMode.connected,
                                  onTap: () => _handleModeChange(ConnectivityMode.connected),
                                ),
                                const SizedBox(height: BaseTheme.spacingLg),
                              ],
                            );
                          },
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(navigationProvider);
    final screens = _getScreens(widget.aesthetic);
    final colors = BaseTheme.colors(context);

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
                style: ElevatedButton.styleFrom(backgroundColor: BaseTheme.colors(context).error),
                onPressed: () => Navigator.pop(context, true),
                child: Text('EXIT', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Theme.of(context).colorScheme.onError)),
              ),
            ],
          ),
        );
        if (shouldExit ?? false) {
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
              const Text('TURBOLINK'),
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
                      borderRadius: BorderRadius.circular(BaseTheme.radiusSm),
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
                          isMock ? 'MOC' : 'REL',
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

class _StrategyCard extends StatelessWidget {
  final String title;
  final String description;
  final List<String> pros;
  final List<String> cons;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _StrategyCard({
    required this.title,
    required this.description,
    required this.pros,
    required this.cons,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = BaseTheme.colors(context);
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(BaseTheme.spacingMd),
        decoration: BoxDecoration(
          color: isSelected ? colors.primaryGlow.withValues(alpha: 0.1) : theme.cardTheme.color,
          borderRadius: BorderRadius.circular(BaseTheme.radiusMd),
          border: Border.all(
            color: isSelected ? colors.primaryGlow : theme.dividerColor,
            width: isSelected ? 2 : 0.5,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: colors.primaryGlow.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ] : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: isSelected ? colors.primaryGlow : theme.colorScheme.onSurfaceVariant, size: 20),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: isSelected ? colors.primaryGlow : theme.colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (isSelected)
                  Icon(Icons.check_circle_rounded, color: colors.primaryGlow, size: 18),
              ],
            ),
            const SizedBox(height: 8),
            Text(description, style: theme.textTheme.bodySmall),
            const SizedBox(height: 12),
            ...pros.map((pro) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Icon(Icons.add_rounded, color: colors.primaryGlow, size: 14),
                  const SizedBox(width: 8),
                  Text(pro, style: theme.textTheme.labelSmall?.copyWith(color: colors.primaryGlow)),
                ],
              ),
            )),
            ...cons.map((con) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Icon(Icons.remove_rounded, color: colors.error, size: 14),
                  const SizedBox(width: 8),
                  Text(con, style: theme.textTheme.labelSmall?.copyWith(color: colors.error)),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }
}
