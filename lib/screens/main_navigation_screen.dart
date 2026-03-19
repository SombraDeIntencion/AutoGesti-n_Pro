import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'vehicle_list_screen.dart';
import 'billing_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const VehicleListScreen(),
    const BillingScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          selectedItemColor: const Color(0xFF17A2B8),
          unselectedItemColor: Colors.grey,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          elevation: 0,
          selectedFontSize: 14,
          unselectedFontSize: 12,
          items: [
            BottomNavigationBarItem(
              icon: SvgPicture.asset(
                'public/images/icon.svg',
                width: 24,
                height: 24,
                colorFilter: ColorFilter.mode(
                  _selectedIndex == 0 ? const Color(0xFF17A2B8) : Colors.grey,
                  BlendMode.srcIn,
                ),
              ),
              label: 'Vehículos',
            ),
            BottomNavigationBarItem(
              icon: SvgPicture.asset(
                'public/images/icon1.svg',
                width: 24,
                height: 24,
                colorFilter: ColorFilter.mode(
                  _selectedIndex == 1 ? const Color(0xFF17A2B8) : Colors.grey,
                  BlendMode.srcIn,
                ),
              ),
              label: 'Facturación',
            ),
          ],
        ),
      ),
    );
  }
}
