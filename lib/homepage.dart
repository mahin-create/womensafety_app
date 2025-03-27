import 'package:flutter/material.dart';
import 'package:women_safety_app/contactpage.dart';
import 'package:women_safety_app/mappage.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  int currentpage = 0;
  List<Widget> pages = [Mappage(), DirectSmsScreen()];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:IndexedStack(
        index: currentpage,
        children: pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Map'),
          BottomNavigationBarItem(icon: Icon(Icons.contact_page), label: 'sms'),
        ],
        currentIndex: currentpage,
        selectedItemColor: Colors.blue,
        onTap: (Value) {
          setState(() {
            currentpage = Value;
          });
        },
      ),
    );
  }
}
