// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/admin_dashboard_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/item_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/promotion_provider.dart';
import 'providers/shop_provider.dart';
import 'providers/user_dashboard_provider.dart';
import 'providers/user_management_provider.dart';
import 'providers/voucher_provider.dart';
import 'screens/admin/admin_dashboard.dart';
import 'screens/admin/admin_signup_screen.dart';
import 'screens/admin/promotions/promotions_list_screen.dart';
import 'screens/admin/promotions/promotion_form_screen.dart';
import 'screens/login_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/user/user_dashboard.dart';
import 'services/database_helper.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.instance.initialize();
  await DatabaseHelper.instance.database;
  runApp(const DvoucherApp());
}

// Modern green color palette
const Color _primaryGreen = Color(0xFF66BB6A); // Light green
const Color _darkGreen = Color(0xFF2E7D32); // Dark green
const Color _lightGreen = Color(0xFFA5D6A7); // Very light green
const Color _accentGreen = Color(0xFF4CAF50); // Medium green
const Color _mist = Color(0xFFF5F5F5); // Light background
const Color _charcoal = Color(0xFF212121); // Dark text

ColorScheme _appColorScheme(Brightness brightness) {
  final isLight = brightness == Brightness.light;
  final background = isLight ? _mist : _charcoal;
  final onBackground = isLight ? _charcoal : _mist;
  final surface = background;
  final onSurface = onBackground;
  final outline = isLight ? _charcoal : _mist;

  return ColorScheme(
    brightness: brightness,
    primary: _primaryGreen,
    onPrimary: Colors.white,
    primaryContainer: _lightGreen,
    onPrimaryContainer: _darkGreen,
    secondary: _accentGreen,
    onSecondary: Colors.white,
    secondaryContainer: _lightGreen.withValues(alpha: 0.5),
    onSecondaryContainer: _darkGreen,
    tertiary: _darkGreen,
    onTertiary: Colors.white,
    tertiaryContainer: _lightGreen,
    onTertiaryContainer: _darkGreen,
    error: const Color(0xFFD32F2F),
    onError: Colors.white,
    errorContainer: const Color(0xFFEF5350).withValues(alpha: 0.2),
    onErrorContainer: const Color(0xFFD32F2F),
    background: background,
    onBackground: onBackground,
    surface: surface,
    onSurface: onSurface,
    surfaceVariant: background,
    onSurfaceVariant: onSurface,
    outline: outline,
    outlineVariant: outline,
    shadow: _charcoal,
    scrim: _charcoal,
    inverseSurface: onBackground,
    onInverseSurface: background,
    inversePrimary: _primaryGreen,
    surfaceTint: _primaryGreen,
    primaryFixed: _primaryGreen,
    onPrimaryFixed: Colors.white,
    primaryFixedDim: _darkGreen,
    onPrimaryFixedVariant: Colors.white,
    secondaryFixed: _accentGreen,
    onSecondaryFixed: Colors.white,
    secondaryFixedDim: _darkGreen,
    onSecondaryFixedVariant: Colors.white,
    tertiaryFixed: _darkGreen,
    onTertiaryFixed: Colors.white,
    tertiaryFixedDim: const Color(0xFF1B5E20),
    onTertiaryFixedVariant: Colors.white,
    surfaceBright: surface,
    surfaceDim: surface,
    surfaceContainerHighest: surface,
    surfaceContainerHigh: surface,
    surfaceContainer: surface,
    surfaceContainerLow: surface,
    surfaceContainerLowest: surface,
  );
}

ThemeData _buildTheme(Brightness brightness) {
  final scheme = _appColorScheme(brightness);
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: scheme.surface,
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      centerTitle: false,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
    ),
    cardTheme: CardThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      color: scheme.surface,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surfaceContainerHighest,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: scheme.outline.withValues(alpha: 0.2),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: scheme.primary,
          width: 2,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: scheme.primary,
      foregroundColor: scheme.onPrimary,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    cardColor: scheme.surface,
    dividerColor: scheme.outline.withValues(alpha: 0.2),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: scheme.primary,
      selectionColor: scheme.primary.withValues(alpha: 0.2),
      selectionHandleColor: scheme.primary,
    ),
  );
}

class DvoucherApp extends StatelessWidget {
  const DvoucherApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => VoucherProvider()),
        ChangeNotifierProvider(create: (_) => ShopProvider()),
        ChangeNotifierProvider(create: (_) => PromotionProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => UserDashboardProvider()),
        ChangeNotifierProvider(create: (_) => ItemProvider()),
        ChangeNotifierProvider(create: (_) => UserManagementProvider()),
        ChangeNotifierProvider(create: (_) => AdminDashboardProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'D-Voucher',
        themeMode: ThemeMode.system,
        theme: _buildTheme(Brightness.light),
        darkTheme: _buildTheme(Brightness.dark),
        home: _InitialRoute(),
        routes: {
          OnboardingScreen.routeName: (_) => const OnboardingScreen(),
          LoginScreen.routeName: (_) => const LoginScreen(),
          SignUpScreen.routeName: (_) => const SignUpScreen(),
          UserDashboard.routeName: (_) => const UserDashboard(),
          AdminDashboard.routeName: (_) => const AdminDashboard(),
          AdminSignUpScreen.routeName: (_) => const AdminSignUpScreen(),
          PromotionsListScreen.routeName: (_) => const PromotionsListScreen(),
          PromotionFormScreen.routeName: (_) => const PromotionFormScreen(),
        },
      ),
    );
  }
}

class _InitialRoute extends StatefulWidget {
  const _InitialRoute();

  @override
  State<_InitialRoute> createState() => _InitialRouteState();
}

class _InitialRouteState extends State<_InitialRoute> {
  @override
  Widget build(BuildContext context) {
    // Always show onboarding screen first
    return const OnboardingScreen();
  }
}
