import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

class AppToast {
  
  static void showSuccess(String message) {
    debugPrint("Showing success toast: $message");
    toastification.show(
      type: ToastificationType.success,
      style: ToastificationStyle.flatColored,
      autoCloseDuration: const Duration(seconds: 3),
      title: Text(
        message,
        style: const TextStyle(color: Colors.black),
      ),
      alignment: Alignment.topCenter,
      primaryColor: Colors.green,
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
    );
  }

  
  static void showError(String message) {
    debugPrint("Showing error toast: $message");
    toastification.show(
      title: Text(
        message,
        style: const TextStyle(color: Colors.black),
      ),
      style: ToastificationStyle.flatColored,
      type: ToastificationType.error,
      alignment: Alignment.topCenter,
      showProgressBar: false,
      backgroundColor: Colors.red,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      borderRadius: BorderRadius.circular(12),
      autoCloseDuration: const Duration(seconds: 3),
    );
  }
  static void showInfo(String message) {
    debugPrint("Showing info toast: $message");
    toastification.show(
      type: ToastificationType.info,
      style: ToastificationStyle.flatColored,
      title: Text(
        message,
        style: const TextStyle(color: Colors.black),
      ),
      alignment: Alignment.topCenter,
      backgroundColor: Colors.blue.shade50,
      primaryColor: Colors.blue,
      foregroundColor: Colors.black,
      borderRadius: BorderRadius.circular(12),
      autoCloseDuration: const Duration(seconds: 3),
    );
  }
}
