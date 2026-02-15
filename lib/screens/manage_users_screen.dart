// ignore_for_file: use_build_context_synchronously

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

  static const Color primaryOrange = Color(0xFFFF6F00);
  static const Color bgColor = Color(0xFFF8F9FA);
  static const Color textDark = Color(0xFF2D3436);
  static const Color textMuted = Color(0xFF636E72);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text(
          "User Management",
          style: TextStyle(fontWeight: FontWeight.w800, color: textDark, fontSize: 18),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: textDark,
      ),
      body: StreamBuilder<List<AppUser>>(
        stream: userService.getAllUsers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: primaryOrange));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline_rounded, size: 64, color: textMuted.withAlpha(51)),
                  const SizedBox(height: 16),
                  const Text("No users registered yet", style: TextStyle(color: textMuted)),
                ],
              ),
            );
          }

          final users = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
            physics: const BouncingScrollPhysics(),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              final bool isMe = user.id == currentUser?.uid;
              final bool isAdmin = user.role == "admin";

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: isMe ? primaryOrange.withAlpha(8) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isMe ? primaryOrange.withAlpha(51) : Colors.black.withAlpha(8),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(5),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    radius: 24,
                    backgroundColor: isAdmin ? primaryOrange : textMuted.withAlpha(26),
                    child: Text(
                      user.name.isNotEmpty ? user.name[0].toUpperCase() : "U",
                      style: TextStyle(
                        color: isAdmin ? Colors.white : textMuted,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          user.name,
                          style: const TextStyle(fontWeight: FontWeight.w800, color: textDark, fontSize: 15),
                        ),
                      ),
                      if (isMe)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: textDark,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text("YOU", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900)),
                        ),
                    ],
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Row(
                      children: [
                        _buildRoleBadge(user.role),
                      ],
                    ),
                  ),
                  trailing: isMe
                      ? null
                      : SizedBox(
                          width: 100,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              const Text("ADMIN", 
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: textMuted)
                              ),
                              Transform.scale(
                                scale: 0.75,
                                child: Switch(
                                  activeThumbColor: primaryOrange,
                                  value: isAdmin,
                                  onChanged: (value) async {
                                    final newRole = value ? "admin" : "user";
                                    try {
                                      final messenger = ScaffoldMessenger.of(context);
                                      await userService.updateUserRole(
                                        uid: user.id,
                                        newRole: newRole,
                                        currentUserEmail: currentUser?.email ?? "",
                                      );
                                      if (!mounted) return;
                                      _showStatusSnack(messenger, "Role updated to $newRole for ${user.name}");
                                    } catch (e) {
                                      if (!mounted) return;
                                      _showStatusSnack(ScaffoldMessenger.of(context), "Error: ${e.toString()}", isError: true);
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildRoleBadge(String role) {
    final bool isAdmin = role == "admin";
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isAdmin ? primaryOrange.withAlpha(26) : Colors.black.withAlpha(13),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        role.toUpperCase(),
        style: TextStyle(
          color: isAdmin ? primaryOrange : textMuted,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  void _showStatusSnack(ScaffoldMessengerState messenger, String message, {bool isError = false}) {
    messenger.showSnackBar(
      SnackBar(
        backgroundColor: isError ? Colors.redAccent : textDark,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }
}