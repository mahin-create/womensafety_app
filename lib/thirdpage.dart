import 'package:flutter/material.dart';
import 'package:women_safety_app/fourthpage.dart';

class Thirdpage extends StatefulWidget {
  const Thirdpage({super.key});

  @override
  State<Thirdpage> createState() => _ThirdpageState();
}

class _ThirdpageState extends State<Thirdpage> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Column(
          children: [
            Center(
              child: Text(
                'Emergency Alert',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w300,
                  color: Color(0xFF575757),
                ),
              ),
            ),
            Spacer(),
            Image(image: AssetImage('assects/alert.jpg')),
            Spacer(flex: 2),
            Container(
              height: 250,
              width: MediaQuery.of(context).size.width,
              decoration: BoxDecoration(
                color: Color(0xFFCBE957),
                borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(30.0),
                child: Column(
                  children: [
                    SizedBox(height: 5),
                    Text(
                      'Emergency alert can send the alert message to the person who was selected by you and then also to nearest potorl and police station',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF030F0F),
                      ),
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF134B42),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => Fourthpage()),
                        );
                      },
                      child: Text(
                        'Next Page',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFCA763A),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
