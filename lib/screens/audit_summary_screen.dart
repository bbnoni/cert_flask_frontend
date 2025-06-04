import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
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

  Future<void> loadSummary() async {
    final url = Uri.parse('${dotenv.env['API_URL']}/summary');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        totalAttendance = data['total_attendance_records'];
        totalCertificates = data['total_certificates'];
        loading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    loadSummary();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Audit Summary')),
      body: Center(
        child:
            loading
                ? const CircularProgressIndicator()
                : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('📍 Total Attendance Records: $totalAttendance'),
                    const SizedBox(height: 10),
                    Text('📄 Total Certificates Uploaded: $totalCertificates'),
                  ],
                ),
      ),
    );
  }
}
