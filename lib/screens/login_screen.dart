import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/promotion_provider.dart';
import '../providers/shop_provider.dart';
import '../providers/user_dashboard_provider.dart';
import '../providers/voucher_provider.dart';
import 'admin/admin_dashboard.dart';
import 'admin/admin_signup_screen.dart';
import 'signup_screen.dart';
import 'user/user_dashboard.dart';
import '../providers/item_provider.dart';
import '../providers/user_management_provider.dart';
import '../providers/admin_dashboard_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    this.initialTab = 0,
    this.showTabs = true,
  });

  static const routeName = '/login';
  final int initialTab; // 0 for User, 1 for Admin
  final bool showTabs; // If false, show only the selected tab's form

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;

  final _userFormKey = GlobalKey<FormState>();
  final _adminFormKey = GlobalKey<FormState>();

  final _userEmailController = TextEditingController();
  final _userPasswordController = TextEditingController();
  final _adminEmailController = TextEditingController();
  final _adminPasswordController = TextEditingController();

  bool _isUserLoading = false;
  bool _isAdminLoading = false;
  bool _userObscurePassword = true;
  bool _adminObscurePassword = true;

  @override
  void initState() {
    super.initState();
    if (widget.showTabs) {
      _tabController = TabController(
        length: 2,
        vsync: this,
        initialIndex: widget.initialTab,
      );
    }
  }

  @override
  void dispose() {
    _tabController?.dispose();
    _userEmailController.dispose();
    _userPasswordController.dispose();
    _adminEmailController.dispose();
    _adminPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleUserLogin() async {
    if (!_userFormKey.currentState!.validate()) {
      return;
    }

    setState(() => _isUserLoading = true);
    final auth = context.read<AuthProvider>();
    final error = await auth.loginUser(
      _userEmailController.text.trim(),
      _userPasswordController.text,
    );
    setState(() => _isUserLoading = false);

    if (error != null) {
      if (!mounted) return;
      _showSnackBar(error);
      return;
    }

    if (!mounted) return;
    final voucherProvider = context.read<VoucherProvider>();
    final promotionProvider = context.read<PromotionProvider>();
    final dashboardProvider = context.read<UserDashboardProvider>();
    final notificationProvider = context.read<NotificationProvider>();
    final user = auth.currentUser;
    if (user != null) {
      await voucherProvider.setUserContext(user.id!);
      await voucherProvider.loadRedeemedHistory(userId: user.id!);
      promotionProvider.setAdminContext(null);
      await promotionProvider.loadActivePromotionsForUsers();
      await promotionProvider.loadPromotionsForUsers(includeExpired: true);
      await dashboardProvider.loadSummary(user.id!);
      await dashboardProvider.loadShopNames();
      await notificationProvider.setUser(user.id!);
    } else {
      voucherProvider.resetUserView();
      promotionProvider.setAdminContext(null);
    }

    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(
      UserDashboard.routeName,
      (route) => false,
    );
  }

  Future<void> _handleAdminLogin() async {
    if (!_adminFormKey.currentState!.validate()) {
      return;
    }

    setState(() => _isAdminLoading = true);
    final auth = context.read<AuthProvider>();
    final error = await auth.loginAdmin(
      _adminEmailController.text.trim(),
      _adminPasswordController.text,
    );
    setState(() => _isAdminLoading = false);

    if (error != null) {
      if (!mounted) return;
      _showSnackBar(error);
      return;
    }

    if (!mounted) return;
    final admin = auth.currentAdmin;
    if (admin != null && admin.id != null) {
      final voucherProvider = context.read<VoucherProvider>();
      final shopProvider = context.read<ShopProvider>();
      final promotionProvider = context.read<PromotionProvider>();
      final itemProvider = context.read<ItemProvider>();
      final userManagementProvider = context.read<UserManagementProvider>();
      final notificationProvider = context.read<NotificationProvider>();
      final adminDashboardProvider = context.read<AdminDashboardProvider>();
      voucherProvider.setAdminContext(admin.id);
      await shopProvider.loadShops(admin.id!);
      promotionProvider.setAdminContext(admin.id);
      await promotionProvider.refreshPromotions();
      await itemProvider.setAdmin(admin.id!);
      await userManagementProvider.loadUsers();
      await notificationProvider.loadAllNotificationsForAdmin();
      await adminDashboardProvider.loadDashboard(admin.id!);
    } else {
      auth.logout();
      _showSnackBar('Admin login failed unexpectedly. Please try again.');
      return;
    }

    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(AdminDashboard.routeName);
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Light green color matching the welcome page
    const primaryGreen = Color(0xFF66BB6A);
    const darkGreen = Color(0xFF2E7D32);

    return Scaffold(
      body: Column(
        children: [
          // Top section with green gradient and logo
          Expanded(
            flex: 2,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    darkGreen,
                    darkGreen.withValues(alpha: 0.9),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: SafeArea(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo container
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              primaryGreen.withValues(alpha: 0.3),
                              primaryGreen.withValues(alpha: 0.2),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          Icons.card_giftcard_rounded,
                          size: 60,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // App name
                      Text(
                        'D-VOUCHER',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Find Your Perfect Deals',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Bottom section with white background and tabs
          Expanded(
            flex: 3,
            child: Container(
              color: Colors.white,
              child: SafeArea(
                top: false,
                child: widget.showTabs
                    ? Column(
                        children: [
                          // Tabs
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: TabBar(
                              controller: _tabController!,
                              indicator: BoxDecoration(
                                color: primaryGreen,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              labelColor: Colors.white,
                              unselectedLabelColor: Colors.grey[700],
                              labelStyle: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                              tabs: const [
                                Tab(text: 'User'),
                                Tab(text: 'Admin'),
                              ],
                            ),
                          ),
                          // Tab views
                          Expanded(
                            child: TabBarView(
                              controller: _tabController!,
                              children: [
                                _buildUserLoginForm(primaryGreen),
                                _buildAdminLoginForm(primaryGreen),
                              ],
                            ),
                          ),
                        ],
                      )
                    : SingleChildScrollView(
                        child: widget.initialTab == 0
                            ? _buildUserLoginForm(primaryGreen)
                            : _buildAdminLoginForm(primaryGreen),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserLoginForm(Color primaryGreen) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Form(
        key: _userFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _userEmailController,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(fontSize: 16),
              decoration: InputDecoration(
                labelText: 'Email',
                labelStyle: TextStyle(color: primaryGreen),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: primaryGreen.withValues(alpha: 0.5)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: primaryGreen.withValues(alpha: 0.5)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: primaryGreen, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your email';
                }
                if (!value.contains('@')) {
                  return 'Email is not valid';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _userPasswordController,
              obscureText: _userObscurePassword,
              style: const TextStyle(fontSize: 16),
              decoration: InputDecoration(
                labelText: 'Password',
                labelStyle: TextStyle(color: primaryGreen),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: primaryGreen.withValues(alpha: 0.5)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: primaryGreen.withValues(alpha: 0.5)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: primaryGreen, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                suffixIcon: IconButton(
                  icon: Icon(
                    _userObscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    color: primaryGreen.withValues(alpha: 0.7),
                  ),
                  onPressed: () {
                    setState(() => _userObscurePassword = !_userObscurePassword);
                  },
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Password is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  _showSnackBar('Forgot password feature coming soon!');
                },
                child: Text(
                  'forgot password?',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isUserLoading ? null : _handleUserLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: _isUserLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'login',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Don\'t have an account? ',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pushNamed(SignUpScreen.routeName);
                  },
                  child: const Text(
                    'Sign up',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminLoginForm(Color primaryGreen) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Form(
        key: _adminFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _adminEmailController,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(fontSize: 16),
              decoration: InputDecoration(
                labelText: 'Email',
                labelStyle: TextStyle(color: primaryGreen),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: primaryGreen.withValues(alpha: 0.5)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: primaryGreen.withValues(alpha: 0.5)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: primaryGreen, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your email';
                }
                if (!value.contains('@')) {
                  return 'Email is not valid';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _adminPasswordController,
              obscureText: _adminObscurePassword,
              style: const TextStyle(fontSize: 16),
              decoration: InputDecoration(
                labelText: 'Password',
                labelStyle: TextStyle(color: primaryGreen),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: primaryGreen.withValues(alpha: 0.5)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: primaryGreen.withValues(alpha: 0.5)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: primaryGreen, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                suffixIcon: IconButton(
                  icon: Icon(
                    _adminObscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    color: primaryGreen.withValues(alpha: 0.7),
                  ),
                  onPressed: () {
                    setState(() => _adminObscurePassword = !_adminObscurePassword);
                  },
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Password is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  _showSnackBar('Forgot password feature coming soon!');
                },
                child: Text(
                  'forgot password?',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isAdminLoading ? null : _handleAdminLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: _isAdminLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'login',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Don\'t have an account? ',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pushNamed(AdminSignUpScreen.routeName);
                  },
                  child: const Text(
                    'Sign up',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

