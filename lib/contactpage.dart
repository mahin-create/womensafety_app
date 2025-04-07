import 'package:flutter/material.dart';
import 'package:telephony/telephony.dart';

class DirectSmsScreen extends StatefulWidget {
  @override
  _DirectSmsScreenState createState() => _DirectSmsScreenState();
}

class _DirectSmsScreenState extends State<DirectSmsScreen> {
  final Telephony telephony = Telephony.instance;
  final TextEditingController phoneController = TextEditingController();
  List<String> numbers=[];

  void sendSMS() async {
    String phoneNumber = phoneController.text.trim(); // Trim spaces
    if (phoneNumber.isEmpty) {
      print("Phone number is empty.");
      return;
    }

    String message = "I am in Trouble please help me";

    bool? permissionsGranted = await telephony.requestSmsPermissions;

    if (permissionsGranted ?? false) {
      try {
        telephony.sendSms(to: phoneNumber, message: message);
        print("SMS sent successfully to $phoneNumber");
      } catch (e) {
        print("Failed to send SMS: $e");
      }
    } else {
      print("SMS permission denied.");
    }
    
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(title: Text("Add Phone Number")),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: phoneController,
                      decoration: InputDecoration(
                        hintText: "Enter Phone Number",
                        border: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.black, width: 2),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.black, width: 2),
                        ),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                  ),
              SizedBox(width: 5),
              ElevatedButton(onPressed: (){
                setState(() {
                  sendSMS();
                  numbers.add(phoneController.text);
                  phoneController.clear();
                });
              }, child: Text("Send SMS")),
                ],
              ),
              SizedBox(height: 10,),
              Flexible(child: ListView.builder(
                itemCount: numbers.length,
                itemBuilder: (context,index){
                  return Container(
                    padding: EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        Expanded(child: Text(numbers[index])),
                        IconButton(
                          onPressed:(){
                            setState(() {
                          numbers.removeAt(index);
                        }); 
                          } ,
                        icon: Icon(Icons.delete),
                        color: Colors.red,
                        ),
                      ],
                    ),
                  );
                },
                ),),
            ],
          ),
        ),
      ),
    );
  }
}
