import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';
import '../services/password_service.dart';
import 'auth_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final PasswordService _passwordService = PasswordService();
  final AuthService _authService = AuthService();
  
  bool _biometricsAvailable = false;
  bool _useBiometrics = false;
  bool _autoLock = true;
  int _autoLockTime = 1; // minutes
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    _checkBiometrics();
    _loadSettings();
  }

  Future<void> _checkBiometrics() async {
    final available = await _authService.isBiometricAvailable();
    setState(() {
      _biometricsAvailable = available;
    });
  }

  Future<void> _loadSettings() async {
    final prefs = await const FlutterSecureStorage().readAll();
    setState(() {
      _useBiometrics = prefs['use_biometrics'] == 'true';
      _autoLock = prefs['auto_lock'] != 'false';
      _autoLockTime = int.tryParse(prefs['auto_lock_time'] ?? '1') ?? 1;
    });
  }

  Future<void> _saveSettings() async {
    final storage = const FlutterSecureStorage();
    await storage.write(key: 'use_biometrics', value: _useBiometrics.toString());
    await storage.write(key: 'auto_lock', value: _autoLock.toString());
    await storage.write(key: 'auto_lock_time', value: _autoLockTime.toString());
  }

  Future<void> _exportPasswords() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final jsonData = await _passwordService.exportPasswords();
      await Clipboard.setData(ClipboardData(text: jsonData));
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords exported to clipboard')),
      );
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to export passwords')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _importPasswords() async {
    final TextEditingController controller = TextEditingController();
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import Passwords'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Paste JSON data here',
          ),
          maxLines: 5,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Import'),
          ),
        ],
      ),
    );
    
    if (result == null || result.isEmpty) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final success = await _passwordService.importPasswords(result);
      
      if (!mounted) return;
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Passwords imported successfully')),
        );
        Navigator.of(context).pop(true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to import passwords: Invalid format')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to import passwords')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _changeMasterPassword() async {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Master Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Current Password',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: newPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'New Password',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: confirmPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirm New Password',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (newPasswordController.text != confirmPasswordController.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('New passwords do not match')),
                );
                return;
              }
              
              Navigator.of(context).pop({
                'current': currentPasswordController.text,
                'new': newPasswordController.text,
              });
            },
            child: const Text('Change'),
          ),
        ],
      ),
    );
    
    if (result == null) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final isValid = await _passwordService.verifyMasterPassword(result['current']!);
      
      if (!isValid) {
        if (!mounted) return;
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Current password is incorrect')),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }
      
      await _passwordService.initializeMasterPassword(result['new']!);
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Master password changed successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to change master password')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
    
    if (confirmed != true) return;
    
    await _saveSettings();
    
    if (!mounted) return;
    
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const AuthScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                ListTile(
                  title: const Text('Security'),
                  subtitle: const Text('Authentication and locking options'),
                  leading: const Icon(Icons.security),
                ),
                SwitchListTile(
                  title: const Text('Use Biometric Authentication'),
                  subtitle: const Text('Unlock with Face ID or Touch ID'),
                  value: _biometricsAvailable && _useBiometrics,
                  onChanged: _biometricsAvailable
                      ? (value) {
                          setState(() {
                            _useBiometrics = value;
                          });
                          _saveSettings();
                        }
                      : null,
                ),
                SwitchListTile(
                  title: const Text('Auto-Lock'),
                  subtitle: const Text('Lock app when in background'),
                  value: _autoLock,
                  onChanged: (value) {
                    setState(() {
                      _autoLock = value;
                    });
                    _saveSettings();
                  },
                ),
                ListTile(
                  title: const Text('Auto-Lock Timeout'),
                  subtitle: Text('$_autoLockTime ${_autoLockTime == 1 ? 'minute' : 'minutes'}'),
                  enabled: _autoLock,
                  trailing: DropdownButton<int>(
                    value: _autoLockTime,
                    onChanged: _autoLock
                        ? (value) {
                            if (value != null) {
                              setState(() {
                                _autoLockTime = value;
                              });
                              _saveSettings();
                            }
                          }
                        : null,
                    items: const [
                      DropdownMenuItem(value: 1, child: Text('1 minute')),
                      DropdownMenuItem(value: 5, child: Text('5 minutes')),
                      DropdownMenuItem(value: 15, child: Text('15 minutes')),
                      DropdownMenuItem(value: 30, child: Text('30 minutes')),
                    ],
                  ),
                ),
                ListTile(
                  title: const Text('Change Master Password'),
                  leading: const Icon(Icons.password),
                  onTap: _changeMasterPassword,
                ),
                const Divider(),
                ListTile(
                  title: const Text('Data Management'),
                  subtitle: const Text('Import and export options'),
                  leading: const Icon(Icons.data_usage),
                ),
                ListTile(
                  title: const Text('Export Passwords'),
                  subtitle: const Text('Copy encrypted data to clipboard'),
                  leading: const Icon(Icons.upload),
                  onTap: _exportPasswords,
                ),
                ListTile(
                  title: const Text('Import Passwords'),
                  subtitle: const Text('Import from JSON data'),
                  leading: const Icon(Icons.download),
                  onTap: _importPasswords,
                ),
                const Divider(),
                ListTile(
                  title: const Text('Logout'),
                  leading: const Icon(Icons.logout, color: Colors.red),
                  textColor: Colors.red,
                  onTap: _logout,
                ),
                const SizedBox(height: 24),
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Secure Vault v1.0.0',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
