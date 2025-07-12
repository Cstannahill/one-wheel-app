import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'providers/ride_provider.dart';
import 'screens/dashboard_screen.dart';
import 'screens/rides_screen.dart';
import 'screens/map_screen.dart';
import 'screens/settings_screen.dart';

void main() {
  runApp(const OneWheelApp());
}

class OneWheelApp extends StatelessWidget {
  const OneWheelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => RideProvider()..generateDummyRides()),
      ],
      child: MaterialApp.router(
        title: 'OneWheel Tracker',
        themeMode: ThemeMode.dark, // Default to dark mode
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF00D4FF), // Electric blue
            brightness: Brightness.light,
          ),
          useMaterial3: true,
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF00D4FF), // Electric blue
            brightness: Brightness.dark,
          ).copyWith(
            // Custom dark theme colors for a sleek, edgy look
            surface: const Color(0xFF0A0A0A), // Almost black
            onSurface: const Color(0xFFE0E0E0), // Light gray text
            surfaceVariant: const Color(0xFF1A1A1A), // Dark gray surfaces
            onSurfaceVariant: const Color(0xFFB0B0B0), // Medium gray text
            primary: const Color(0xFF00D4FF), // Electric blue
            secondary: const Color(0xFF7C4DFF), // Purple accent
            tertiary: const Color(0xFF00FF88), // Green accent
            error: const Color(0xFFFF4444), // Red
          ),
          scaffoldBackgroundColor: const Color(0xFF0A0A0A),
          cardTheme: const CardThemeData(
            color: Color(0xFF1A1A1A),
            elevation: 8,
            shadowColor: Colors.black54,
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF1A1A1A),
            foregroundColor: Color(0xFFE0E0E0),
            elevation: 0,
            centerTitle: true,
          ),
          navigationBarTheme: NavigationBarThemeData(
            backgroundColor: const Color(0xFF1A1A1A),
            indicatorColor: const Color(0xFF00D4FF).withOpacity(0.3),
            labelTextStyle: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return const TextStyle(color: Color(0xFF00D4FF), fontSize: 12, fontWeight: FontWeight.w600);
              }
              return const TextStyle(color: Color(0xFFB0B0B0), fontSize: 12);
            }),
            iconTheme: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return const IconThemeData(color: Color(0xFF00D4FF));
              }
              return const IconThemeData(color: Color(0xFFB0B0B0));
            }),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00D4FF),
              foregroundColor: const Color(0xFF0A0A0A),
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          textTheme: const TextTheme(
            headlineLarge: TextStyle(color: Color(0xFFE0E0E0), fontWeight: FontWeight.bold),
            headlineMedium: TextStyle(color: Color(0xFFE0E0E0), fontWeight: FontWeight.w600),
            bodyLarge: TextStyle(color: Color(0xFFE0E0E0)),
            bodyMedium: TextStyle(color: Color(0xFFB0B0B0)),
            labelLarge: TextStyle(color: Color(0xFF00D4FF), fontWeight: FontWeight.w600),
          ),
          useMaterial3: true,
        ),
        routerConfig: _router,
      ),
    );
  }
}

final _router = GoRouter(
  routes: [
    ShellRoute(
      builder: (context, state, child) {
        return MainNavigationScreen(child: child);
      },
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const DashboardScreen(),
        ),
        GoRoute(
          path: '/rides',
          builder: (context, state) => const RidesScreen(),
        ),
        GoRoute(
          path: '/map',
          builder: (context, state) => const MapScreen(),
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsScreen(),
        ),
      ],
    ),
  ],
);

class MainNavigationScreen extends StatefulWidget {
  final Widget child;

  const MainNavigationScreen({super.key, required this.child});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  final List<NavigationDestination> _destinations = [
    const NavigationDestination(
      icon: Icon(Icons.dashboard_outlined),
      selectedIcon: Icon(Icons.dashboard),
      label: 'Dashboard',
    ),
    const NavigationDestination(
      icon: Icon(Icons.route_outlined),
      selectedIcon: Icon(Icons.route),
      label: 'Rides',
    ),
    const NavigationDestination(
      icon: Icon(Icons.map_outlined),
      selectedIcon: Icon(Icons.map),
      label: 'Map',
    ),
    const NavigationDestination(
      icon: Icon(Icons.settings_outlined),
      selectedIcon: Icon(Icons.settings),
      label: 'Settings',
    ),
  ];

  final List<String> _routes = ['/', '/rides', '/map', '/settings'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
          context.go(_routes[index]);
        },
        destinations: _destinations,
      ),
    );
  }
}
