import 'package:flutter/material.dart';
import 'Widgets/appointment_card.dart';

class Test extends StatelessWidget {
  const Test({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("data"),),
      body: SafeArea(child: ListView(
        children: [
          AppointmentCard(
            tutorName: "M. EYAT ALLAH MOLK ALARAB",
            subject: "Mathématiques",
            duration: "30 min",
            date: "SAM 14 Juin",
            time: "14:30 - 15:00",
            scolor: const Color.fromARGB(255, 226, 44, 31),
            state: "rejected",
            onTap: () => print("Card clicked"),
          ),
          
          AppointmentCard(
            tutorName: "M. EYAT ALLAH MOLK ALARAB",
            subject: "Mathématiques",
            duration: "30 min",
            date: "SAM 14 Juin",
            time: "14:30 - 15:00",
            scolor: Colors.green,
            state: "accpted",
            onTap: () => print("Card clicked"),
          ),
        ],
      ))
      
    );
  }
}