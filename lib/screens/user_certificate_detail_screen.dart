import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class UserCertificateDetailScreen extends StatefulWidget {
  final int userId;
  final String userName;
  final String month;

  const UserCertificateDetailScreen({
    super.key,
    required this.userId,
    required this.userName,
    required this.month,
  });

  @override
  State<UserCertificateDetailScreen> createState() =>
      _UserCertificateDetailScreenState();
}

class _UserCertificateDetailScreenState
    extends State<UserCertificateDetailScreen> {
  List<dynamic> branchSummary = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadBranchSummary();
  }

  Future<void> loadBranchSummary() async {
    final uri = Uri.parse(
      '${dotenv.env['API_URL']}/user_branch_summary?user_id=${widget.userId}&month=${Uri.encodeComponent(widget.month)}',
    );

    print("🔍 Branch summary URI: $uri");

    final response = await http.get(uri);
    if (response.statusCode == 200) {
      setState(() {
        branchSummary = jsonDecode(response.body);
        loading = false;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to load branch summary.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.userName}'s Uploads - ${widget.month}"),
      ),
      body:
          loading
              ? const Center(child: CircularProgressIndicator())
              : branchSummary.isEmpty
              ? const Center(child: Text("No uploads found."))
              : ListView.builder(
                itemCount: branchSummary.length,
                itemBuilder: (_, index) {
                  final b = branchSummary[index];
                  final completed =
                      (b['JCC'] ?? 0) > 0 &&
                      (b['DCC'] ?? 0) > 0 &&
                      (b['JSDN'] ?? 0) > 0;

                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: ListTile(
                      title: Text("${b['bank']}, ${b['branch']}"),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("JCC: ${b['JCC']}"),
                          if (b['JCC_url'] != null && b['JCC_url'] != '')
                            TextButton(
                              onPressed:
                                  () => launchUrl(Uri.parse(b['JCC_url'])),
                              child: const Text("Download JCC"),
                            ),
                          Text("DCC: ${b['DCC']}"),
                          if (b['DCC_url'] != null && b['DCC_url'] != '')
                            TextButton(
                              onPressed:
                                  () => launchUrl(Uri.parse(b['DCC_url'])),
                              child: const Text("Download DCC"),
                            ),
                          Text("JSDN: ${b['JSDN']}"),
                          if (b['JSDN_url'] != null && b['JSDN_url'] != '')
                            TextButton(
                              onPressed:
                                  () => launchUrl(Uri.parse(b['JSDN_url'])),
                              child: const Text("Download JSDN"),
                            ),
                        ],
                      ),

                      trailing: Icon(
                        completed ? Icons.check_circle : Icons.warning_amber,
                        color: completed ? Colors.green : Colors.red,
                      ),
                    ),
                  );
                },
              ),
    );
  }
}
