import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_frontend/screens/user_certificate_detail_screen.dart';
import 'package:http/http.dart' as http;

class AuditSummaryScreen extends StatefulWidget {
  const AuditSummaryScreen({super.key});

  @override
  State<AuditSummaryScreen> createState() => _AuditSummaryScreenState();
}

class _AuditSummaryScreenState extends State<AuditSummaryScreen> {
  int totalAttendance = 0;
  int totalCertificates = 0;
  bool loading = true;

  String selectedMonth = '';
  List<String> months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  List<dynamic> certificateSummary = [];

  Future<void> loadSummary() async {
    final summaryUrl = Uri.parse('${dotenv.env['API_URL']}/summary');
    final certSummaryUrl = Uri.parse(
      '${dotenv.env['API_URL']}/audit_summary?month=$selectedMonth',
    );

    try {
      final summaryRes = await http.get(summaryUrl);
      final certSummaryRes = await http.get(certSummaryUrl);

      if (summaryRes.statusCode == 200 && certSummaryRes.statusCode == 200) {
        final summaryData = jsonDecode(summaryRes.body);
        final certSummaryData = jsonDecode(certSummaryRes.body);

        setState(() {
          totalAttendance = summaryData['total_attendance_records'];
          totalCertificates = summaryData['total_certificates'];
          certificateSummary = certSummaryData;
          loading = false;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to load summary data")),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    selectedMonth = months[DateTime.now().month - 1];
    loadSummary();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Audit Summary')),
      body:
          loading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('📍 Total Attendance Records: $totalAttendance'),
                    const SizedBox(height: 8),
                    Text('📄 Total Certificates Uploaded: $totalCertificates'),
                    const SizedBox(height: 24),
                    DropdownButtonFormField<String>(
                      value: selectedMonth,
                      decoration: const InputDecoration(
                        labelText: "Select Month",
                        border: OutlineInputBorder(),
                      ),
                      items:
                          months
                              .map(
                                (m) =>
                                    DropdownMenuItem(value: m, child: Text(m)),
                              )
                              .toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedMonth = value!;
                          loading = true;
                        });
                        loadSummary();
                      },
                    ),
                    const SizedBox(height: 20),
                    const Divider(),
                    const Text(
                      "📊 Per-User Certificate Summary:",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    ...certificateSummary.map((entry) {
                      final hasMissing = entry['has_missing'] == true;

                      return Card(
                        color: hasMissing ? Colors.red[100] : null,
                        child: ListTile(
                          title: Text(entry['user']),
                          subtitle: Text("Month: ${entry['month']}"),
                          trailing: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text("JCC: ${entry['JCC']}"),
                              Text("DCC: ${entry['DCC']}"),
                              Text("JSDN: ${entry['JSDN']}"),
                            ],
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (_) => UserCertificateDetailScreen(
                                      userId: entry['user_id'],
                                      userName: entry['user'],
                                      month: selectedMonth,
                                    ),
                              ),
                            );
                          },
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
    );
  }
}
