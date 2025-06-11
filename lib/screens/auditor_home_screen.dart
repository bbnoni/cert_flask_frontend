import 'package:flutter/material.dart';

import 'audit_summary_screen.dart';

class AuditorHomeScreen extends StatefulWidget {
  const AuditorHomeScreen({super.key});

  @override
  State<AuditorHomeScreen> createState() => _AuditorHomeScreenState();
}

class _AuditorHomeScreenState extends State<AuditorHomeScreen> {
  int _selectedIndex = 1; // 0: Dashboard, 1: View Certificates, 2: Audit Logs

  Widget getBody() {
    switch (_selectedIndex) {
      case 0:
        return const Center(child: Text("Dashboard coming soon!"));
      case 1:
        return const AuditSummaryScreen();
      case 2:
        return const Center(child: Text("Audit Logs coming soon!"));
      default:
        return const AuditSummaryScreen();
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
            leading: const Icon(Icons.remove_red_eye),
            title: const Text('View Certificates'),
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
          return Scaffold(
            appBar: AppBar(title: const Text('Audit Portal')),
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
          return Scaffold(
            appBar: AppBar(title: const Text('Audit Portal')),
            drawer: buildDrawer(context),
            body: getBody(),
          );
        }
      },
    );
  }
}
