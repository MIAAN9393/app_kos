import 'package:flutter/material.dart';
import 'package:kos_management/features/auth/widget/custom_appsnackbar.dart';

mixin ProviderFeedback<T extends StatefulWidget> on State<T> {
  void listenProviderErrors({
    required String? Function() readError,
    required String? Function() readSuccess,
  }) {
    final err = readError();
    if (err != null && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) AppSnackbar.error(context, err);
      });
    }
    final ok = readSuccess();
    if (ok != null && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) AppSnackbar.success(context, ok);
      });
    }
  }
}
