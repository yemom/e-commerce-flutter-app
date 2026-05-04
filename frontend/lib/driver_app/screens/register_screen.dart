import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _vehicle = TextEditingController();
  final _license = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _password.dispose();
    _vehicle.dispose();
    _license.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final messenger = ScaffoldMessenger.of(context);
    if (_name.text.trim().isEmpty ||
        _phone.text.trim().isEmpty ||
        _password.text.trim().length < 6) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Name, phone, and a password of at least 6 characters are required.',
          ),
        ),
      );
      return;
    }

    try {
      await ref
          .read(authControllerProvider.notifier)
          .register(
            name: _name.text.trim(),
            phone: _phone.text.trim(),
            password: _password.text.trim(),
            email: _email.text.trim(),
            phoneNumber: _phone.text.trim(),
            vehicleType: _vehicle.text.trim(),
            licenseNumber: _license.text.trim(),
          );
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
      }
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Register failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Driver Register')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Full name'),
            ),
            TextField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Phone'),
            ),
            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email (optional)'),
            ),
            TextField(
              controller: _password,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            TextField(
              controller: _vehicle,
              decoration: const InputDecoration(labelText: 'Vehicle type'),
            ),
            TextField(
              controller: _license,
              decoration: const InputDecoration(labelText: 'License number'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: isLoading ? null : _register,
              child: isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Register'),
            ),
          ],
        ),
      ),
    );
  }
}
