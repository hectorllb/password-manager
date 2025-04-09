import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/password_item.dart';
import 'add_edit_password_screen.dart';

class PasswordDetailScreen extends StatefulWidget {
  final PasswordItem passwordItem;

  const PasswordDetailScreen({
    Key? key,
    required this.passwordItem,
  }) : super(key: key);

  @override
  State<PasswordDetailScreen> createState() => _PasswordDetailScreenState();
}

class _PasswordDetailScreenState extends State<PasswordDetailScreen> {
  bool _showPassword = false;

  Future<void> _copyToClipboard(String text, String label) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label copied to clipboard')),
    );
  }

  String _getObscuredPassword() {
    return '•' * widget.passwordItem.password.length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Password Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final result = await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => AddEditPasswordScreen(
                    passwordItem: widget.passwordItem,
                  ),
                ),
              );
              
              if (result == true) {
                Navigator.of(context).pop(true);
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                          radius: 24,
                          child: Text(
                            widget.passwordItem.title.isNotEmpty
                                ? widget.passwordItem.title[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.passwordItem.title,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (widget.passwordItem.website.isNotEmpty)
                                Text(
                                  widget.passwordItem.website,
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'ACCOUNT DETAILS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              margin: EdgeInsets.zero,
              child: Column(
                children: [
                  ListTile(
                    title: const Text('Username'),
                    subtitle: Text(widget.passwordItem.username),
                    trailing: IconButton(
                      icon: const Icon(Icons.copy),
                      onPressed: () => _copyToClipboard(
                        widget.passwordItem.username,
                        'Username',
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    title: const Text('Password'),
                    subtitle: Text(
                      _showPassword
                          ? widget.passwordItem.password
                          : _getObscuredPassword(),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            _showPassword ? Icons.visibility_off : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              _showPassword = !_showPassword;
                            });
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy),
                          onPressed: () => _copyToClipboard(
                            widget.passwordItem.password,
                            'Password',
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (widget.passwordItem.website.isNotEmpty) ...[
                    const Divider(height: 1),
                    ListTile(
                      title: const Text('Website'),
                      subtitle: Text(widget.passwordItem.website),
                      trailing: IconButton(
                        icon: const Icon(Icons.open_in_new),
                        onPressed: () {
                          // Open website (would use url_launcher in a real app)
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (widget.passwordItem.notes.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'NOTES',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(widget.passwordItem.notes),
                ),
              ),
            ],
            const SizedBox(height: 16),
            const Text(
              'METADATA',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              margin: EdgeInsets.zero,
              child: Column(
                children: [
                  ListTile(
                    title: const Text('Category'),
                    subtitle: Text(widget.passwordItem.category),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    title: const Text('Created'),
                    subtitle: Text(
                      '${widget.passwordItem.createdAt.day}/${widget.passwordItem.createdAt.month}/${widget.passwordItem.createdAt.year}',
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    title: const Text('Last Modified'),
                    subtitle: Text(
                      '${widget.passwordItem.updatedAt.day}/${widget.passwordItem.updatedAt.month}/${widget.passwordItem.updatedAt.year}',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
