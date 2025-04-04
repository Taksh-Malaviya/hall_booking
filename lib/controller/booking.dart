import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:table_calendar/table_calendar.dart';

class BookingController extends GetxController {
  var startDate = Rxn<DateTime>();
  var endDate = Rxn<DateTime>();
  var selectedDay = Rxn<DateTime>();
  var focusedDay = DateTime.now().obs;
  var calendarFormat = CalendarFormat.month.obs;

  void selectDate(DateTime selected) {
    if (startDate.value == null ||
        (startDate.value != null && endDate.value != null)) {
      startDate.value = selected;
      endDate.value = null;
    } else {
      endDate.value =
          selected.isAfter(startDate.value!) ? selected : startDate.value;
    }
    selectedDay.value = selected;
  }

  void changeFormat(CalendarFormat format) {
    calendarFormat.value = format;
  }

  void changeFocusedDay(DateTime day) {
    focusedDay.value = day;
  }
}
