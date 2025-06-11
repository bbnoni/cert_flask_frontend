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

  Map<String, Map<String, PlatformFile>> uploadedFiles = {};

  Future<void> pickFile(String branch, String fileType) async {
    final result = await FilePicker.platform.pickFiles(withData: true);
    if (result == null || result.files.isEmpty) return;

    final file = result.files.single;

    setState(() {
      uploadedFiles[branch] = uploadedFiles[branch] ?? {};
      uploadedFiles[branch]![fileType] = file;
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$fileType selected for $branch')));
  }

  @override
  Widget build(BuildContext context) {
    final banks =
        widget.branches.map((b) => b.split(',')[0].trim()).toSet().toList();

    final filteredBranches =
        widget.branches.where((b) {
          final parts = b.split(',');
          return parts.length >= 2 && parts[0].trim() == selectedBank;
        }).toList();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          DropdownButtonFormField<String>(
            hint: const Text("Select Bank"),
            value: selectedBank,
            items:
                banks
                    .map(
                      (b) => DropdownMenuItem<String>(value: b, child: Text(b)),
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
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 4,
                                            ),
                                            child: Column(
                                              children: [
                                                ElevatedButton(
                                                  onPressed:
                                                      () => pickFile(
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
                                                    child: Row(
                                                      children: [
                                                        Expanded(
                                                          child: Text(
                                                            uploadedName.name,
                                                            style:
                                                                const TextStyle(
                                                                  fontSize: 12,
                                                                  color:
                                                                      Colors
                                                                          .grey,
                                                                ),
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                          ),
                                                        ),
                                                        IconButton(
                                                          icon: const Icon(
                                                            Icons.clear,
                                                            size: 18,
                                                            color:
                                                                Colors
                                                                    .redAccent,
                                                          ),
                                                          tooltip:
                                                              "Remove file",
                                                          onPressed: () {
                                                            setState(() {
                                                              uploadedFiles[branchName]!
                                                                  .remove(type);
                                                              if (uploadedFiles[branchName]!
                                                                  .isEmpty) {
                                                                uploadedFiles
                                                                    .remove(
                                                                      branchName,
                                                                    );
                                                              }
                                                            });
                                                          },
                                                        ),
                                                      ],
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
                        (_) => const Center(child: CircularProgressIndicator()),
                  );

                  for (var branch in uploadedFiles.keys) {
                    for (var fileType in uploadedFiles[branch]!.keys) {
                      final file = uploadedFiles[branch]![fileType]!;
                      final uri = Uri.parse(
                        '${dotenv.env['API_URL']}/upload_certificate',
                      );

                      final request =
                          http.MultipartRequest('POST', uri)
                            ..fields['user_id'] = widget.userId.toString()
                            ..fields['file_type'] = fileType
                            ..fields['bank'] = selectedBank ?? ''
                            ..fields['branch'] = branch
                            ..fields['month'] = selectedMonth ?? ''
                            ..files.add(
                              http.MultipartFile.fromBytes(
                                'file',
                                file.bytes!,
                                filename: file.name,
                              ),
                            );

                      final response = await request.send();
                      print(
                        '⬆️ Uploaded $fileType for $branch → ${response.statusCode}',
                      );
                    }
                  }

                  if (mounted) Navigator.pop(context);

                  setState(() {
                    uploadedFiles.clear();
                  });

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        "All selected files uploaded successfully.",
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
