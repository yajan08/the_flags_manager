import 'package:flutter/material.dart';
import '../models/site.dart';
import '../services/site_service.dart';
import 'add_site_screen.dart';

class SiteListScreen extends StatefulWidget {
  const SiteListScreen({super.key});

  @override
  State<SiteListScreen> createState() => _SiteListScreenState();
}

class _SiteListScreenState extends State<SiteListScreen> {
  final SiteService _siteService = SiteService();

  @override
  void initState() {
    super.initState();
    _siteService.ensureDefaultSitesExist();
  }

  void _showEditDialog(Site site) {
    final controller = TextEditingController(text: site.name);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Edit Site Name"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final updated = Site(
                  id: site.id,
                  name: controller.text.trim(),
                  activeFlags: site.activeFlags,
                  washingFlags: site.washingFlags,
                );

                await _siteService.updateSite(updated);

                if (mounted) Navigator.pop(context);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(e.toString())),
                );
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  void _deleteSite(String id) async {
    try {
      await _siteService.deleteSite(id);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Sites",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<List<Site>>(
        stream: _siteService.getSites(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text(snapshot.error.toString()));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final sites = snapshot.data!;

          sites.sort((a, b) => a.name.compareTo(b.name));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sites.length,
            itemBuilder: (context, index) {
              final site = sites[index];
              final isSystem =
                  SiteService.systemSiteIds.contains(site.id);

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  title: Text(
                    site.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold),
                  ),
                  subtitle: isSystem
                      ? const Text("System Site")
                      : null,
                  trailing: isSystem
                      ? null
                      : PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'edit') {
                              _showEditDialog(site);
                            } else if (value == 'delete') {
                              _deleteSite(site.id);
                            }
                          },
                          itemBuilder: (context) => const [
                            PopupMenuItem(
                              value: 'edit',
                              child: Text("Edit"),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Text("Delete"),
                            ),
                          ],
                        ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const AddSiteScreen(),
          ),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}
