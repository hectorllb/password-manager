import 'package:flutter/material.dart';
import '../models/password_item.dart';
import '../services/password_service.dart';

class AddEditPasswordScreen extends StatefulWidget {
  final PasswordItem? passwordItem;

  const AddEditPasswordScreen({
    Key? key,
    this.passwordItem,
  }) : super(key: key);

  @override
  State<AddEditPasswordScreen> createState() => _AddEditPasswordScreenState();
}

class _AddEditPasswordScreenState extends State<AddEditPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _websiteController = TextEditingController();
  final _notesController = TextEditingController();
  
  final PasswordService _passwordService = PasswordService();
  
  String _category = 'General';
  bool _obscurePassword = true;
  bool _isLoading = false;
  int _passwordStrength = 0;
  
  final List<String> _categories = [
    'General',
    'Social',
    'Work',
    'Finance',
    'Shopping',
    'Entertainment',
    'Travel',
    'Education',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    
    if (widget.passwordItem != null) {
      _titleController.text = widget.passwordItem!.title;
      _usernameController.text = widget.passwordItem!.username;
      _passwordController.text = widget.passwordItem!.password;
      _websiteController.text = widget.passwordItem!.website;
      _notesController.text = widget.passwordItem!.notes;
      _category = widget.passwordItem!.category;
    }
    
    _passwordController.addListener(_updatePasswordStrength);
    _updatePasswordStrength();
  }

  void _updatePasswordStrength() {
    setState(() {
      _passwordStrength = _passwordService.checkPasswordStrength(_passwordController.text);
    });
  }

  String _getPasswordStrengthText() {
    switch (_passwordStrength) {
      case 0:
        return 'Enter a password';
      case 1:
        return 'Weak';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Strong';
      default:
        return '';
    }
  }

  Color _getPasswordStrengthColor() {
    switch (_passwordStrength) {
      case 1:
        return Colors.red;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.yellow;
      case 4:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Future<void> _generatePassword() async {
    final password = _passwordService.generatePassword(
      length: 16,
      includeUppercase: true,
      includeLowercase: true,
      includeNumbers: true,
      includeSpecial: true,
    );
    
    setState(() {
      _passwordController.text = password;
    });
  }

  Future<void> _savePassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final PasswordItem passwordItem = widget.passwordItem != null
          ? widget.passwordItem!.copyWith(
              title: _titleController.text,
              username: _usernameController.text,
              password: _passwordController.text,
              website: _websiteController.text,
              notes: _notesController.text,
              category: _category,
            )
          : PasswordItem(
              title: _titleController.text,
              username: _usernameController.text,
              password: _passwordController.text,
              website: _websiteController.text,
              notes: _notesController.text,
              category: _category,
            );

      if (widget.passwordItem != null) {
        await _passwordService.updateItem(passwordItem);
      } else {
        await _passwordService.addItem(passwordItem);
      }

      if (!mounted) return;
      
      Navigator.of(context).pop(true);
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save password')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.passwordItem != null;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Password' : 'Add Password'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                prefixIcon: Icon(Icons.title),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a title';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'Username / Email',
                prefixIcon: Icon(Icons.person),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a username or email';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.key),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: _generatePassword,
                      tooltip: 'Generate password',
                    ),
                  ],
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a password';
                }
                return null;
              },
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: _passwordStrength / 4,
              backgroundColor: Colors.grey[300],
              color: _getPasswordStrengthColor(),
            ),
            const SizedBox(height: 4),
            Text(
              'Password strength: ${_getPasswordStrengthText()}',
              style: TextStyle(
                color: _getPasswordStrengthColor(),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _websiteController,
              decoration: const InputDecoration(
                labelText: 'Website (optional)',
                prefixIcon: Icon(Icons.web),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _category,
              decoration: const InputDecoration(
                labelText: 'Category',
                prefixIcon: Icon(Icons.category),
              ),
              items: _categories.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _category = value;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                prefixIcon: Icon(Icons.note),
                alignLabelWithHint: true,
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isLoading ? null : _savePassword,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                      isEditing ? 'Update Password' : 'Save Password',
                      style: const TextStyle(fontSize: 16),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _websiteController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}
