import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'screens/transfer_screen.dart';

/// Root app widget with bottom navigation between Home and Transfer screens.
///
/// Uses a custom dark industrial-tech theme with Unbounded display font
/// and Source Code Pro monospace body. Navigation bar uses the design
/// system's cyan accent for selected state.
class TurboLinkApp extends StatefulWidget {
  const TurboLinkApp({super.key});

  @override
  State<TurboLinkApp> createState() => _TurboLinkAppState();
}

class _TurboLinkAppState extends State<TurboLinkApp> {
  int _currentIndex = 0;

  static const _screens = [
    HomeScreen(),
    TransferScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TurboLink',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: Scaffold(
        backgroundColor: AppTheme.surface,
        appBar: AppBar(
          title: Row(
            children: [
              // Logo mark: a small glowing bolt.
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  gradient: AppTheme.cyanGradient,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.bolt_rounded,
                  color: AppTheme.surface,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'TURBOLINK',
                style: GoogleFonts.unbounded(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
          actions: [
            // Status indicator dot.
            Container(
              margin: const EdgeInsets.only(right: AppTheme.spacingMd),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppTheme.cyanDim,
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
          ],
        ),
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _screens[_currentIndex],
        ),
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
            color: AppTheme.surfaceAlt,
            border: Border(
              top: BorderSide(color: AppTheme.border, width: 0.5),
            ),
          ),
          child: NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: (i) => setState(() => _currentIndex = i),
            height: 64,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.radar_rounded, color: AppTheme.textTertiary),
                selectedIcon: Icon(Icons.radar_rounded, color: AppTheme.cyan),
                label: 'DISCOVER',
              ),
              NavigationDestination(
                icon: Icon(Icons.swap_vert_rounded, color: AppTheme.textTertiary),
                selectedIcon: Icon(Icons.swap_vert_rounded, color: AppTheme.cyan),
                label: 'TRANSFERS',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
