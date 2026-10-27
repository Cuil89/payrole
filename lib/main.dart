import 'package:flutter/material.dart';

import 'core/theme.dart';
import 'data/app_store.dart';
import 'data/models.dart';
import 'data/secure_vault.dart';
import 'pages/attendance_page.dart';
import 'pages/dashboard_page.dart';
import 'pages/employees_page.dart';
import 'pages/help_page.dart';
import 'pages/karyawan_portal_page.dart';
import 'pages/mandor_portal_page.dart';
import 'pages/owner_master_tarif_page.dart';
import 'pages/payroll_page.dart';
import 'pages/reimbursement_page.dart';
import 'pages/reports_page.dart';
import 'pages/settings_page.dart';
import 'pages/super_admin_page.dart';
import 'security/auth_state.dart';
import 'widgets/modals/security_lock_overlay.dart';
import 'widgets/sidebar.dart';
import 'widgets/topbar.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize hardware-backed secure storage vault with memory fallback
  SecureVault vault;
  try {
    vault = PlatformSecureVault();
  } catch (_) {
    vault = MemoryVault();
  }

  final appStore = AppStore(vault);
  final authState = AuthState(vault);

  await Future.wait([
    appStore.load(),
    authState.initialize(),
  ]);

  runApp(PayroleApp(store: appStore, authState: authState));
}

class PayroleApp extends StatelessWidget {
  const PayroleApp({
    super.key,
    required this.store,
    required this.authState,
  });

  final AppStore store;
  final AuthState authState;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Payrole - Sistem Penggajian Konveksi & Garmen',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        return MediaQuery(
          data: mediaQuery.copyWith(
            textScaler: mediaQuery.textScaler.clamp(
              minScaleFactor: 0.85,
              maxScaleFactor: 1.15,
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: SecurityLockOverlay(
        authState: authState,
        child: AppShell(store: store, authState: authState),
      ),
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    required this.store,
    required this.authState,
  });

  final AppStore store;
  final AuthState authState;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> with WidgetsBindingObserver {
  AppTab _currentTab = AppTab.payroll;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  UserRole? _lastRole;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _lastRole = widget.store.currentUser.role;
    widget.store.addListener(_onStoreUpdate);
  }

  @override
  void dispose() {
    widget.store.removeListener(_onStoreUpdate);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _onStoreUpdate() {
    // If role changed, seamlessly switch to that role's primary landing tab!
    if (widget.store.currentUser.role != _lastRole) {
      _lastRole = widget.store.currentUser.role;
      setState(() {
        switch (_lastRole!) {
          case UserRole.superAdmin:
            _currentTab = AppTab.superAdmin;
          case UserRole.pemilik:
            _currentTab = AppTab.masterTarif;
          case UserRole.adminKeuangan:
            _currentTab = AppTab.payroll;
          case UserRole.mandor:
            _currentTab = AppTab.mandorPortal;
          case UserRole.karyawan:
            _currentTab = AppTab.karyawanPortal;
        }
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      widget.store.flush();
      widget.authState.lockSession();
    }
  }

  void _onSelectTab(AppTab tab) {
    setState(() => _currentTab = tab);
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.store,
      builder: (context, _) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final isMobileOrTablet = constraints.maxWidth < 992;

            return Scaffold(
              key: _scaffoldKey,
              backgroundColor: AppColors.bg,
              // Drawer for mobile / tablet screens
              drawer: isMobileOrTablet
                  ? Drawer(
                      child: Sidebar(
                        currentTab: _currentTab,
                        onSelectTab: _onSelectTab,
                        companyName: widget.store.settings.companyName,
                        currentUser: widget.store.currentUser,
                        isDrawer: true,
                        onLogout: () => widget.authState.lockSession(),
                      ),
                    )
                  : null,
              body: Row(
                children: [
                  // Desktop Fixed Sidebar
                  if (!isMobileOrTablet)
                    Sidebar(
                      currentTab: _currentTab,
                      onSelectTab: _onSelectTab,
                      companyName: widget.store.settings.companyName,
                      currentUser: widget.store.currentUser,
                      onLogout: () => widget.authState.lockSession(),
                    ),

                  // Main Content Area
                  Expanded(
                    child: Column(
                      children: [
                        // Topbar with 1-click Role Switcher & Status
                        Topbar(
                          currentTab: _currentTab,
                          store: widget.store,
                          isMobile: isMobileOrTablet,
                          onMenuPressed: () {
                            _scaffoldKey.currentState?.openDrawer();
                          },
                          onNotificationPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Log Sesi Aktif: ${widget.store.currentUser.name} (${widget.store.currentUser.role.label}) · Semua data tersinkron.',
                                ),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                        ),

                        // Active Tab View
                        Expanded(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: _buildCurrentTab(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCurrentTab() {
    switch (_currentTab) {
      case AppTab.superAdmin:
        return SuperAdminPage(
          key: const ValueKey('superAdmin'),
          store: widget.store,
        );
      case AppTab.masterTarif:
        return OwnerMasterTarifPage(
          key: const ValueKey('masterTarif'),
          store: widget.store,
        );
      case AppTab.mandorPortal:
        return MandorPortalPage(
          key: const ValueKey('mandorPortal'),
          store: widget.store,
        );
      case AppTab.karyawanPortal:
        return KaryawanPortalPage(
          key: const ValueKey('karyawanPortal'),
          store: widget.store,
        );
      case AppTab.summary:
        return DashboardPage(
          key: const ValueKey('summary'),
          store: widget.store,
          onNavigateToTab: _onSelectTab,
        );
      case AppTab.employees:
        return EmployeesPage(
          key: const ValueKey('employees'),
          store: widget.store,
        );
      case AppTab.attendance:
        return AttendancePage(
          key: const ValueKey('attendance'),
          store: widget.store,
        );
      case AppTab.payroll:
        return PayrollPage(
          key: const ValueKey('payroll'),
          store: widget.store,
        );
      case AppTab.reimbursement:
        return ReimbursementPage(
          key: const ValueKey('reimbursement'),
          store: widget.store,
        );
      case AppTab.reports:
        return ReportsPage(
          key: const ValueKey('reports'),
          store: widget.store,
        );
      case AppTab.settings:
        return SettingsPage(
          key: const ValueKey('settings'),
          store: widget.store,
          authState: widget.authState,
        );
      case AppTab.help:
        return const HelpPage(
          key: ValueKey('help'),
        );
    }
  }
}
