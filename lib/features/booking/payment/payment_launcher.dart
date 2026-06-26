import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/booking_models.dart';

/// Launches the device payment sheet (Razorpay) and reports whether payment completed (captured).
abstract interface class PaymentLauncher {
  Future<bool> launch(PaymentInitiation payment);
}

/// Default launcher: the native Razorpay SDK is not wired into this build (it needs a device build
/// + live keys). Returns false so checkout falls back to the "reserved — payment pending" path.
/// Swap this for a RazorpayPaymentLauncher when building for a device.
class UnsupportedPaymentLauncher implements PaymentLauncher {
  const UnsupportedPaymentLauncher();

  @override
  Future<bool> launch(PaymentInitiation payment) async => false;
}

final paymentLauncherProvider =
    Provider<PaymentLauncher>((ref) => const UnsupportedPaymentLauncher());
