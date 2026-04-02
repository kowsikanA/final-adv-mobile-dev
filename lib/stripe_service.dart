import 'dart:convert';

import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;

class StripeService {
  // Android emulator -> 10.0.2.2
  // iOS simulator/macOS -> localhost
  static const String _androidBaseUrl = 'http://10.0.2.2:3000';
  static const String _iosBaseUrl = 'http://localhost:3000';

  static String get _baseUrl {
    if (Uri.base.host.contains('localhost')) {
      return _iosBaseUrl;
    }
    return _androidBaseUrl;
  }

  static Future<String> createPaymentIntent({
    required double amount,
    required String title,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/create-payment-intent'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'amount': (amount * 100).round(),
        'currency': 'cad',
        'title': title,
      }),
    );

    final body = jsonDecode(response.body);

    if (response.statusCode != 200) {
      throw Exception(body['error'] ?? 'Failed to create payment intent');
    }

    final clientSecret = body['clientSecret'];
    if (clientSecret == null || clientSecret is! String) {
      throw Exception('Missing client secret');
    }

    return clientSecret;
  }

  static Future<void> pay({
    required double amount,
    required String title,
  }) async {
    final clientSecret = await createPaymentIntent(
      amount: amount,
      title: title,
    );

    await Stripe.instance.initPaymentSheet(
      paymentSheetParameters: SetupPaymentSheetParameters(
        paymentIntentClientSecret: clientSecret,
        merchantDisplayName: 'Group Project Expenses',
      ),
    );

    await Stripe.instance.presentPaymentSheet();
  }
}