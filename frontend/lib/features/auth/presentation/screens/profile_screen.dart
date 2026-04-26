/// Displays the current user's profile details and account actions.
library;
import 'package:flutter/material.dart';

import 'package:e_commerce_app_with_django/features/auth/domain/models/user_role.dart';

/// Screen for Profile.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    required this.userName,
    required this.email,
    required this.role,
    required this.branchName,
    required this.onLogout,
  });

  final String userName;
  final String email;
  final AppUserRole role;
  final String branchName;
  final Future<void> Function() onLogout;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Supported UI languages shown in bottom sheet.
  static const List<String> _languages = [
    'English',
    'Amharic',
    'Afan Oromo',
    'Tigrinya',
    'Somali',
    'Arabic',
    'French',
  ];

  String _selectedLanguage = 'English';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        // Settings are grouped to help users find actions quickly.
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          const _SettingsSectionTitle('General'),
          _SettingsTile(
            icon: Icons.person_outline_rounded,
            title: 'Edit Profile',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => _EditProfileScreen(
                    userName: widget.userName,
                    email: widget.email,
                    branchName: widget.branchName,
                    role: widget.role,
                  ),
                ),
              );
            },
          ),
          _SettingsTile(
            icon: Icons.lock_outline_rounded,
            title: 'Change Password',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const _ChangePasswordScreen(),
                ),
              );
            },
          ),
          _SettingsTile(
            icon: Icons.notifications_none_rounded,
            title: 'Notifications',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notification controls are now active.')),
              );
            },
          ),
          _SettingsTile(
            icon: Icons.security_outlined,
            title: 'Security',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const _SecurityScreen(),
                ),
              );
            },
          ),
          _SettingsTile(
            icon: Icons.language_rounded,
            title: 'Language',
            trailingText: _selectedLanguage,
            onTap: _showLanguagePicker,
          ),
          const SizedBox(height: 18),
          const _SettingsSectionTitle('Preferences'),
          _SettingsTile(
            icon: Icons.tune_rounded,
            title: 'App Preferences',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const _PreferencesScreen(),
                ),
              );
            },
          ),
          _SettingsTile(
            icon: Icons.policy_outlined,
            title: 'Legal and Policies',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const _LegalPoliciesScreen(),
                ),
              );
            },
          ),
          _SettingsTile(
            icon: Icons.help_outline_rounded,
            title: 'Help & Support',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const _HelpSupportScreen(),
                ),
              );
            },
          ),
          _SettingsTile(
            icon: Icons.logout_rounded,
            title: 'Logout',
            isDanger: true,
            onTap: widget.onLogout,
          ),
        ],
      ),
    );
  }

  Future<void> _showLanguagePicker() async {
    // Show all available languages and return selected value.
    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const ListTile(
              title: Text('Choose Language', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
            ..._languages.map(
              (language) => RadioListTile<String>(
                value: language,
                groupValue: _selectedLanguage,
                title: Text(language),
                onChanged: (value) => Navigator.of(context).pop(value),
              ),
            ),
          ],
        ),
      ),
    );

    if (selected != null && mounted) {
      setState(() => _selectedLanguage = selected);
      // Give quick feedback so user knows preference changed.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Language changed to $selected.')),
      );
    }
  }
}

class _EditProfileScreen extends StatelessWidget {
  const _EditProfileScreen({
    required this.userName,
    required this.email,
    required this.branchName,
    required this.role,
  });

  final String userName;
  final String email;
  final String branchName;
  final AppUserRole role;

  @override
  Widget build(BuildContext context) {
    final userNameController = TextEditingController(text: userName);
    final emailController = TextEditingController(text: email);

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 48,
              backgroundColor: Color(0xFFE4E8F2),
              child: Icon(Icons.person_rounded, size: 52, color: Color(0xFF6A7186)),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: userNameController,
              decoration: const InputDecoration(
                labelText: 'Username',
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.mail_outline_rounded),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              enabled: false,
              controller: TextEditingController(text: branchName),
              decoration: const InputDecoration(
                labelText: 'Branch',
                prefixIcon: Icon(Icons.storefront_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              enabled: false,
              controller: TextEditingController(text: role.value),
              decoration: const InputDecoration(
                labelText: 'Role',
                prefixIcon: Icon(Icons.badge_outlined),
              ),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(54)),
              child: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChangePasswordScreen extends StatefulWidget {
  const _ChangePasswordScreen();

  @override
  State<_ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<_ChangePasswordScreen> {
  // Toggle for showing/hiding password text in both fields.
  bool _hidePassword = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Change Password')),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
        child: Column(
          children: [
            TextField(
              obscureText: _hidePassword,
              decoration: InputDecoration(
                labelText: 'New Password',
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                suffixIcon: IconButton(
                  onPressed: () => setState(() => _hidePassword = !_hidePassword),
                  icon: Icon(_hidePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              obscureText: _hidePassword,
              decoration: InputDecoration(
                labelText: 'Confirm Password',
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                suffixIcon: IconButton(
                  onPressed: () => setState(() => _hidePassword = !_hidePassword),
                  icon: Icon(_hidePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                ),
              ),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(54)),
              child: const Text('Change Now'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SecurityScreen extends StatefulWidget {
  const _SecurityScreen();

  @override
  State<_SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<_SecurityScreen> {
  // Local toggle values for demo security settings.
  bool _biometricEnabled = true;
  bool _twoFactorEnabled = false;
  bool _loginAlertEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Security')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        children: [
          SwitchListTile(
            value: _biometricEnabled,
            title: const Text('Biometric Login'),
            subtitle: const Text('Use fingerprint or face unlock for sign in.'),
            onChanged: (value) => setState(() => _biometricEnabled = value),
          ),
          SwitchListTile(
            value: _twoFactorEnabled,
            title: const Text('Two-Factor Authentication'),
            subtitle: const Text('Require a second step when logging in.'),
            onChanged: (value) => setState(() => _twoFactorEnabled = value),
          ),
          SwitchListTile(
            value: _loginAlertEnabled,
            title: const Text('Login Alerts'),
            subtitle: const Text('Notify me when a new device signs in.'),
            onChanged: (value) => setState(() => _loginAlertEnabled = value),
          ),
        ],
      ),
    );
  }
}

class _PreferencesScreen extends StatefulWidget {
  const _PreferencesScreen();

  @override
  State<_PreferencesScreen> createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends State<_PreferencesScreen> {
  // Local app preference toggles for user experience options.
  bool _saveHistory = true;
  bool _personalizedOffers = true;
  bool _compactProductCards = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('App Preferences')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        children: [
          SwitchListTile(
            value: _saveHistory,
            title: const Text('Save Search History'),
            onChanged: (value) => setState(() => _saveHistory = value),
          ),
          SwitchListTile(
            value: _personalizedOffers,
            title: const Text('Personalized Offers'),
            onChanged: (value) => setState(() => _personalizedOffers = value),
          ),
          SwitchListTile(
            value: _compactProductCards,
            title: const Text('Compact Product Cards'),
            onChanged: (value) => setState(() => _compactProductCards = value),
          ),
        ],
      ),
    );
  }
}

class _LegalPoliciesScreen extends StatelessWidget {
  const _LegalPoliciesScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Legal and Policies')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        children: const [
          ListTile(
            leading: Icon(Icons.description_outlined),
            title: Text('Terms of Service'),
            subtitle: Text('Rules and responsibilities for using the app.'),
          ),
          ListTile(
            leading: Icon(Icons.privacy_tip_outlined),
            title: Text('Privacy Policy'),
            subtitle: Text('How we collect and process your data.'),
          ),
          ListTile(
            leading: Icon(Icons.gavel_outlined),
            title: Text('Consumer Protection'),
            subtitle: Text('Your rights and dispute process details.'),
          ),
        ],
      ),
    );
  }
}

class _HelpSupportScreen extends StatelessWidget {
  const _HelpSupportScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Help & Support')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        children: const [
          ListTile(
            leading: Icon(Icons.chat_bubble_outline_rounded),
            title: Text('Live Chat'),
            subtitle: Text('Chat with our support team.'),
          ),
          ListTile(
            leading: Icon(Icons.mail_outline_rounded),
            title: Text('Email Support'),
            subtitle: Text('support@kutuku.app'),
          ),
          ListTile(
            leading: Icon(Icons.phone_in_talk_outlined),
            title: Text('Phone Support'),
            subtitle: Text('+251 911 000 000'),
          ),
          ListTile(
            leading: Icon(Icons.quiz_outlined),
            title: Text('FAQ'),
            subtitle: Text('Find answers to common questions.'),
          ),
        ],
      ),
    );
  }
}

class _SettingsSectionTitle extends StatelessWidget {
  const _SettingsSectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Text(title, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    this.trailingText,
    this.onTap,
    this.isDanger = false,
  });

  final IconData icon;
  final String title;
  final String? trailingText;
  final VoidCallback? onTap;
  final bool isDanger;

  @override
  Widget build(BuildContext context) {
    // Use danger color for destructive actions like logout.
    final color = isDanger ? const Color(0xFFE64A4A) : const Color(0xFF23263B);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8EBF2)),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: color),
        title: Text(
          title,
          style: TextStyle(fontWeight: FontWeight.w600, color: color),
        ),
        trailing: trailingText == null
            ? const Icon(Icons.chevron_right_rounded)
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(trailingText!, style: const TextStyle(color: Color(0xFFA1A7B8))),
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right_rounded),
                ],
              ),
      ),
    );
  }
}
