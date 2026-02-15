// ignore_for_file: use_build_context_synchronously

import 'package:flags_manager/services/user_service.dart';
import 'package:flags_manager/widgets/my_text_field.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; 
import '../services/auth_service.dart';
import '../widgets/my_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  bool isLoading = false;
  String? errorMessage;

  Future<void> login() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final userCredential = await _authService.login(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      final user = userCredential.user;

      if (user != null) {
        final userService = UserService();
        final userDoc = await userService.getUserByUid(user.uid);

        if (userDoc == null) {
          await userService.createUserInFirestore(
            uid: user.uid,
            name: user.email ?? "User",
            role: "user",
          );
        }
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        errorMessage = e.toString();
      });
    }

    if (!mounted) return;

    setState(() {
      isLoading = false;
    });
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const primaryOrange = Color(0xFFFF6F00);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 60),

                // 🔹 Logo Circle
                Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: primaryOrange,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: primaryOrange.withAlpha(30),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        )
                      ],
                    ),
                    child: const Icon(
                      Icons.flag,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                // 🔹 Welcome Text
                Text(
                  "Welcome Back",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),

                const SizedBox(height: 12),
                Text(
                  "Sign in to continue",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),

                const SizedBox(height: 40),

                // 🔹 Email Field (Using MyTextField)
                MyTextField(
                  hintText: "Email",
                  keyboardType: TextInputType.emailAddress,
                  obscureText: false,
                  controller: emailController,
                  prefixIcon: Icons.email_outlined,
                ),

                // 🔹 Password Field (Using MyTextField)
                MyTextField(
                  hintText: "Password",
                  obscureText: true,
                  controller: passwordController,
                  prefixIcon: Icons.lock_outline,
                ),

                if (errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // 🔹 Login Button (Using MyButton)
                MyButton(
                  text: isLoading ? "Signing in..." : "Sign in",
                  onTap: isLoading ? null : login,
                  prefixIcon: isLoading 
                    ? const SizedBox(
                        height: 20, 
                        width: 20, 
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                      ) 
                    : null,
                ),

                const SizedBox(height: 40),

                // 🔹 Professional Divider
                Row(
                  children: [
                    Expanded(child: Divider(color: Colors.grey[400])),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                      child: Text(
                        "Support",
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ),
                    Expanded(child: Divider(color: Colors.grey[400])),
                  ],
                ),

                const SizedBox(height: 20),

                // 🔹 Styled Contact Section
                Column(
                  children: [
                    Text(
                      "Need a demo or an account?",
                      style: TextStyle(
                        color: Colors.grey[800],
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () async {
                        final Uri emailUri = Uri.parse(
                          'mailto:yajanmehta@gmail.com?subject=Inventory App Request',
                        );
                        try {
                          if (await canLaunchUrl(emailUri)) {
                            await launchUrl(emailUri,
                                mode: LaunchMode.externalApplication);
                          } else {
                            throw 'Could not launch email app';
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: primaryOrange,
                                content: const Text(
                                  "Please email: yajanmehta@gmail.com",
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            );
                          }
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: primaryOrange.withAlpha(30)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.email_outlined,
                                size: 18, color: primaryOrange),
                            const SizedBox(width: 10),
                            const Text(
                              "yajanmehta@gmail.com",
                              style: TextStyle(
                                color: primaryOrange,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}