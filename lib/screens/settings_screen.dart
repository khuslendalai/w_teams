import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_screen.dart';
import 'account_info_screen.dart';

class SettingsScreen extends StatefulWidget {
  final String email;

  const SettingsScreen({super.key, required this.email});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const appColor = Color.fromARGB(255, 1, 4, 104);

  bool _isLoading = false;
  User? _currentUser;

  String _teamName = 'No Team';
  String _role = 'No Role';
  String _firstName = '';
  String _lastName = '';
  String _nickname = '';
  String _phoneNumber = '';
  String _accountId = '';

  @override
  void initState() {
    super.initState();
    _loadUser();
    _loadFirestoreUserData();
  }

  void _loadUser() {
    setState(() {
      _currentUser = FirebaseAuth.instance.currentUser;
    });
  }

  Future<void> _loadFirestoreUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final data = doc.data();
        var teamName = data?['teamName']?.toString();
        final role = data?['role']?.toString() ?? 'No Role';
        final firstNameValue = data?['firstName']?.toString() ?? '';
        final lastNameValue = data?['lastName']?.toString() ?? '';
        final nicknameValue = data?['nickname']?.toString() ?? '';
        final phoneNumberValue = data?['phoneNumber']?.toString() ??
            FirebaseAuth.instance.currentUser?.phoneNumber ?? '';
        final accountIdValue = FirebaseAuth.instance.currentUser?.uid ?? '';

        if ((teamName == null || teamName.isEmpty) && data?['teamId'] != null) {
          final teamDoc = await FirebaseFirestore.instance
              .collection('teams')
              .doc(data?['teamId'])
              .get();
          if (teamDoc.exists) {
            teamName = teamDoc.data()?['name']?.toString();
          }
        }

        setState(() {
          _teamName = teamName?.isNotEmpty == true ? teamName! : 'No Team';
          _role = role;
          _firstName = firstNameValue;
          _lastName = lastNameValue;
          _nickname = nicknameValue;
          _phoneNumber = phoneNumberValue;
          _accountId = accountIdValue;
        });
      }
    } catch (e) {
      debugPrint('Failed to load Firestore user data: $e');
    }
  }


  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? Colors.redAccent : appColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _showChangePasswordDialog(BuildContext context) async {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    bool obscureCurrent = true;
    bool obscureNew = true;
    bool obscureConfirm = true;
    bool isSubmitting = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> submit() async {
              final user = FirebaseAuth.instance.currentUser;
              final email = user?.email;
              final currentPassword = currentPasswordController.text.trim();
              final newPassword = newPasswordController.text.trim();
              final confirmPassword = confirmPasswordController.text.trim();

              if (user == null || email == null) {
                _showSnack('No logged-in user found', isError: true);
                return;
              }
              if (currentPassword.isEmpty ||
                  newPassword.isEmpty ||
                  confirmPassword.isEmpty) {
                _showSnack('Please fill in all fields', isError: true);
                return;
              }
              if (newPassword.length < 6) {
                _showSnack('New password must be at least 6 characters',
                    isError: true);
                return;
              }
              if (newPassword != confirmPassword) {
                _showSnack('New passwords do not match', isError: true);
                return;
              }

              setDialogState(() => isSubmitting = true);
              try {
                final credential = EmailAuthProvider.credential(
                  email: email,
                  password: currentPassword,
                );
                await user.reauthenticateWithCredential(credential);
                await user.updatePassword(newPassword);

                if (!mounted) return;
                Navigator.pop(context);
                _showSnack('Password updated successfully!');
              } on FirebaseAuthException catch (e) {
                String message = 'Failed to update password';
                if (e.code == 'wrong-password' ||
                    e.code == 'invalid-credential') {
                  message = 'Current password is incorrect';
                } else if (e.code == 'weak-password') {
                  message = 'New password is too weak';
                } else if (e.code == 'requires-recent-login') {
                  message = 'Please log in again and try';
                }
                _showSnack(message, isError: true);
              } catch (e) {
                _showSnack('Error: $e', isError: true);
              } finally {
                if (context.mounted) {
                  setDialogState(() => isSubmitting = false);
                }
              }
            }

            Widget passwordField({
              required TextEditingController controller,
              required String label,
              required bool obscure,
              required VoidCallback toggleObscure,
            }) {
              return TextField(
                controller: controller,
                obscureText: obscure,
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  labelText: label,
                  labelStyle: const TextStyle(fontSize: 13),
                  prefixIcon: const Icon(Icons.lock_outline,
                      color: appColor, size: 20),
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscure ? Icons.visibility_off : Icons.visibility,
                      size: 20,
                      color: Colors.grey,
                    ),
                    onPressed: toggleObscure,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: appColor, width: 1.8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      vertical: 14, horizontal: 12),
                ),
              );
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title: const Row(
                children: [
                  Icon(Icons.lock_outline, color: appColor),
                  SizedBox(width: 8),
                  Text(
                    'Change Password',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: appColor,
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    passwordField(
                      controller: currentPasswordController,
                      label: 'Current Password',
                      obscure: obscureCurrent,
                      toggleObscure: () => setDialogState(
                          () => obscureCurrent = !obscureCurrent),
                    ),
                    const SizedBox(height: 12),
                    passwordField(
                      controller: newPasswordController,
                      label: 'New Password',
                      obscure: obscureNew,
                      toggleObscure: () =>
                          setDialogState(() => obscureNew = !obscureNew),
                    ),
                    const SizedBox(height: 12),
                    passwordField(
                      controller: confirmPasswordController,
                      label: 'Confirm New Password',
                      obscure: obscureConfirm,
                      toggleObscure: () => setDialogState(
                          () => obscureConfirm = !obscureConfirm),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed:
                      isSubmitting ? null : () => Navigator.pop(context),
                  child: const Text('Cancel',
                      style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: isSubmitting ? null : submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: appColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: isSubmitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Update'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.info_outline, color: appColor),
              SizedBox(width: 8),
              Text(
                'About W Teams',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: appColor,
                ),
              ),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Icon(Icons.music_note, size: 60, color: appColor)),
              SizedBox(height: 12),
              Center(
                child: Text(
                  'W Teams',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: appColor),
                ),
              ),
              Center(
                child: Text('Version 1.0.0',
                    style: TextStyle(fontSize: 12, color: Colors.grey)),
              ),
              SizedBox(height: 16),
              Text(
                'W Teams is a worship team management app designed to help team members stay organized, view schedules, manage songs, and coordinate with their team.',
                style: TextStyle(fontSize: 13, color: Colors.black54),
              ),
              SizedBox(height: 12),
              Text(
                'Developed for Mobile Programming Course.',
                style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontStyle: FontStyle.italic),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: appColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.logout, color: Colors.redAccent),
              SizedBox(width: 8),
              Text(
                'Logout',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.redAccent),
              ),
            ],
          ),
          content: const Text(
            'Are you sure you want to logout from W Teams?',
            style: TextStyle(fontSize: 14, color: Colors.black54),
          ),
          actions: [
            TextButton(
              onPressed: _isLoading ? null : () => Navigator.pop(context),
              child: const Text('Cancel',
                  style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: _isLoading
                  ? null
                  : () async {
                      Navigator.pop(context);
                      setState(() => _isLoading = true);
                      try {
                        await FirebaseAuth.instance.signOut();
                        if (!mounted) return;
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const LoginScreen()),
                          (_) => false,
                        );
                      } catch (e) {
                        if (!mounted) return;
                        _showSnack('Logout failed: $e', isError: true);
                      } finally {
                        if (mounted) setState(() => _isLoading = false);
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _currentUser;
    final displayEmail = user?.email ?? widget.email;
    final initialUsername = displayEmail.split('@')[0];
    final nameParts = initialUsername.split('.');
    final initials = nameParts.length >= 2
        ? '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase()
        : initialUsername.isNotEmpty
            ? initialUsername[0].toUpperCase()
            : 'U';
    final uid = user?.uid ?? 'No UID';
    final displayName = (_firstName.isNotEmpty || _lastName.isNotEmpty)
        ? '$_firstName ${_lastName}'.trim()
        : initialUsername;

    return Stack(
      children: [
        SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Navy Header ──────────────────────────────────────────────
              Container(
                width: double.infinity,
                color: appColor,
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 28),
                child: Column(
                  children: [
                    // Avatar with colored ring
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 2.5,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 38,
                        backgroundColor: Colors.white.withOpacity(0.15),
                        child: Text(
                          initials,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      displayName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      displayEmail,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 14),
                    // Role + Team inline badges
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _HeaderBadge(
                            icon: Icons.music_note_outlined, label: _role),
                        const SizedBox(width: 8),
                        _HeaderBadge(
                            icon: Icons.groups_outlined, label: _teamName),
                      ],
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Account ──────────────────────────────────────────
                    const _SectionLabel(label: 'ACCOUNT'),
                    _SettingsTile(
                      icon: Icons.person_outline,
                      label: 'Account Info',
                      subtitle: 'View detailed account profile',
                      onTap: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AccountInfoScreen(
                              firstName: _firstName,
                              lastName: _lastName,
                              nickname: _nickname,
                              email: displayEmail,
                              phoneNumber: _phoneNumber,
                              accountId: _accountId,
                            ),
                          ),
                        );
                        if (result is Map<String, String>) {
                          setState(() {
                            _firstName = result['firstName'] ?? _firstName;
                            _lastName = result['lastName'] ?? _lastName;
                            _nickname = result['nickname'] ?? _nickname;
                            _phoneNumber = result['phoneNumber'] ?? _phoneNumber;
                          });
                          _showSnack('Account info updated successfully');
                        }
                      },
                    ),
                    _SettingsTile(
                      icon: Icons.email_outlined,
                      label: 'Email',
                      subtitle: displayEmail,
                      onTap: () {},
                    ),
                    _SettingsTile(
                      icon: Icons.groups_outlined,
                      label: 'Team Name',
                      subtitle: _teamName,
                      onTap: () {},
                    ),
                    _SettingsTile(
                      icon: Icons.music_note_outlined,
                      label: 'Role',
                      subtitle: _role,
                      onTap: () {},
                    ),
                    _SettingsTile(
                      icon: Icons.lock_outline,
                      label: 'Change Password',
                      subtitle: 'Update your account password',
                      onTap: () => _showChangePasswordDialog(context),
                    ),
                    const SizedBox(height: 20),

                    // ── Account Details ───────────────────────────────────
                    const _SectionLabel(label: 'ACCOUNT DETAILS'),
                    _SettingsTile(
                      icon: Icons.badge_outlined,
                      label: 'User ID',
                      subtitle: uid,
                      onTap: () {},
                    ),
                    const SizedBox(height: 20),

                    // ── About ─────────────────────────────────────────────
                    const _SectionLabel(label: 'ABOUT'),
                    _SettingsTile(
                      icon: Icons.info_outline,
                      label: 'About W Teams',
                      subtitle: 'Version 1.0.0',
                      onTap: () => _showAboutDialog(context),
                    ),
                    const SizedBox(height: 24),

                    // ── Logout ────────────────────────────────────────────
                    InkWell(
                      onTap: _isLoading
                          ? null
                          : () => _showLogoutDialog(context),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: Colors.redAccent.withOpacity(0.4)),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.logout,
                                color: Colors.redAccent, size: 20),
                            SizedBox(width: 10),
                            Text(
                              'Logout',
                              style: TextStyle(
                                color: Colors.redAccent,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ],
          ),
        ),

        // ── Global loading overlay ───────────────────────────────────────
        if (_isLoading)
          Container(
            color: Colors.black.withOpacity(0.12),
            child: const Center(
              child: CircularProgressIndicator(color: appColor),
            ),
          ),
      ],
    );
  }
}

// ── Reusable Widgets ──────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          color: Color.fromARGB(255, 1, 4, 104),
        ),
      ),
    );
  }
}

class _HeaderBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  const _HeaderBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.white.withOpacity(0.85)),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.9),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;
  final Color? subtitleColor;

  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
    this.subtitleColor,
  });

  @override
  Widget build(BuildContext context) {
    const appColor = Color.fromARGB(255, 1, 4, 104);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F2FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: appColor, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: subtitleColor ?? Colors.grey,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

