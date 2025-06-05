import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class AuditFilesScreen extends StatefulWidget {
  const AuditFilesScreen({super.key});

  @override
  State<AuditFilesScreen> createState() => _AuditFilesScreenState();
}

class _AuditFilesScreenState extends State<AuditFilesScreen> {
  List<dynamic> files = [];

  @override
  void initState() {
    super.initState();
    fetchAuditFiles();
  }

  Future<void> fetchAuditFiles() async {
    final uri = Uri.parse('${dotenv.env['API_URL']}/audit_files');
    final res = await http.get(uri);

    if (res.statusCode == 200) {
      setState(() {
        files = json.decode(res.body);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to fetch uploaded files.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Uploaded Files (Audit)")),
      body:
          files.isEmpty
              ? const Center(child: Text("No files uploaded for this month."))
              : ListView.builder(
                itemCount: files.length,
                itemBuilder: (_, index) {
                  final f = files[index];
                  return ListTile(
                    leading: const Icon(Icons.insert_drive_file),
                    title: Text("${f['bank']}, ${f['branch']}"),
                    subtitle: Text(
                      "Type: ${f['file_type']} • ${f['uploaded_at']}",
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.download),
                      onPressed: () {
                        // You can use url_launcher package to open the link
                        launchUrl(Uri.parse(f['file_url']));
                      },
                    ),
                  );
                },
              ),
    );
  }
}
