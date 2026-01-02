import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/grocery_item.dart';
import '../models/store.dart';
import '../services/storage_service.dart';
import '../services/user_service.dart';
import '../services/auth_service.dart';
import '../services/sync_service.dart';
import '../services/firestore_service.dart';
import 'household_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Store? _currentStore;
  String _currentUser = 'Me';
  final SyncService _syncService = SyncService();
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _currentStore = StorageService.getDefaultStore();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
      // Get display name from Firebase Auth, not local storage
      final firebaseUser = _authService.currentUser;
  
      if (firebaseUser != null && firebaseUser.displayName != null && firebaseUser.displayName!.isNotEmpty) {
        setState(() {
        _currentUser = firebaseUser.displayName!;
        });
        // Update local storage to match
        await UserService.setUserName(firebaseUser.displayName!);
      } else {
        // Fallback to local storage
        final userName = await UserService.getUserName();
        setState(() {
          _currentUser = userName;
        });
      }
  
      final hasName = await UserService.hasUserName();
      if (!hasName && firebaseUser != null) {
       WidgetsBinding.instance.addPostFrameCallback((_) {
          _showSetUserNameDialog();
        });
      }
  }

  void _showSetUserNameDialog() {
    final TextEditingController controller = TextEditingController(text: _currentUser);
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Welcome!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('What should we call you?'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Your Name',
                hintText: 'e.g., Mom, Dad, Sarah',
              ),
              autofocus: true,
              textCapitalization: TextCapitalization.words,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                UserService.setUserName(controller.text.trim());
                setState(() {
                  _currentUser = controller.text.trim();
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Color get _currentColor {
    return _currentStore != null 
        ? Color(_currentStore!.colorValue)
        : Colors.green;
  }

  void _addItem({
    required String name,
    int quantity = 1,
    String? category,
    String? aisle,
  }) {
    final item = GroceryItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      quantity: quantity,
      category: category,
      aisle: aisle,
      createdAt: DateTime.now(),
      storeId: _currentStore?.id,
      addedBy: _currentUser,
      addedAt: DateTime.now(),
    );
    
    _syncService.addItem(item);
  }

  void _toggleItem(GroceryItem item, int index) {
    final updatedItem = item.copyWith(
      isChecked: !item.isChecked,
      checkedAt: !item.isChecked ? DateTime.now() : null,
    );
    
    _syncService.updateItem(index, updatedItem);
  }

  void _deleteItem(int index, String itemId) {
    _syncService.deleteItem(index, itemId);
  }

  void _showAddItemDialog() {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController quantityController = TextEditingController(text: '1');
    final TextEditingController aisleController = TextEditingController();
    final TextEditingController categoryController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Item'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Item Name *',
                  hintText: 'e.g., Milk',
                ),
                autofocus: true,
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: quantityController,
                decoration: const InputDecoration(
                  labelText: 'Quantity',
                  hintText: '1',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: aisleController,
                decoration: const InputDecoration(
                  labelText: 'Aisle Number (optional)',
                  hintText: 'e.g., 5',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: categoryController,
                decoration: const InputDecoration(
                  labelText: 'Category (optional)',
                  hintText: 'e.g., Dairy',
                ),
                textCapitalization: TextCapitalization.words,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (nameController.text.trim().isNotEmpty) {
                _addItem(
                  name: nameController.text.trim(),
                  quantity: int.tryParse(quantityController.text) ?? 1,
                  aisle: aisleController.text.trim().isEmpty 
                      ? null 
                      : aisleController.text.trim(),
                  category: categoryController.text.trim().isEmpty 
                      ? null 
                      : categoryController.text.trim(),
                );
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showStoreSelector() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Store'),
        content: StreamBuilder<List<Store>>(
          stream: _syncService.getStoresStream(),
          builder: (context, snapshot) {
            final stores = snapshot.data ?? StorageService.getStores();
            
            if (stores.isEmpty) {
              return const Text('No stores available');
            }

            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: stores.map((store) {
                  final isSelected = _currentStore?.id == store.id;
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Color(store.colorValue),
                      radius: 12,
                    ),
                    title: Text(store.name),
                    subtitle: store.isDefault ? const Text('Default') : null,
                    trailing: Icon(
                      isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                      color: isSelected ? Theme.of(context).colorScheme.primary : null,
                    ),
                    onTap: () {
                      setState(() {
                        _currentStore = store;
                      });
                      Navigator.pop(context);
                    },
                    onLongPress: () {
                      Navigator.pop(context);
                      final storeIndex = stores.indexOf(store);
                      _showEditStoreDialog(store, storeIndex);
                    },
                  );
                }).toList(),
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showAddStoreDialog();
            },
            child: const Text('Add Store'),
          ),
        ],
      ),
    );
  }

  void _showAddStoreDialog() {
    final TextEditingController controller = TextEditingController();
    Color selectedColor = Colors.blue;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Add Store'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: controller,
                  decoration: const InputDecoration(
                    labelText: 'Store Name',
                    hintText: 'e.g., Walmart, Publix',
                  ),
                  autofocus: true,
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 20),
                const Text('Choose Color:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Colors.red,
                    Colors.pink,
                    Colors.purple,
                    Colors.deepPurple,
                    Colors.indigo,
                    Colors.blue,
                    Colors.lightBlue,
                    Colors.cyan,
                    Colors.teal,
                    Colors.green,
                    Colors.lightGreen,
                    Colors.lime,
                    Colors.yellow,
                    Colors.amber,
                    Colors.orange,
                    Colors.deepOrange,
                  ].map((color) {
                    return GestureDetector(
                      onTap: () {
                        setDialogState(() {
                          selectedColor = color;
                        });
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: selectedColor == color 
                                ? Colors.black 
                                : Colors.transparent,
                            width: 3,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  if (controller.text.trim().isNotEmpty) {
                    final store = Store(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      name: controller.text.trim(),
                      createdAt: DateTime.now(),
                      colorValue: selectedColor.toARGB32(),
                      notes: '',
                    );
                    
                    _syncService.addStore(store);
                    Navigator.pop(context);
                  }
                },
                child: const Text('Add'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showEditStoreDialog(Store store, int index) {
    final TextEditingController controller = TextEditingController(text: store.name);
    Color selectedColor = Color(store.colorValue);
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Edit Store'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: controller,
                  decoration: const InputDecoration(
                    labelText: 'Store Name',
                  ),
                  autofocus: true,
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 20),
                const Text('Choose Color:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Colors.red,
                    Colors.pink,
                    Colors.purple,
                    Colors.deepPurple,
                    Colors.indigo,
                    Colors.blue,
                    Colors.lightBlue,
                    Colors.cyan,
                    Colors.teal,
                    Colors.green,
                    Colors.lightGreen,
                    Colors.lime,
                    Colors.yellow,
                    Colors.amber,
                    Colors.orange,
                    Colors.deepOrange,
                  ].map((color) {
                    return GestureDetector(
                      onTap: () {
                        setDialogState(() {
                          selectedColor = color;
                        });
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: selectedColor == color 
                                ? Colors.black 
                                : Colors.transparent,
                            width: 3,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
            actions: [
              if (!store.isDefault)
                TextButton(
                  onPressed: () {
                    _syncService.deleteStore(index, store.id);
                    if (_currentStore?.id == store.id) {
                      setState(() {
                        _currentStore = StorageService.getDefaultStore();
                      });
                    }
                    Navigator.pop(context);
                  },
                  child: const Text('Delete', style: TextStyle(color: Colors.red)),
                ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  if (controller.text.trim().isNotEmpty) {
                    final updatedStore = store.copyWith(
                      name: controller.text.trim(),
                      colorValue: selectedColor.toARGB32(),
                    );
                    
                    _syncService.updateStore(index, updatedStore);
                    if (_currentStore?.id == store.id) {
                      setState(() {
                        _currentStore = updatedStore;
                      });
                    }
                    Navigator.pop(context);
                  }
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showNotesDialog() async {
    if (_currentStore == null) return;

    final TextEditingController notesController = TextEditingController(text: _currentStore!.notes);

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${_currentStore!.name} - Notes'),
        content: SizedBox(
          width: double.maxFinite,
          child: TextField(
            controller: notesController,
            decoration: const InputDecoration(
              hintText: 'Add notes or reminders for this store...',
              border: OutlineInputBorder(),
            ),
            maxLines: 6,
            minLines: 5,
            textCapitalization: TextCapitalization.sentences,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (saved != true || !mounted) return;

    final updatedStore = _currentStore!.copyWith(notes: notesController.text);

    try {
      if (_syncService.isLoggedIn) {
        final uid = _syncService.currentUser!.uid;
        final householdId = _syncService.householdId;
        
        final collection = _firestoreService.getStoresCollection(uid, householdId: householdId);
        await collection.doc(updatedStore.id).update({'notes': notesController.text});
      }

      final localStores = StorageService.getStores();
      final localIndex = localStores.indexWhere((s) => s.id == updatedStore.id);
      if (localIndex != -1) {
        await StorageService.updateStore(localIndex, updatedStore);
      }

      setState(() {
        _currentStore = updatedStore;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notes saved!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
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
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await AuthService().signOut();
    }
  }

  Widget _buildCloudSyncedList() {
    return StreamBuilder<List<GroceryItem>>(
      stream: _syncService.getItemsStream(storeId: _currentStore?.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error: ${snapshot.error}'),
              ],
            ),
          );
        }

        final items = snapshot.data ?? [];

        if (items.isEmpty) {
          return const Center(
            child: Text(
              'No items yet.\nTap + to add your first item!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          );
        }

        return ListView.builder(
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            
            return Dismissible(
              key: Key(item.id),
              background: Container(
                color: Colors.red,
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                child: const Icon(Icons.delete, color: Colors.white),
              ),
              direction: DismissDirection.endToStart,
              confirmDismiss: (direction) async {
                final localItems = StorageService.getItems();
                final hiveIndex = localItems.indexWhere((i) => i.id == item.id);
                
                if (hiveIndex != -1) {
                  _deleteItem(hiveIndex, item.id);
                  return true;
                } else if (_syncService.isLoggedIn) {
                  try {
                    await _firestoreService.deleteItem(
                      _syncService.currentUser!.uid, 
                      item.id
                    );
                    return true;
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error deleting: $e')),
                      );
                    }
                    return false;
                  }
                }
                return false;
              },
              child: ListTile(
                leading: Checkbox(
                  value: item.isChecked,
                  onChanged: (_) async {
                    final localItems = StorageService.getItems();
                    final hiveIndex = localItems.indexWhere((i) => i.id == item.id);
                    
                    if (hiveIndex != -1) {
                      _toggleItem(item, hiveIndex);
                    } else {
                      await StorageService.addItem(item);
                      final newItems = StorageService.getItems();
                      final newIndex = newItems.indexWhere((i) => i.id == item.id);
                      if (newIndex != -1) {
                        _toggleItem(item, newIndex);
                      }
                    }
                  },
                  activeColor: _currentColor,
                ),
                title: Text(
                  item.name,
                  style: TextStyle(
                    decoration: item.isChecked ? TextDecoration.lineThrough : null,
                    color: item.isChecked ? Colors.grey : null,
                  ),
                ),
                subtitle: _buildSubtitle(item),
                trailing: Text(
                  'Qty: ${item.quantity}',
                  style: TextStyle(
                    color: item.isChecked ? Colors.grey : Colors.black87,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasNotes = _currentStore?.notes.isNotEmpty ?? false;

    return Scaffold(
      appBar: AppBar(
        title: Text(_currentStore?.name ?? 'FamilyCart'),
        backgroundColor: _currentColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(hasNotes ? Icons.notes : Icons.note_add),
            onPressed: _showNotesDialog,
            tooltip: 'Store Notes',
          ),
          IconButton(
            icon: const Icon(Icons.people),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HouseholdScreen()),
              );
            },
            tooltip: 'Household',
          ),
          IconButton(
            icon: const Icon(Icons.store),
            onPressed: _showStoreSelector,
            tooltip: 'Select Store',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'change_name') {
                _showSetUserNameDialog();
              } else if (value == 'logout') {
                _logout();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'change_name',
                child: Row(
                  children: [
                    const Icon(Icons.person),
                    const SizedBox(width: 8),
                    Text('Change Name ($_currentUser)'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Logout', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          if (hasNotes)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _currentColor.withOpacity(0.1),
                border: Border(
                  bottom: BorderSide(color: _currentColor.withOpacity(0.3)),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.notes, color: _currentColor, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _currentStore!.notes,
                      style: TextStyle(
                        color: _currentColor.withOpacity(0.8),
                        fontSize: 13,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.edit, size: 18, color: _currentColor),
                    onPressed: _showNotesDialog,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
          Expanded(
            key: ValueKey(_currentStore?.id),
            child: _buildCloudSyncedList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddItemDialog,
        backgroundColor: _currentColor,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSubtitle(GroceryItem item) {
    final List<String> parts = [];
    
    if (item.aisle != null) {
      parts.add('Aisle ${item.aisle}');
    }
    
    if (item.category != null) {
      parts.add(item.category!);
    }

    final addedInfo = 'Added by ${item.addedBy} • ${_formatDate(item.addedAt)}';
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (parts.isNotEmpty)
          Text(
            parts.join(' • '),
            style: TextStyle(
              fontSize: 12,
              color: item.isChecked ? Colors.grey : Colors.black54,
            ),
          ),
        Text(
          addedInfo,
          style: TextStyle(
            fontSize: 11,
            color: item.isChecked ? Colors.grey : Colors.black45,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final itemDate = DateTime(date.year, date.month, date.day);

    if (itemDate == today) {
      return 'Today ${DateFormat('h:mm a').format(date)}';
    } else if (itemDate == yesterday) {
      return 'Yesterday ${DateFormat('h:mm a').format(date)}';
    } else {
      return DateFormat('MMM d, h:mm a').format(date);
    }
  }
}