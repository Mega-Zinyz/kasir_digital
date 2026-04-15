import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:io' show Platform;
import 'package:window_manager/window_manager.dart';
import 'providers/index.dart';
import 'screens/index.dart';
import 'widgets/index.dart';
import 'services/scheduled_backup_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize sqflite for Windows/Linux
  if (Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    
    // Initialize window manager for desktop
    if (Platform.isWindows) {
      await windowManager.ensureInitialized();
      await windowManager.setMinimumSize(const Size(1024, 768));
      await windowManager.setFullScreen(true);
    }
  }
  
  await initializeDateFormatting('id_ID', null);
  runApp(const MyApp());
}

ColorScheme _buildLightColorScheme() {
  final base = ColorScheme.fromSeed(
    seedColor: Colors.blue,
    brightness: Brightness.light,
  );

  return base.copyWith(
    primary: const Color(0xFF1976D2),
    onPrimary: Colors.white,
    primaryContainer: const Color(0xFFF1F8FF),
    onPrimaryContainer: const Color(0xFF0D47A1),
    secondary: const Color(0xFF2E7D32),
    onSecondary: Colors.white,
    secondaryContainer: const Color(0xFFF1F8F2),
    onSecondaryContainer: const Color(0xFF1B5E20),
    tertiary: const Color(0xFFEF6C00),
    onTertiary: Colors.white,
    tertiaryContainer: const Color(0xFFFFF7ED),
    onTertiaryContainer: const Color(0xFFE65100),
    error: const Color(0xFFD32F2F),
    onError: Colors.white,
    errorContainer: const Color(0xFFFFF1F2),
    onErrorContainer: const Color(0xFFB71C1C),
    surface: Colors.white,
    onSurface: const Color(0xFF212121),
    onSurfaceVariant: const Color(0xFF616161),
    outline: const Color(0xFFC7CDD3),
    outlineVariant: const Color(0xFFE8EDF2),
    surfaceContainerLowest: const Color(0xFFFFFFFF),
    surfaceContainerLow: const Color(0xFFFFFBFF),
    surfaceContainer: const Color(0xFFFCFDFF),
    surfaceContainerHigh: const Color(0xFFF8FAFC),
    surfaceContainerHighest: const Color(0xFFF3F6F9),
    shadow: Colors.black.withValues(alpha: 0.10),
    inverseSurface: const Color(0xFF263238),
    onInverseSurface: Colors.white,
  );
}

ColorScheme _buildDarkColorScheme() {
  return ColorScheme.fromSeed(
    seedColor: Colors.blue,
    brightness: Brightness.dark,
  );
}

ThemeData _buildAppTheme(Brightness brightness) {
  final colorScheme = brightness == Brightness.dark
      ? _buildDarkColorScheme()
      : _buildLightColorScheme();

  return ThemeData(
    colorScheme: colorScheme,
    useMaterial3: true,
    fontFamily: 'Roboto',
    scaffoldBackgroundColor: colorScheme.surface,
    cardTheme: CardThemeData(
      color: brightness == Brightness.dark ? null : colorScheme.surface,
      elevation: brightness == Brightness.dark ? null : 1,
      shadowColor: colorScheme.shadow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: brightness == Brightness.dark
              ? Colors.transparent
              : colorScheme.outlineVariant,
        ),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor:
          brightness == Brightness.dark ? null : colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: brightness == Brightness.dark
          ? colorScheme.inverseSurface
          : colorScheme.primary,
      contentTextStyle: TextStyle(color: colorScheme.onInverseSurface),
      actionTextColor: brightness == Brightness.dark
          ? colorScheme.primary
          : colorScheme.onPrimary,
      behavior: SnackBarBehavior.floating,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: colorScheme.primary,
      foregroundColor: colorScheme.onPrimary,
      elevation: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: brightness == Brightness.light,
      fillColor: brightness == Brightness.light
          ? colorScheme.surface
          : null,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: colorScheme.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: colorScheme.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: colorScheme.primary, width: 2),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        disabledBackgroundColor: colorScheme.onSurface.withValues(alpha: 0.12),
        disabledForegroundColor: colorScheme.onSurface.withValues(alpha: 0.38),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: colorScheme.onSurfaceVariant,
        side: BorderSide(color: colorScheme.outline),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: colorScheme.primary,
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: colorScheme.primary,
      foregroundColor: colorScheme.onPrimary,
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => TransactionProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => HardwareProvider()),
        ChangeNotifierProvider(create: (_) => CategoryProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, settings, _) => MaterialApp(
          title: 'Kasir Digital',
          locale: Locale('id', 'ID'),
          debugShowCheckedModeBanner: false,
          themeMode: settings.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          theme: _buildAppTheme(Brightness.light),
          darkTheme: _buildAppTheme(Brightness.dark),
          home: const MainScreen(),
        ),
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  late ScheduledBackupService _scheduledBackupService;

  @override
  void initState() {
    super.initState();
    _initializeBackupScheduler();
    _initializeWindowMode();
  }

  Future<void> _initializeWindowMode() async {
    if (Platform.isWindows) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (mounted) {
          final settings = context.read<SettingsProvider>();
          if (settings.isFullscreen) {
            await windowManager.maximize();
          }
        }
      });
    }
  }

  Future<void> _initializeBackupScheduler() async {
    _scheduledBackupService = ScheduledBackupService();
    
    // Get settings from provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final settings = context.read<SettingsProvider>();
        _scheduledBackupService.startScheduledBackups(
          frequency: settings.backupFrequency,
          lastBackupTime: settings.lastBackupTime,
          backupDirectory: settings.getBackupPath(),
        );
        
        // Set up callbacks
        _scheduledBackupService.onBackupComplete = (message) {
          if (mounted) {
            settings.setLastBackupTime(DateTime.now());
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(message),
                backgroundColor: Colors.green,
              ),
            );
          }
        };
        
        _scheduledBackupService.onBackupError = (error) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(error),
                backgroundColor: Colors.red,
              ),
            );
          }
        };
      }
    });
  }

  @override
  void dispose() {
    _scheduledBackupService.stopScheduledBackups();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Gunakan NavigationRail untuk Windows (desktop)
    if (MediaQuery.of(context).size.width > 600) {
      return Scaffold(
        body: Row(
          children: [
            AppSidebar(
              selectedIndex: _selectedIndex,
              onItemTap: (index) {
                setState(() => _selectedIndex = index);
              },
            ),
            Expanded(
              child: IndexedStack(
                index: _selectedIndex,
                children: [
                  DashboardScreen(onNavigate: (index) => setState(() => _selectedIndex = index)),
                  SalesScreen(),
                  ProductListScreen(),
                  HistoryScreen(),
                  AnalyticsScreen(),
                  BackupScreen(),
                  SettingsScreen(),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Gunakan BottomNavigationBar untuk mobile
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          DashboardScreen(onNavigate: (index) => setState(() => _selectedIndex = index)),
          SalesScreen(),
          ProductListScreen(),
          HistoryScreen(),
          AnalyticsScreen(),
          BackupScreen(),
          SettingsScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        destinations: [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_shopping_cart_outlined),
            selectedIcon: Icon(Icons.add_shopping_cart),
            label: 'Penjualan',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: 'Barang',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'History',
          ),
          NavigationDestination(
            icon: Icon(Icons.analytics_outlined),
            selectedIcon: Icon(Icons.analytics),
            label: 'Analitik',
          ),
          NavigationDestination(
            icon: Icon(Icons.backup_outlined),
            selectedIcon: Icon(Icons.backup),
            label: 'Backup',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Pengaturan',
          ),
        ],
      ),
    );
  }
}
