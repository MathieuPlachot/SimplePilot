import 'package:flutter/material.dart';
import 'package:flutter_pilot/pages/about_page.dart';
import '../widgets/bottom_navbar.dart';
import 'home_page.dart';
import 'chart_page.dart';
import 'settings_page.dart';

class HomeShell extends StatefulWidget {
  @override
  _HomeShellState createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _currentIndex = 1; // default Home tab
  late final PageController _pageController;

  final List<Widget> _pages = [ChartPage(), HomePage(), SettingsPage()];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  int _drawerSelectedIndex() {
    switch (_currentIndex) {
      case 1:
        return 0; // Home
      case 0:
        return 1; // Chart
      case 2:
        return 2; // Settings
      default:
        return -1; // About (not part of bottom nav)
    }
  }

  void _onDrawerSelected(int index) {
    Navigator.pop(context); // close drawer

    switch (index) {
      case 0: // Home
        _onTabSelected(1); // bottom nav index for Home

      case 1: // Chart
        _onTabSelected(0); // bottom nav index for Chart

      case 2: // Settings
        _onTabSelected(2); // bottom nav index for Settings

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
