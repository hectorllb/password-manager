import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/password_item.dart';
import '../services/password_service.dart';
import 'add_edit_password_screen.dart';
import 'password_detail_screen.dart';
import 'settings_screen.dart';
import 'password_generator_screen.dart';
import '../widgets/password_list_item.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PasswordService _passwordService = PasswordService();
  List<PasswordItem> _passwordItems = [];
  List<PasswordItem> _filteredItems = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedCategory = 'All';
  
  @override
  void initState() {
    super.initState();
    _loadPasswords();
  }

  Future<void> _loadPasswords() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final items = await _passwordService.getAllItems();
      setState(() {
        _passwordItems = items;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _passwordItems = [];
        _filteredItems = [];
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredItems = _passwordItems.where((item) {
        // Apply category filter
        if (_selectedCategory != 'All' && item.category != _selectedCategory) {
          return false;
        }
        
        // Apply search filter
        if (_searchQuery.isNotEmpty) {
          final query = _searchQuery.toLowerCase();
          return item.title.toLowerCase().contains(query) ||
              item.username.toLowerCase().contains(query) ||
              item.website.toLowerCase().contains(query);
        }
        
        return true;
      }).toList();
    });
  }

  List<String> _getCategories() {
    final Set<String> categories = {'All'};
    for (final item in _passwordItems) {
      categories.add(item.category);
    }
    return categories.toList()..sort();
  }

  Future<void> _navigateToAddEditScreen({PasswordItem? item}) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddEditPasswordScreen(passwordItem: item),
      ),
    );

    if (result == true) {
      _loadPasswords();
    }
  }

  Future<void> _navigateToDetailScreen(PasswordItem item) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PasswordDetailScreen(passwordItem: item),
      ),
    );

    if (result == true) {
      _loadPasswords();
    }
  }

  Future<void> _deletePassword(PasswordItem item) async {
    try {
      await _passwordService.deleteItem(item.id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password deleted')),
      );
      _loadPasswords();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete password')),
      );
    }
  }

  Future<void> _copyToClipboard(String text, String label) async {
    await Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label copied to clipboard')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Secure Vault'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () async {
              final result = await Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
              if (result == true) {
                _loadPasswords();
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search passwords...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8.0)),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                  _applyFilters();
                });
              },
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: _getCategories().map((category) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    label: Text(category),
                    selected: _selectedCategory == category,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = selected ? category : 'All';
                        _applyFilters();
                      });
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredItems.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.lock_outline,
                              size: 64,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _passwordItems.isEmpty
                                  ? 'No passwords saved yet'
                                  : 'No matching passwords found',
                              style: const TextStyle(
                                fontSize: 18,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filteredItems.length,
                        itemBuilder: (context, index) {
                          final item = _filteredItems[index];
                          return PasswordListItem(
                            passwordItem: item,
                            onTap: () => _navigateToDetailScreen(item),
                            onEdit: () => _navigateToAddEditScreen(item: item),
                            onDelete: () => _deletePassword(item),
                            onCopyUsername: () => _copyToClipboard(item.username, 'Username'),
                            onCopyPassword: () => _copyToClipboard(item.password, 'Password'),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'generate',
            mini: true,
            onPressed: () async {
              final result = await Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const PasswordGeneratorScreen()),
              );
              
              if (result != null && result is String) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Password generated and copied to clipboard')),
                );
              }
            },
            child: const Icon(Icons.vpn_key),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            heroTag: 'add',
            onPressed: () => _navigateToAddEditScreen(),
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}
