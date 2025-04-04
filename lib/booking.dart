import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:hall_2/controller/clear_data.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'dart:math';
import 'package:firebase_core/firebase_core.dart';

import 'controller/booking.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
  );
  runApp(const MyApp());
}

final _Formkey = GlobalKey<FormState>();

final BookingController bookingController = Get.put(BookingController());
final ClearData clearData = Get.put(ClearData());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Hall Booking',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const BookingScreen(),
    );
  }
}

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  _BookingScreenState createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  DateTime? _startDate;
  DateTime? _endDate;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();

  Future<bool> _isDateAvailable(DateTime start, DateTime end) async {
    QuerySnapshot bookings =
        await _firestore
            .collection('bookings')
            .where('startDate', isLessThan: end.toIso8601String())
            .get();

    for (var doc in bookings.docs) {
      DateTime bookedStart = DateTime.parse(doc['startDate']);
      DateTime bookedEnd = DateTime.parse(doc['endDate']);

      if (!(end.isBefore(bookedStart) || start.isAfter(bookedEnd))) {
        return false;
      }
    }
    return true;
  }

  String _generateRandomCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    Random random = Random();
    return List.generate(
      6,
      (index) => chars[random.nextInt(chars.length)],
    ).join();
  }

  double _calculateRent(DateTime startDate, DateTime endDate) {
    int daysBetween = startDate.difference(DateTime.now()).inDays;
    int totalDays = endDate.difference(startDate).inDays + 1;

    double baseRentPerDay = 5000;
    double finalRentPerDay = baseRentPerDay;

    if (daysBetween <= 7) {
      finalRentPerDay *= 1.2;
    } else if (daysBetween >= 30) {
      finalRentPerDay *= 0.85;
    }

    return finalRentPerDay * totalDays;
  }

  void _bookHall() async {
    if (_startDate == null ||
        _endDate == null ||
        _nameController.text.isEmpty ||
        _contactController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all fields and select dates.'),
        ),
      );
      return;
    }

    bool available = await _isDateAvailable(_startDate!, _endDate!);
    if (!available) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selected dates are already booked ❌')),
      );
      return;
    }

    double finalRent = _calculateRent(_startDate!, _endDate!);
    String bookingCode = _generateRandomCode();

    try {
      await _firestore.collection('bookings').add({
        'startDate': _startDate!.toIso8601String(),
        'endDate': _endDate!.toIso8601String(),
        'bookingCode': bookingCode,
        'name': _nameController.text,
        'contact': _contactController.text,
        'finalRent': finalRent,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Booking confirmed ✅ Total Rent: ₹$finalRent')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error saving booking: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(title: const Text('Hall Booking')),
      body: Column(
        children: [
          Obx(() {
            return TableCalendar(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2101, 12, 31),
              focusedDay: bookingController.focusedDay.value,
              calendarFormat: bookingController.calendarFormat.value,
              selectedDayPredicate:
                  (day) => isSameDay(bookingController.selectedDay.value, day),

              onDaySelected: (selectedDay, focusedDay) {
                bookingController.selectDate(selectedDay);
                bookingController.focusedDay.value = focusedDay;
              },

              onFormatChanged: (format) {
                bookingController.changeFormat(format);
              },

              onPageChanged: (focusedDay) {
                bookingController.focusedDay.value = focusedDay;
              },

              rangeStartDay: bookingController.startDate.value,
              rangeEndDay: bookingController.endDate.value,

              calendarStyle: CalendarStyle(
                rangeHighlightColor: Colors.blueAccent.withOpacity(0.5),
                selectedDecoration: BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
                todayDecoration: BoxDecoration(
                  color: Colors.orange,
                  shape: BoxShape.circle,
                ),
              ),
            );
          }),

          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _Formkey,
              child: Column(
                children: [
                  Row(
                    children: [
                      Text(
                        bookingController.startDate.value != null
                            ? "Start Date: ${DateFormat('dd/MM/yyyy').format(bookingController.startDate.value!)}"
                            : "Start Date: Not Selected",
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Text(
                        bookingController.startDate.value != null
                            ? "End Date: ${DateFormat('dd/MM/yyyy').format(bookingController.endDate.value!)}"
                            : "Start Date: Not Selected",
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 20),
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Full Name',
                      labelStyle: TextStyle(color: Colors.blue, fontSize: 16),
                      prefixIcon: Icon(Icons.person, color: Colors.blue),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.blue),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.blue, width: 2),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 16,
                      ),
                    ),
                    validator: (value) {
                      return (value == null || value.isEmpty)
                          ? "Enter Name"
                          : null;
                    },
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _contactController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'Contact No.',
                      labelStyle: TextStyle(color: Colors.blue, fontSize: 16),
                      prefixIcon: Icon(Icons.phone, color: Colors.blue),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.blue, width: 2),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 16,
                      ),
                    ),
                    validator: (value) {
                      return (value == null || value.isEmpty)
                          ? "Enter Contact No."
                          : null;
                    },
                  ),

                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                    ),
                    onPressed: () {
                      _bookHall();
                      _Formkey.currentState!.validate();
                      clearData.clearInputs();
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.event_available,
                          color: Colors.white,
                        ), // Icon
                        const SizedBox(width: 8), // Spacing
                        const Text(
                          'Book Hall',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
