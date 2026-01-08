import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});
  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  List notes = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetch();
  }

  Future<void> fetch() async {
    final api = Provider.of<ApiService>(context, listen:false);
    final res = await api.getNotifications();
    if (res['statusCode'] == 200) {
      setState(() {
        notes = res['body']['notifications'] ?? [];
        loading = false;
      });
    }
  }

  Future<void> markRead(int id) async {
    final api = Provider.of<ApiService>(context, listen:false);
    await api.markNotificationRead(id);
    fetch();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Notifications")),
      body: loading ? const Center(child: CircularProgressIndicator()) :
      ListView.builder(
        itemCount: notes.length,
        itemBuilder: (_, i) {
          final n = notes[i];
          return ListTile(
            title: Text(n['message'] ?? ''),
            subtitle: Text(n['created_at'] ?? ''),
            trailing: n['read'] ? null : TextButton(onPressed: ()=>markRead(n['id']), child: const Text("Mark read")),
          );
        }
      ),
    );
  }
}
