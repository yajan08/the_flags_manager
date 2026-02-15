import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user.dart';
import '../services/user_service.dart';

class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({super.key});

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  final userService = UserService();
  final currentUser = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Manage Users"),
        centerTitle: true,
      ),
      body: StreamBuilder<List<AppUser>>(
        stream: userService.getAllUsers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No users found"));
          }

          final users = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              final bool isMe = user.id == currentUser?.uid;

              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(
                      user.name.isNotEmpty ? user.name[0].toUpperCase() : "U",
                    ),
                  ),
                  title: Text(user.name),
                  subtitle: Text("Role: ${user.role}"),
                 trailing: isMe
    ? const Text(
        "You",
        style: TextStyle(fontWeight: FontWeight.bold),
      )
    : Switch(
        value: user.role == "admin",
        onChanged: (value) async {
  final newRole = value ? "admin" : "user";

  try {
    // Capture scaffoldMessenger before async gap
    final messenger = ScaffoldMessenger.of(context);

    await userService.updateUserRole(
      uid: user.id,
      newRole: newRole,
      currentUserEmail: currentUser?.email ?? "",
    );

    if (!mounted) return;

    messenger.showSnackBar(
      SnackBar(
        content: Text("Role updated to $newRole for ${user.name}"),
      ),
    );
  } catch (e) {
    if (!mounted) return;
    if (context.mounted) {
      final messenger = ScaffoldMessenger.of(context);
        messenger.showSnackBar(
          SnackBar(
            content: Text("Error updating role: ${e.toString()}"),
          ),
        );
    }
  }
},

      ),

                ),
              );
            },
          );
        },
      ),
    );
  }
}