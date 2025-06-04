import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class UploadCertificatesScreen extends StatefulWidget {
  final int userId;
  final List<dynamic> branches;

  const UploadCertificatesScreen({
    super.key,
    required this.userId,
    required this.branches,
  });

  @override
  State<UploadCertificatesScreen> createState() =>
      _UploadCertificatesScreenState();
}

class _UploadCertificatesScreenState extends State<UploadCertificatesScreen> {
  String? selectedBank;
  String? selectedMonth;
  String message = '';

  final months = [
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

  // ✅ New: map to hold uploaded filenames by branch and file type
  Map<String, Map<String, String>> uploadedFiles = {};

  Future<void> uploadFile(String branch, String fileType) async {
    print('📤 Upload triggered for $fileType at $branch');

    final result = await FilePicker.platform.pickFiles(withReadStream: true);
    if (result == null) {
      print('❌ No file picked');
      return;
    }

    final fileName = result.files.single.name;
    final fileStream = http.ByteStream(result.files.single.readStream!);
    final fileLength = result.files.single.size;

    print('📁 Picked file: $fileName');
    print('📦 File size: $fileLength bytes');

    final uri = Uri.parse('${dotenv.env['API_URL']}/upload_certificate');
    final request =
        http.MultipartRequest('POST', uri)
          ..fields['user_id'] = widget.userId.toString()
          ..fields['file_type'] = fileType
          ..fields['bank'] = selectedBank ?? ''
          ..fields['branch'] = branch
          ..fields['month'] = selectedMonth ?? ''
          ..files.add(
            http.MultipartFile(
              'file',
              fileStream,
              fileLength,
              filename: fileName,
            ),
          );

    try {
      print('🚀 Sending request...');
      final response = await request.send();
      print('✅ Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        setState(() {
          uploadedFiles[branch] = uploadedFiles[branch] ?? {};
          uploadedFiles[branch]![fileType] = fileName;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$fileType uploaded for $branch')),
        );
      } else {
        print('❌ Upload failed with status: ${response.statusCode}');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Upload failed for $branch')));
      }
    } catch (e) {
      print('❌ Upload failed with error: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error during upload: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Extract unique bank names from the full 'bank,branch' strings
    final banks =
        widget.branches.map((b) => b.split(',')[0].trim()).toSet().toList();

    // Filter branch pairs by selected bank
    final filteredBranches =
        widget.branches.where((b) {
          final parts = b.split(',');
          return parts.length >= 2 && parts[0].trim() == selectedBank;
        }).toList();

    return Scaffold(
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: const [
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.deepPurple),
              child: Text(
                'Spaklean',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            ListTile(leading: Icon(Icons.dashboard), title: Text('Dashboard')),
            ListTile(
              leading: Icon(Icons.upload_file),
              title: Text('Upload Certificates'),
            ),
            ListTile(leading: Icon(Icons.history), title: Text('Audit Logs')),
          ],
        ),
      ),
      appBar: AppBar(title: const Text('Upload Certificates')),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              hint: const Text("Select Bank"),
              value: selectedBank,
              items:
                  banks
                      .map(
                        (b) =>
                            DropdownMenuItem<String>(value: b, child: Text(b)),
                      )
                      .toList(),
              onChanged: (v) => setState(() => selectedBank = v),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              hint: const Text("Select Month"),
              value: selectedMonth,
              items:
                  months
                      .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                      .toList(),
              onChanged: (v) => setState(() => selectedMonth = v),
            ),
            const SizedBox(height: 20),
            if (selectedBank != null && selectedMonth != null)
              Expanded(
                child:
                    filteredBranches.isEmpty
                        ? const Center(child: Text("No branches found."))
                        : ListView.builder(
                          itemCount: filteredBranches.length,
                          itemBuilder: (_, index) {
                            final parts = filteredBranches[index].split(',');
                            final branchName =
                                parts.length > 1
                                    ? parts[1].trim()
                                    : 'Unknown Branch';

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.location_on_outlined),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          '$selectedBank, $branchName',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children:
                                        ['JCC', 'DCC', 'JSDN'].map((type) {
                                          final uploadedName =
                                              uploadedFiles[branchName]?[type];
                                          return Expanded(
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 4,
                                                  ),
                                              child: Column(
                                                children: [
                                                  ElevatedButton(
                                                    onPressed:
                                                        () => uploadFile(
                                                          branchName,
                                                          type,
                                                        ),
                                                    child: Text('Upload $type'),
                                                  ),
                                                  if (uploadedName != null)
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                            top: 4,
                                                          ),
                                                      child: Text(
                                                        uploadedName,
                                                        style: const TextStyle(
                                                          fontSize: 12,
                                                          color: Colors.grey,
                                                        ),
                                                        overflow:
                                                            TextOverflow
                                                                .ellipsis,
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
              ),
            if (uploadedFiles.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.send),
                  label: const Text("Final Submit"),
                  onPressed: () async {
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder:
                          (_) =>
                              const Center(child: CircularProgressIndicator()),
                    );

                    // Simulate delay or call your own API
                    await Future.delayed(const Duration(seconds: 2));

                    if (mounted) Navigator.pop(context); // Close progress

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("All uploaded files submitted."),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
