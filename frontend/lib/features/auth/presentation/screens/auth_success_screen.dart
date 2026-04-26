/// Simple confirmation screen shown after a successful auth step.
library;
import 'package:flutter/material.dart';

/// Screen for Auth Success.
class AuthSuccessScreen extends StatelessWidget {
  const AuthSuccessScreen({
    super.key,
    required this.onContinue,
    this.fullName,
  });

  final VoidCallback onContinue;
  final String? fullName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // Three-stop gradient: strong color on top and clean content area below.
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF5E56E7), Color(0xFF756DF2), Color(0xFFF7F8FC)],
            stops: [0, .35, .35],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              // Main confirmation card.
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Positive visual cue for successful completion.
                    const CircleAvatar(
                      radius: 42,
                      backgroundColor: Color(0xFFE7FFF1),
                      child: Icon(Icons.check_circle_rounded, color: Color(0xFF1FB56C), size: 42),
                    ),
                    const SizedBox(height: 18),
                    Text('Account Created Successfully', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    Text(
                      fullName == null || fullName!.trim().isEmpty
                          ? 'Your account is ready. Continue to start shopping.'
                          : '${fullName!.trim()}, your account is ready. Continue to start shopping.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(onPressed: onContinue, child: const Text('Continue to Home')),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
