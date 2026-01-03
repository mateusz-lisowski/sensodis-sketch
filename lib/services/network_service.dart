import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sensodis_sketch/widgets/success_snackbar.dart';
import 'package:sensodis_sketch/widgets/warning_snackbar.dart';

class NetworkService extends GetxService {
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;

  @override
  void onInit() {
    super.onInit();
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
  }

  void _updateConnectionStatus(List<ConnectivityResult> result) {
    if (result.contains(ConnectivityResult.none)) {
      showWarningSnackbar('No Internet Connection', 'Please check your internet connection');
    } else {
      if (Get.isSnackbarOpen) {
        Get.closeCurrentSnackbar();
      }
      showSuccessSnackbar('Internet Connection Restored', 'You are back online');
    }
  }

  @override
  void onClose() {
    _connectivitySubscription.cancel();
    super.onClose();
  }
}
