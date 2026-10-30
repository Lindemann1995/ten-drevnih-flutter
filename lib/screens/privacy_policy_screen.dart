import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Ссылка на политику (прод-версия)
    const url = 'https://api.code-nest.ru/privacy/';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        title: const Text(
          'ПОЛИТИКА КОНФИДЕНЦИАЛЬНОСТИ',
          style: TextStyle(
            color: Color(0xFFD4AF37),
            fontSize: 14,
            letterSpacing: 1,
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFFD4AF37)),
      ),
      // Убрали const перед InAppWebView и URLRequest
      body: InAppWebView(
        initialUrlRequest: URLRequest(url: WebUri(url)),
      ),
    );
  }
}