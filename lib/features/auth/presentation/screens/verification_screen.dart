/// Handles the code verification step after signup or login.
library;
import 'package:flutter/material.dart';

class VerificationScreen extends StatefulWidget {
  const VerificationScreen({
    super.key,
    required this.identifier,
    required this.onVerifyCode,
    required this.onResend,
    required this.onBack,
    this.title = 'Email Verification',
    this.description,
  });

  final String identifier;
  final Future<bool> Function(String code) onVerifyCode;
  final Future<void> Function() onResend;
  final VoidCallback onBack;
  final String title;
  final String? description;

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  // Holds the one-time code entered by the user.
  final _codeController = TextEditingController();
  // True while verify request is in progress.
  bool _isSubmitting = false;
  // True while resend request is in progress.
  bool _isResending = false;
  // Inline status feedback shown under the code box.
  String? _message;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // Branded header background.
            Container(
              height: 220,
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [Color(0xFF5E56E7), Color(0xFF756DF2)]),
              ),
            ),
            // Content is scrollable for smaller devices.
            ListView(
              padding: const EdgeInsets.fromLTRB(22, 28, 22, 24),
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: widget.onBack,
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  widget.title,
                  style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.description ??
                      'A 4-digit verification code has been sent to ${widget.identifier}. Enter the code below to continue.',
                  style: const TextStyle(color: Color(0xFFDCDDFF)),
                ),
                const SizedBox(height: 26),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 78,
                        height: 78,
                        decoration: BoxDecoration(
                          color: const Color(0xFFECEBFF),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: const Icon(Icons.mark_email_read_outlined, color: Color(0xFF5E56E7), size: 34),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Enter the 4-digit code from your email.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _codeController,
                        keyboardType: TextInputType.number,
                        maxLength: 4,
                        textAlign: TextAlign.center,
                        decoration: const InputDecoration(
                          hintText: '1234',
                          prefixIcon: Icon(Icons.pin_outlined),
                          counterText: '',
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_message != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            _message!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Color(0xFF5E56E7)),
                          ),
                        ),
                      ElevatedButton(
                        onPressed: _isSubmitting
                            ? null
                            : () async {
                                setState(() => _isSubmitting = true);
                                final code = _codeController.text.trim();
                                // Validate a simple 4-digit format before calling backend.
                                final ok = code.length == 4
                                    ? await widget.onVerifyCode(code)
                                    : false;
                                if (!mounted) return;
                                setState(() {
                                  _isSubmitting = false;
                                  _message = ok
                                      ? 'Your code is verified. You can continue now.'
                                      : 'That code is not valid. Please check your email and try again.';
                                });
                              },
                        child: Text(_isSubmitting ? 'Checking...' : 'Verify Code'),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton(
                        onPressed: _isResending
                            ? null
                            : () async {
                                setState(() => _isResending = true);
                                await widget.onResend();
                                if (!mounted) return;
                                setState(() {
                                  _isResending = false;
                                  _message = 'A new verification code has been sent to your email.';
                                });
                              },
                        child: Text(_isResending ? 'Sending...' : 'Resend Email'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}