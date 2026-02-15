import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flags_manager/screens/site_list_screen.dart';
import 'package:flags_manager/services/auth_service.dart';
import 'package:flags_manager/services/user_service.dart';
import '../screens/po_history_screen.dart';
import '../screens/manage_users_screen.dart';
import '../models/user.dart';

class MyDrawer extends StatelessWidget {
  const MyDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final Color primaryOrange = Colors.orange.shade800;
    final Color surfaceColor = Colors.orange.shade50;

    final currentUser = FirebaseAuth.instance.currentUser;

    return FutureBuilder<AppUser?>(
      future: currentUser != null
          ? UserService().getUserByUid(currentUser.uid)
          : Future.value(null),
      builder: (context, snapshot) {
        final appUser = snapshot.data;
        final bool isAdmin = appUser?.role == "admin";
        final bool isSuperUser =
            currentUser?.email == "person1@gmail.com";

        return Drawer(
          backgroundColor: Colors.white,
          child: Column(
            children: [
              // 🔹 Header Section
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.only(top: 60, left: 24, bottom: 30),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: const BorderRadius.only(
                    bottomRight: Radius.circular(40),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: primaryOrange,
                      child: const Icon(Icons.flag_rounded,
                          color: Colors.white, size: 30),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Flags Manager',
                      style: TextStyle(
                        color: Colors.grey.shade900,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      'Project Dashboard',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 6),

                    // 👤 Show Logged In User
                    Text(
                      currentUser?.email ?? "",
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 🔹 Navigation Items
              Expanded(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12),
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [

                      // ✅ Visible only for ADMIN
                      if (isAdmin || isSuperUser)
                        _buildNavItem(
                          context,
                          icon: Icons.receipt_long_rounded,
                          label: 'POs',
                          color: primaryOrange,
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const POHistoryScreen()),
                            );
                          },
                        ),

                      // ✅ Visible only for ADMIN
                      if (isAdmin || isSuperUser)
                        _buildNavItem(
                          context,
                          icon: Icons.location_on_rounded,
                          label: "Sites",
                          color: primaryOrange,
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      const SiteListScreen()),
                            );
                          },
                        ),

                      // ✅ Only visible for person1@gmail.com
                      if (isSuperUser)
                        _buildNavItem(
                          context,
                          icon:
                              Icons.manage_accounts_rounded,
                          label: "Manage Users",
                          color: Colors.blueAccent,
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      const ManageUsersScreen()),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),

              const Divider(indent: 20, endIndent: 20),

              Padding(
                padding: const EdgeInsets.all(12.0),
                child: _buildNavItem(
                  context,
                  icon: Icons.logout_rounded,
                  label: 'Logout',
                  color: Colors.redAccent,
                  onTap: () async {
                    Navigator.pop(context);
                    await AuthService().logout();
                  },
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: color, size: 22),
      title: Text(
        label,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      onTap: onTap,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      hoverColor: color.withAlpha(10),
    );
  }
}
