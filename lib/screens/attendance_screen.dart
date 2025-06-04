import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class AttendanceScreen extends StatefulWidget {
  final String name;
  final String location;
  final int userId;

  const AttendanceScreen({
    super.key,
    required this.name,
    required this.location,
    required this.userId,
  });

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  String? coordinates;
  File? selfie;
  String? note;
  bool isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _fetchLocation();
  }

  Future<void> _fetchLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await Geolocator.openLocationSettings();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        permission = await Geolocator.requestPermission();
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        coordinates =
            '${position.latitude.toStringAsFixed(4)}° N, ${position.longitude.toStringAsFixed(4)}° W';
      });
    } catch (e) {
      setState(() {
        coordinates = 'Location unavailable';
      });
    }
  }

  Future<void> _pickSelfie() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.camera);
    if (picked != null) {
      setState(() => selfie = File(picked.path));
    }
  }

  Future<void> _checkIn() async {
    if (coordinates == null || coordinates == 'Location unavailable') {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Location not available")));
      return;
    }

    setState(() => isSubmitting = true);

    final uri = Uri.parse('${dotenv.env['API_URL']}/attendance');
    final request =
        http.MultipartRequest('POST', uri)
          ..fields['user_id'] = widget.userId.toString()
          ..fields['note'] = note ?? ''
          ..fields['location'] = coordinates ?? '';

    if (selfie != null) {
      request.files.add(
        await http.MultipartFile.fromPath('selfie', selfie!.path),
      );
    }

    final response = await request.send();

    setState(() => isSubmitting = false);

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Attendance submitted successfully")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to submit attendance")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final date = "${now.year}-${now.month}-${now.day}";
    final time = "${now.hour}:${now.minute.toString().padLeft(2, '0')}";

    return Scaffold(
      appBar: AppBar(title: const Text("Attendance App")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            const Icon(Icons.account_circle, size: 60),
            Text(widget.name, style: const TextStyle(fontSize: 20)),
            Text(widget.location),
            const SizedBox(height: 16),
            Text("Date: $date"),
            Text("Time: $time"),
            Text("Location: ${coordinates ?? "Loading..."}"),
            const SizedBox(height: 8),
            const Text("East Legon, Accra"),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(hintText: 'Note (optional)'),
              onChanged: (val) => note = val,
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _pickSelfie,
              icon: const Icon(Icons.camera_alt),
              label: const Text('Add Selfie (optional)'),
            ),
            if (selfie != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Image.file(selfie!, height: 150),
              ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: isSubmitting ? null : _checkIn,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                isSubmitting ? "Submitting..." : "CHECK IN NOW",
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
