import 'package:flutter/material.dart';
import '../../utils/backup.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ListTile(
          leading: const Icon(Icons.backup_outlined),
          title: const Text('Backup data'),
          subtitle: const Text(
            'Export to a JSON file and share (Drive supported).',
          ),
          onTap: () async {
            final path = await BackupUtils.exportAll();
            if (context.mounted) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('Exported: $path')));
            }
          },
        ),
        ListTile(
          leading: const Icon(Icons.restore_outlined),
          title: const Text('Import data'),
          subtitle: const Text('Restore from a JSON backup file.'),
          onTap: () async {
            final count = await BackupUtils.importAll();
            if (context.mounted) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('Imported $count items')));
            }
          },
        ),
        const Divider(),
        const ListTile(
          title: Text('Design'),
          subtitle: Text(
            'Calm theme with soft palette and minimal distractions.',
          ),
        ),
      ],
    );
  }
}
