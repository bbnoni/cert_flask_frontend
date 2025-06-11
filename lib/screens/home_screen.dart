import 'package:flutter/material.dart';

import 'upload_certificates_screen.dart';

class HomeScreen extends StatefulWidget {
  final int userId;
  final List<String> branches;

  const HomeScreen({super.key, required this.userId, required this.branches});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 1; // 0: Dashboard, 1: Upload, 2: Audit

  Widget getBody() {
    switch (_selectedIndex) {
      case 0:
        return const Center(child: Text("Dashboard coming soon!"));
      case 1:
        return UploadCertificatesScreen(
          userId: widget.userId,
          branches: widget.branches,
        );
      case 2:
        return const Center(child: Text("Audit Logs coming soon!"));
      default:
        return UploadCertificatesScreen(
          userId: widget.userId,
          branches: widget.branches,
        );
    }
  }

  Widget buildDrawer(BuildContext context, {bool isPermanent = false}) {
    return Drawer(
      child: ListView(
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Colors.deepPurple),
            child: Text(
              'Spaklean',
              style: TextStyle(color: Colors.white, fontSize: 24),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('Dashboard'),
            selected: _selectedIndex == 0,
            onTap: () {
              setState(() => _selectedIndex = 0);
              if (!isPermanent) Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.upload_file),
            title: const Text('Upload Certificates'),
            selected: _selectedIndex == 1,
            onTap: () {
              setState(() => _selectedIndex = 1);
              if (!isPermanent) Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('Audit Logs'),
            selected: _selectedIndex == 2,
            onTap: () {
              setState(() => _selectedIndex = 2);
              if (!isPermanent) Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 800;

        if (isDesktop) {
          // Desktop: permanent drawer
          return Scaffold(
            appBar: AppBar(title: const Text('Certification App')),
            body: Row(
              children: [
                SizedBox(
                  width: 250,
                  child: buildDrawer(context, isPermanent: true),
                ),
                const VerticalDivider(width: 1),
                Expanded(child: getBody()),
              ],
            ),
          );
        } else {
          // Mobile: collapsible drawer
          return Scaffold(
            appBar: AppBar(title: const Text('Certification App')),
            drawer: buildDrawer(context),
            body: getBody(),
          );
        }
      },
    );
  }
}
