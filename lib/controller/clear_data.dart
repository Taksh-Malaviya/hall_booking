import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ClearData extends GetxController {
  // Controllers for text fields
  final TextEditingController nameController = TextEditingController();
  final TextEditingController contactController = TextEditingController();

  // Reactive variables for selected dates
  var startDate = Rxn<DateTime>();
  var endDate = Rxn<DateTime>();

  // Method to clear all inputs
  void clearInputs() {
    nameController.clear();
    contactController.clear();
    startDate.value = null;
    endDate.value = null;
  }

  @override
  void onClose() {
    nameController.dispose();
    contactController.dispose();
    super.onClose();
  }
}
