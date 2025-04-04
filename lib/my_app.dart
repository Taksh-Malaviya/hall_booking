import 'package:flutter/material.dart';

import 'booking.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Hall Booking',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: BookingScreen(),
    );
  }
}
