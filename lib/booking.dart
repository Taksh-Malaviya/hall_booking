import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:math';

final _formKey = GlobalKey<FormState>();

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
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
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

  double _calculateRent(DateTime startDate, DateTime endDate, bool isFullDay) {
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

    bool isFullDay =
        _startDate!.isAtSameMomentAs(_endDate!)
            ? await _showHalfFullDayDialog()
            : true;
    double finalRent = _calculateRent(_startDate!, _endDate!, isFullDay);
    String bookingCode = _generateRandomCode();

    try {
      await _firestore.collection('bookings').add({
        'startDate': _startDate!.toIso8601String(),
        'endDate': _endDate!.toIso8601String(),
        'bookingCode': bookingCode,
        'name': _nameController.text,
        'contact': _contactController.text,
        'finalRent': finalRent,
        'isFullDay': isFullDay,
      });

      String bookingDetails =
          "📅 Hall Booking Confirmation\n"
          "👤 Name: ${_nameController.text}\n"
          "📞 Contact: ${_contactController.text}\n"
          "🗓️ Start Date: ${DateFormat('dd/MM/yyyy').format(_startDate!)}\n"
          "🗓️ End Date: ${DateFormat('dd/MM/yyyy').format(_endDate!)}\n"
          "🔖 Booking Code: $bookingCode\n"
          "💰 Total Rent: ₹$finalRent\n"
          "📌 Booking Type: ${isFullDay ? 'Full Day' : 'Half Day'}\n"
          "✅ Your hall booking is confirmed!";

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Booking confirmed ✅ Total Rent: ₹$finalRent')),
      );

      Share.share(bookingDetails);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error saving booking: $e')));
    }
  }

  Future<bool> _showHalfFullDayDialog() async {
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Choose Booking Type'),
              content: const Text(
                'Do you want to book for a full day or half day?',
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Half Day'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Full Day'),
                ),
              ],
            );
          },
        ) ??
        true; // Default to full day if no selection is made
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Hall Booking',
          style: TextStyle(fontSize: 20, color: Colors.white),
        ),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
        elevation: 4,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: TableCalendar(
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2101, 12, 31),
                  focusedDay: _focusedDay,
                  calendarFormat: _calendarFormat,
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = selectedDay;
                      if (_startDate == null ||
                          (_startDate != null && _endDate != null)) {
                        _startDate = selectedDay;
                        _endDate = null;
                      } else {
                        _endDate =
                            selectedDay.isAfter(_startDate!)
                                ? selectedDay
                                : _startDate;
                      }
                    });
                  },
                  rangeStartDay: _startDate,
                  rangeEndDay: _endDate,
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
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "Selected Dates",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blueAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  Text(
                    _startDate != null
                        ? "Start Date: ${DateFormat('dd/MM/yyyy').format(_startDate!)}"
                        : "Start Date: Not Selected",
                    style: const TextStyle(fontSize: 16, color: Colors.blue),
                  ),
                  Text(
                    _endDate != null
                        ? "End Date: ${DateFormat('dd/MM/yyyy').format(_endDate!)}"
                        : "End Date: Not Selected",
                    style: const TextStyle(fontSize: 16, color: Colors.blue),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameController,
                    keyboardType: TextInputType.name,
                    decoration: InputDecoration(
                      labelText: 'Full Name',
                      prefixIcon: Icon(Icons.person, color: Colors.blue),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    validator:
                        (value) =>
                            value == null || value.isEmpty
                                ? "Enter Name"
                                : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    maxLength: 10,
                    controller: _contactController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'Contact No.',
                      prefixIcon: Icon(Icons.phone, color: Colors.blue),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    validator:
                        (value) =>
                            value == null || value.isEmpty
                                ? "Enter Contact No."
                                : null,
                  ),
                  const SizedBox(height: 20),
                  Visibility(
                    visible: _startDate == _endDate,
                    child: ElevatedButton(
                      onPressed: () {
                        _showHalfFullDayDialog();
                      },
                      child: Text("Choose Day Type"),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _bookHall,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        'Book Hall',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
