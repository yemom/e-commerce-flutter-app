// lib/driver_app/screens/edit_profile_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:e_commerce_app_with_django/features/auth/presentation/providers/auth_provider.dart' as app_auth;

import '../providers/auth_provider.dart';
import '../providers/profile_provider.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _vehicleTypeController = TextEditingController();
  final _licenseNumberController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isSaving = false;
  bool _changePassword = false;
  bool _profileLoaded = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _vehicleTypeController.dispose();
    _licenseNumberController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _populateFields(DriverProfile profile) {
    if (_profileLoaded) return;
    _nameController.text = profile.name;
    _phoneController.text = profile.phone;
    _emailController.text = profile.email;
    _vehicleTypeController.text = profile.vehicleType;
    _licenseNumberController.text = profile.licenseNumber;
    _profileLoaded = true;
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isSaving) return;

    if (_changePassword) {
      if (_newPasswordController.text != _confirmPasswordController.text) {
        _showSnack('New passwords do not match.', isError: true);
        return;
      }
      if (_newPasswordController.text.length < 6) {
        _showSnack('Password must be at least 6 characters.', isError: true);
        return;
      }
    }

    setState(() => _isSaving = true);
    try {
      await ref
          .read(driverProfileProvider.notifier)
          .updateProfile(
            name: _nameController.text.trim(),
            phone: _phoneController.text.trim(),
            email: _emailController.text.trim(),
            vehicleType: _vehicleTypeController.text.trim(),
            licenseNumber: _licenseNumberController.text.trim(),
            currentPassword: _changePassword
                ? _currentPasswordController.text
                : null,
            newPassword: _changePassword ? _newPasswordController.text : null,
          );

      if (mounted) {
        _showSnack('Profile updated successfully.');
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        _showSnack('Failed to update profile: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? Colors.red.shade700
            : const Color(0xFF5E56E7),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(driverProfileProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F8),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text('Could not load profile: $e'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(driverProfileProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (profile) {
          _populateFields(profile);
          return CustomScrollView(
            slivers: [
              // ── App Bar ──────────────────────────────────────────────────
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                backgroundColor: const Color(0xFF5E56E7),
                foregroundColor: Colors.white,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF5E56E7), Color(0xFF9C8FFF)],
                      ),
                    ),
                    child: SafeArea(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 40),
                          Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              CircleAvatar(
                                radius: 46,
                                backgroundColor: Colors.white.withValues(alpha: 0.2),
                                child: Text(
                                  profile.name.isNotEmpty
                                      ? profile.name[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.edit,
                                  size: 14,
                                  color: Color(0xFF5E56E7),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            profile.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            profile.currentStatus,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.75),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                title: const Text(
                  'Edit Profile',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),

              // ── Form ─────────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Personal Info card
                        _SectionCard(
                          title: 'Personal Information',
                          icon: Icons.person_outline_rounded,
                          children: [
                            _Field(
                              controller: _nameController,
                              label: 'Full Name',
                              icon: Icons.badge_outlined,
                              validator: (v) => v == null || v.trim().isEmpty
                                  ? 'Name is required'
                                  : null,
                            ),
                            _Field(
                              controller: _phoneController,
                              label: 'Phone',
                              icon: Icons.phone_outlined,
                              keyboardType: TextInputType.phone,
                              validator: (v) => v == null || v.trim().isEmpty
                                  ? 'Phone is required'
                                  : null,
                            ),
                            _Field(
                              controller: _emailController,
                              label: 'Email',
                              icon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return null;
                                }
                                if (!v.contains('@')) {
                                  return 'Enter a valid email';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Vehicle Info card
                        _SectionCard(
                          title: 'Vehicle Information',
                          icon: Icons.local_shipping_outlined,
                          children: [
                            _Field(
                              controller: _vehicleTypeController,
                              label: 'Vehicle Type',
                              icon: Icons.directions_car_outlined,
                            ),
                            _Field(
                              controller: _licenseNumberController,
                              label: 'License Number',
                              icon: Icons.credit_card_outlined,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Change Password toggle card
                        _SectionCard(
                          title: 'Security',
                          icon: Icons.lock_outline_rounded,
                          trailing: Switch(
                            value: _changePassword,
                            activeThumbColor: const Color(0xFF5E56E7),
                            onChanged: (v) =>
                                setState(() => _changePassword = v),
                          ),
                          children: _changePassword
                              ? [
                                  _PasswordField(
                                    controller: _currentPasswordController,
                                    label: 'Current Password',
                                    obscure: _obscureCurrent,
                                    onToggle: () => setState(
                                      () => _obscureCurrent = !_obscureCurrent,
                                    ),
                                    validator: (v) => v == null || v.isEmpty
                                        ? 'Enter current password'
                                        : null,
                                  ),
                                  _PasswordField(
                                    controller: _newPasswordController,
                                    label: 'New Password',
                                    obscure: _obscureNew,
                                    onToggle: () => setState(
                                      () => _obscureNew = !_obscureNew,
                                    ),
                                    validator: (v) => v == null || v.length < 6
                                        ? 'Min 6 characters'
                                        : null,
                                  ),
                                  _PasswordField(
                                    controller: _confirmPasswordController,
                                    label: 'Confirm New Password',
                                    obscure: _obscureConfirm,
                                    onToggle: () => setState(
                                      () => _obscureConfirm = !_obscureConfirm,
                                    ),
                                    validator: (v) =>
                                        v != _newPasswordController.text
                                        ? 'Passwords do not match'
                                        : null,
                                  ),
                                ]
                              : [
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      left: 4,
                                      bottom: 8,
                                    ),
                                    child: Text(
                                      'Toggle to change your password',
                                      style: TextStyle(
                                        color: Colors.grey.shade500,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                        ),
                        const SizedBox(height: 28),

                        // Save button
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton.icon(
                            onPressed: _isSaving ? null : _handleSave,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF5E56E7),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            icon: _isSaving
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.check_rounded),
                            label: Text(
                              _isSaving ? 'Saving...' : 'Save Changes',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Logout button
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: OutlinedButton.icon(
                            onPressed: _isSaving
                                ? null
                                : () async {
                                    await ref
                                        .read(authControllerProvider.notifier)
                                        .logout();
                                    await ref
                                        .read(app_auth.authProvider.notifier)
                                        .logout();
                                  },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red.shade600,
                              side: BorderSide(color: Colors.red.shade300),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            icon: const Icon(Icons.logout_rounded),
                            label: const Text(
                              'Log Out',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── Reusable section card ────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
    this.trailing,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE7ECF3)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: const Color(0xFF5E56E7)),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF23263B),
                ),
              ),
              if (trailing != null) ...[const Spacer(), trailing!],
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

// ── Reusable text field ──────────────────────────────────────────────────────

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 20, color: const Color(0xFF9AA1B2)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE7ECF3)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE7ECF3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF5E56E7), width: 1.5),
          ),
          filled: true,
          fillColor: const Color(0xFFF8F9FC),
        ),
      ),
    );
  }
}

// ── Reusable password field ──────────────────────────────────────────────────

class _PasswordField extends StatelessWidget {
  const _PasswordField({
    required this.controller,
    required this.label,
    required this.obscure,
    required this.onToggle,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final bool obscure;
  final VoidCallback onToggle;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(
            Icons.lock_outline,
            size: 20,
            color: Color(0xFF9AA1B2),
          ),
          suffixIcon: IconButton(
            icon: Icon(
              obscure
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              size: 20,
              color: const Color(0xFF9AA1B2),
            ),
            onPressed: onToggle,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE7ECF3)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE7ECF3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF5E56E7), width: 1.5),
          ),
          filled: true,
          fillColor: const Color(0xFFF8F9FC),
        ),
      ),
    );
  }
}
