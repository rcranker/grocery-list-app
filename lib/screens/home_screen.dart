import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/grocery_item.dart';
import '../models/store.dart';
import '../services/storage_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Store? _currentStore;

  @override
  void initState() {
    super.initState();
    _currentStore = StorageService.getDefaultStore();
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
    );
    StorageService.addItem(item);
  }

  void _toggleItem(GroceryItem item, int index) {
    final updatedItem = item.copyWith(
      isChecked: !item.isChecked,
      checkedAt: !item.isChecked ? DateTime.now() : null,
    );
    StorageService.updateItem(index, updatedItem);
  }

  void _deleteItem(int index) {
    StorageService.deleteItem(index);
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
        content: ValueListenableBuilder(
          valueListenable: StorageService.getStoresBox().listenable(),
          builder: (context, Box<Store> box, _) {
            final stores = box.values.toList();
            
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
                       _showEditStoreDialog(store, box.values.toList().indexOf(store));
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
                    );
                    StorageService.addStore(store);
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
                    StorageService.deleteStore(index);
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
                    StorageService.updateStore(index, updatedStore);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentStore?.name ?? 'My Grocery List'),
        backgroundColor: _currentColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.store),
            onPressed: _showStoreSelector,
            tooltip: 'Select Store',
          ),
        ],
      ),
      body: ValueListenableBuilder(
        valueListenable: StorageService.getItemsBox().listenable(),
        builder: (context, Box<GroceryItem> box, _) {
          final allItems = box.values.toList();
          final items = _currentStore == null
              ? allItems
              : allItems.where((item) => item.storeId == _currentStore?.id).toList();

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
            itemBuilder: (context, listIndex) {
              final item = items[listIndex];
              final boxIndex = box.values.toList().indexOf(item);
              
              return Dismissible(
                key: Key(item.id),
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                direction: DismissDirection.endToStart,
                onDismissed: (_) => _deleteItem(boxIndex),
                child: ListTile(
                  leading: Checkbox(
                    value: item.isChecked,
                    onChanged: (_) => _toggleItem(item, boxIndex),
                    activeColor: _currentColor,
                  ),
                  title: Text(
                    item.name,
                    style: TextStyle(
                      decoration: item.isChecked
                          ? TextDecoration.lineThrough
                          : null,
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
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddItemDialog,
        backgroundColor: _currentColor,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget? _buildSubtitle(GroceryItem item) {
    final List<String> parts = [];
    
    if (item.aisle != null) {
      parts.add('Aisle ${item.aisle}');
    }
    
    if (item.category != null) {
      parts.add(item.category!);
    }
    
    if (parts.isEmpty) return null;
    
    return Text(
      parts.join(' • '),
      style: TextStyle(
        fontSize: 12,
        color: item.isChecked ? Colors.grey : Colors.black54,
      ),
    );
  }
}