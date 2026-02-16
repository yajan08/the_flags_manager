import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flags_manager/screens/site_list_screen.dart';
import 'package:flags_manager/services/auth_service.dart';
import 'package:flags_manager/services/user_service.dart';
import '../screens/po_history_screen.dart';
import '../screens/manage_users_screen.dart';
import '../screens/global_history_screen.dart'; 
import '../models/user.dart';

class MyDrawer extends StatelessWidget {
  const MyDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    const Color primaryOrange = Color(0xFFFF6F00);
    const Color textDark = Color(0xFF2D3436);
    const Color textMuted = Color(0xFF636E72);

    final currentUser = FirebaseAuth.instance.currentUser;

    return FutureBuilder<AppUser?>(
      future: currentUser != null
          ? UserService().getUserByUid(currentUser.uid)
          : Future.value(null),
      builder: (context, snapshot) {
        final appUser = snapshot.data;
        final bool isAdmin = appUser?.role == "admin";
        final bool isSuperUser = currentUser?.email == "person1@gmail.com";

        return Drawer(
          backgroundColor: Colors.white,
          child: Column(
            children: [
              // 🔹 Header Section with Gradient
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 60, 24, 30),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFFFF3E0), Colors.white],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: primaryOrange,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: primaryOrange.withAlpha(77),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: const Icon(Icons.flag_rounded, color: Colors.white, size: 30),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Flag Inventory',
                      style: TextStyle(
                        color: textDark,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // 👤 Role Badge & Email
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: isSuperUser ? Colors.blueAccent : primaryOrange.withAlpha(26),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isSuperUser ? "SUPERUSER" : (isAdmin ? "ADMIN" : "USER"),
                            style: TextStyle(
                              color: isSuperUser ? Colors.white : primaryOrange,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            currentUser?.email ?? "",
                            style: const TextStyle(
                              color: textMuted,
                              fontSize: 12,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const Divider(height: 1, indent: 24, endIndent: 24),

              // 🔹 Navigation Items
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  children: [
                    // 🏠 Home Dashboard - Visible to ALL
                    _buildNavItem(
                      context,
                      icon: Icons.dashboard_customize_outlined,
                      label: 'Home Dashboard',
                      color: textDark,
                      onTap: () => Navigator.pop(context),
                    ),
                    
                    const SizedBox(height: 8),

                    // 📜 Audit History - Visible to ALL
                    _buildNavItem(
                      context,
                      icon: Icons.manage_history_rounded,
                      label: "Audit History",
                      color: textDark, // Keeping it neutral for general users
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const GlobalHistoryScreen()),
                        );
                      },
                    ),

                    // 💼 Admin Section - Visible to ADMINS & SUPERUSER
                    if (isAdmin || isSuperUser) ...[
                      const Padding(
                        padding: EdgeInsets.only(left: 16, top: 24, bottom: 8),
                        child: Text("MANAGEMENT", 
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: textMuted, letterSpacing: 1.2)),
                      ),
                      _buildNavItem(
                        context,
                        icon: Icons.receipt_long_rounded,
                        label: 'Purchase Orders',
                        color: primaryOrange,
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const POHistoryScreen()),
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      _buildNavItem(
                        context,
                        icon: Icons.location_on_rounded,
                        label: "Manage Sites",
                        color: primaryOrange,
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const SiteListScreen()),
                          );
                        },
                      ),
                    ],

                    // 🔑 SuperUser Section - Visible ONLY to person1@gmail.com
                    if (isSuperUser) ...[
                      const Padding(
                        padding: EdgeInsets.only(left: 16, top: 24, bottom: 8),
                        child: Text("ADMINISTRATION", 
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: textMuted, letterSpacing: 1.2)),
                      ),
                      _buildNavItem(
                        context,
                        icon: Icons.manage_accounts_rounded,
                        label: "Manage Users",
                        color: Colors.blueAccent,
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const ManageUsersScreen()),
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),

              // 🔹 Logout Section & Developer Credit
              const Divider(indent: 24, endIndent: 24),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                child: _buildNavItem(
                  context,
                  icon: Icons.logout_rounded,
                  label: 'Sign Out',
                  color: Colors.redAccent,
                  onTap: () async {
                    Navigator.pop(context);
                    await AuthService().logout();
                  },
                ),
              ),
              
              // 🔹 Subtle Developer Credit
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Column(
                  children: [
                    Text(
                      "Developed by",
                      style: TextStyle(color: textMuted.withAlpha(150), fontSize: 10, fontWeight: FontWeight.w500),
                    ),
                    Text(
                      "yajanmehta@gmail.com",
                      style: TextStyle(color: textMuted.withAlpha(180), fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
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
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withAlpha(26),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        label,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: Color(0xFF2D3436),
        ),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      onTap: onTap,
      visualDensity: const VisualDensity(vertical: -1),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
    );
  }
}