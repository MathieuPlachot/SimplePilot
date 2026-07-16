import 'package:flutter/material.dart';
import 'package:flutter_pilot/pages/about_page.dart';
import 'package:flutter_pilot/services/udp_handler.dart';
import 'package:provider/provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../widgets/bottom_navbar.dart';
import 'home_page.dart';
import 'chart_page.dart';
import 'settings_page.dart';

class HomeShell extends StatefulWidget {
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> with WidgetsBindingObserver {
  int _currentIndex = 0; // default Home tab
  late final PageController _pageController;

  final List<Widget> _pages = [HomePage(), ChartPage(), SettingsPage()];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);

    WidgetsBinding.instance.addObserver(this);

    // Prevents the screen from turning off automatically
    WakelockPlus.enable();

    // Start polling immediately if app starts in foreground
    Future.microtask(() {
      if (!mounted) return;
      context.read<UDPHandler>().startPolling();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    context.read<UDPHandler>().stopPolling();
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final udpHandler = context.read<UDPHandler>();

    if (state == AppLifecycleState.resumed) {
      udpHandler.startPolling();
      WakelockPlus.enable();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      udpHandler.stopPolling();
      WakelockPlus.disable();
    }
  }

  int _drawerSelectedIndex() {
    if (_currentIndex <= 2) return _currentIndex;
    return -1; // About (not part of bottom nav)
  }

  void _onDrawerSelected(int index) {
    Navigator.pop(context); // close drawer

    switch (index) {
      case 0: // Home
      case 1: // Chart
      case 2: // Settings
        _onTabSelected(index);

      case 3: // About
        Navigator.push(context, MaterialPageRoute(builder: (_) => AboutPage()));
    }
  }

  void _onTabSelected(int index) {
    setState(() {
      _currentIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Simple Pilot'),
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      drawer: NavigationDrawer(
        header: const Padding(
          padding: EdgeInsets.fromLTRB(16, 24, 16, 12),
          child: Text(
            "Menu",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
        ),
        selectedIndex: _drawerSelectedIndex(),
        onDestinationSelected: _onDrawerSelected,
        children: const [
          NavigationDrawerDestination(
            icon: Icon(Icons.home),
            label: Text("Home"),
          ),
          NavigationDrawerDestination(
            icon: Icon(Icons.show_chart),
            label: Text("Chart"),
          ),
          NavigationDrawerDestination(
            icon: Icon(Icons.settings),
            label: Text("Settings"),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Divider(),
          ),
          NavigationDrawerDestination(
            icon: Icon(Icons.info),
            label: Text("About"),
          ),
        ],
      ),
      body: PageView(
        controller: _pageController,
        physics:
            NeverScrollableScrollPhysics(), // disable swipe = only navbar control
        children: _pages,
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onTabSelected,
      ),
    );
  }
}
