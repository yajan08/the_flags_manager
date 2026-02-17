// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/site.dart';
import '../widgets/my_button.dart';      // ✅ Integrated
import '../widgets/my_text_field.dart'; // ✅ Integrated
import 'package:posthog_flutter/posthog_flutter.dart';

class AddSiteScreen extends StatefulWidget {
  const AddSiteScreen({super.key});

  @override
  State<AddSiteScreen> createState() => _AddSiteScreenState();
}

class _AddSiteScreenState extends State<AddSiteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  bool _isLoading = false;

  static const Color primaryOrange = Color(0xFFFF6F00);
  static const Color bgColor = Color(0xFFF8F9FA);
  static const Color textDark = Color(0xFF2D3436);
  static const Color textMuted = Color(0xFF636E72);

  Future<void> _saveSite() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final docRef = FirebaseFirestore.instance.collection('sites').doc();
      final siteName = _nameController.text.trim(); // Get the name for tracking

      final site = Site(
        id: docRef.id,
        name: siteName,
        activeFlags: [],
        washingFlags: [],
      );

      await docRef.set(site.toMap());

      // ✅ ADD THIS POSTHOG TRACKING HERE
      Posthog().capture(
        eventName: 'site_created',
        properties: {
          'site_name': siteName,
          'site_id': docRef.id,
        },
      );

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      // ... existing error handling
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text(
          "Add New Site",
          style: TextStyle(fontWeight: FontWeight.w800, color: textDark, fontSize: 18),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: textDark,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // 🔹 Instructional Icon/Text
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(50),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Column(
                    children: [
                      const CircleAvatar(
                        radius: 30,
                        backgroundColor: Color(0xFFFFF3E0),
                        child: Icon(Icons.add_location_alt_rounded, color: primaryOrange, size: 30),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "Create Site Location",
                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: textDark),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Specify a new location where flags can be stored, transferred, or sent to washing.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: textMuted, fontSize: 13, height: 1.5),
                      ),
                      const SizedBox(height: 32),
                      
                      // 🔹 MyTextField Integration
                      MyTextField(
                        controller: _nameController,
                        hintText: "Enter Site Name (e.g. Warehouse B)",
                        obscureText: false,
                        prefixIcon: Icons.business_rounded,
                        // Logic untouched, validation still handled by Form
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),

                // 🔹 MyButton Integration
                MyButton(
                  text: _isLoading ? "Creating..." : "Create Site",
                  onTap: _isLoading ? null : _saveSite,
                  prefixIcon: _isLoading 
                    ? const SizedBox(
                        height: 20, 
                        width: 20, 
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                      ) 
                    : const Icon(Icons.check_circle_outline_rounded, color: Colors.white),
                ),
                
                const SizedBox(height: 16),
                
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    "Go Back",
                    style: TextStyle(color: textMuted, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}