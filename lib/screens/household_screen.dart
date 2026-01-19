import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/household.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/sync_service.dart';

class HouseholdScreen extends StatefulWidget {
  const HouseholdScreen({super.key});

  @override
  State<HouseholdScreen> createState() => _HouseholdScreenState();
}

class _HouseholdScreenState extends State<HouseholdScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();
  
  UserModel? _currentUser;
  Household? _household;
  List<UserModel> _members = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    final uid = _authService.currentUser?.uid;
    if (uid == null) return;

    try {
      _currentUser = await _firestoreService.getUserData(uid);
      
      if (_currentUser?.householdId != null) {
        _household = await _firestoreService.getHousehold(_currentUser!.householdId!);
        if (_household != null) {
          _members = await _firestoreService.getHouseholdMembers(_household!.id);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading household: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _createHousehold() async {
    final nameController = TextEditingController();
  
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Household'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Household Name',
            hintText: 'e.g., Smith Family',
          ),
          textCapitalization: TextCapitalization.words,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, nameController.text.trim()),
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (name == null || name.isEmpty || !mounted) return;

    setState(() => _isLoading = true);

    try {
      final householdId = await _firestoreService.createHousehold(
        name: name,
        ownerId: _authService.currentUser!.uid,
      );

      debugPrint('Household created with ID: $householdId');  
      if (!mounted) return;
  
      // Show dialog telling user to logout/login
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Household Created!'),
          content: const Text(
            'Your household has been created successfully.\n\n'
            'Please logout and login again to start using household features.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _authService.signOut();
              },
              child: const Text('Logout Now'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
    
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating household: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _joinHousehold() async {
    final codeController = TextEditingController();
  
    final code = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Join Household'),
        content: TextField(
          controller: codeController,
          decoration: const InputDecoration(
            labelText: 'Invite Code',
            hintText: 'Enter 6-character code',
          ),
          textCapitalization: TextCapitalization.characters,
          maxLength: 6,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, codeController.text.trim().toUpperCase()),
            child: const Text('Join'),
          ),
        ],
      ),
    );

    if (code == null || code.isEmpty || !mounted) return;
    setState(() => _isLoading = true);

    try {
      await _firestoreService.joinHousehold(
        inviteCode: code,
        userId: _authService.currentUser!.uid,
      );

      if (!mounted) return;

      // Show dialog telling user to logout/login
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Joined Household!'),
          content: const Text(
            'You have successfully joined the household.\n\n'
            'Please logout and login again to see shared stores and items.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _authService.signOut();
              },
              child: const Text('Logout Now'),
            ),
          ],
        ),
      );
    
    } catch (e) {
      if (!mounted) return;
    
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  } //JoinHousehold

  Future<void> _leaveHousehold() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Household'),
        content: Text(
          _household!.ownerId == _authService.currentUser!.uid
              ? 'As the owner, leaving will delete this household for all members. Are you sure?'
              : 'Are you sure you want to leave this household?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Leave'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isLoading = true);

    try {
      await _firestoreService.leaveHousehold(
        householdId: _household!.id,
        userId: _authService.currentUser!.uid,
      );

      // Refresh sync service to clear household ID
      final syncService = SyncService();
      await syncService.refreshUserData();

      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Left household successfully')),
      );

      await _loadData();
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error leaving household: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _copyInviteCode() {
    if (_household?.inviteCode != null) {
      Clipboard.setData(ClipboardData(text: _household!.inviteCode!));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invite code copied to clipboard!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
  return Scaffold(
    appBar: AppBar(
      title: const Text('Household'),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _loadData,
          tooltip: 'Refresh',
        ),
      ],
    ),
    body: const Center(child: CircularProgressIndicator()),
  );
}

if (_household == null) {
  return Scaffold(
    appBar: AppBar(
      title: const Text('Household'),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _loadData,
          tooltip: 'Refresh',
        ),
      ],
    ),
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.people_outline, size: 80, color: Colors.grey),
            const SizedBox(height: 24),
            const Text(
              'No Household',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Create a household to share grocery lists with family',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _createHousehold,
              icon: const Icon(Icons.add),
              label: const Text('Create Household'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _joinHousehold,
              icon: const Icon(Icons.group_add),
              label: const Text('Join Household'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

    // User is in a household
    return Scaffold(
      appBar: AppBar(
        title: Text(_household!.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: _leaveHousehold,
            tooltip: 'Leave Household',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Invite Code',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        _household!.inviteCode ?? 'N/A',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.copy),
                        onPressed: _copyInviteCode,
                        tooltip: 'Copy Code',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Share this code with family members to join',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Members (${_members.length})',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ..._members.map((member) {
            final isOwner = member.uid == _household!.ownerId;
            final isCurrentUser = member.uid == _authService.currentUser?.uid;
            
            return ListTile(
              leading: CircleAvatar(
                child: Text(member.displayName[0].toUpperCase()),
              ),
              title: Text(
                member.displayName + (isCurrentUser ? ' (You)' : ''),
                style: TextStyle(
                  fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              subtitle: Text(member.email),
              trailing: isOwner 
                  ? const Chip(label: Text('Owner'), backgroundColor: Colors.green)
                  : null,
            );
          }),
        ],
      ),
    );
  }
}