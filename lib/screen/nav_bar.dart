import 'package:flutter/material.dart';

class NavBar extends StatefulWidget {
  final int currentIndex;
  const NavBar({
    Key? key,
    required this.currentIndex,
  }) : super(key: key);

  @override
  State<NavBar> createState() => _NavBarState();
}

class _NavBarState extends State<NavBar> {
  void _onItemTapped(BuildContext context, int index) {
    if (index == 0) {
      Navigator.pushReplacementNamed(context, '/cob');
    } else if (index == 1) {
      Navigator.pushReplacementNamed(context, '/history');
    }
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: widget.currentIndex,
      onTap: (index) => _onItemTapped(context, index),
      selectedItemColor: Colors.blue[700],
      unselectedItemColor: Colors.grey,
      showUnselectedLabels: true,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.history),
          label: 'History',
        ),
      ],
    );
  }
}