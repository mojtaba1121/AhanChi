import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers.dart';

class UsersScreen extends ConsumerStatefulWidget {
  const UsersScreen({super.key});
  @override
  ConsumerState<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends ConsumerState<UsersScreen> {
  late Future<List<Map<String, dynamic>>> future;
  @override
  void initState() { super.initState(); future = ref.read(repositoryProvider).api.list('/users'); }

  Future<void> add() async {
    final name = TextEditingController(); final phone = TextEditingController(); final password = TextEditingController(); final city = TextEditingController(); final village = TextEditingController();
    final ok = await showDialog<bool>(context: context, builder: (context) => AlertDialog(
      title: const Text('نماینده جدید'),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: name, decoration: const InputDecoration(labelText: 'نام کامل')),
        const SizedBox(height: 8), TextField(controller: phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'شماره موبایل')),
        const SizedBox(height: 8), TextField(controller: password, obscureText: true, decoration: const InputDecoration(labelText: 'رمز موقت')),
        const SizedBox(height: 8), TextField(controller: city, decoration: const InputDecoration(labelText: 'شهر')),
        const SizedBox(height: 8), TextField(controller: village, decoration: const InputDecoration(labelText: 'روستا')),
      ])),
      actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('انصراف')), FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('ایجاد'))],
    ));
    if (ok == true) {
      await ref.read(repositoryProvider).api.post('/users', {'fullName': name.text.trim(), 'phone': phone.text.trim(), 'password': password.text, 'role': 'REPRESENTATIVE', 'city': city.text.trim(), 'village': village.text.trim()});
      setState(() => future = ref.read(repositoryProvider).api.list('/users'));
    }
  }

  @override
  Widget build(BuildContext context) => Stack(children: [
    FutureBuilder<List<Map<String, dynamic>>>(future: future, builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
      if (snapshot.hasError) return Center(child: Text(snapshot.error.toString()));
      return ListView.builder(padding: const EdgeInsets.fromLTRB(12, 12, 12, 90), itemCount: snapshot.data!.length, itemBuilder: (_, index) {
        final user = snapshot.data![index];
        return Card(child: ListTile(
          leading: CircleAvatar(child: Text((user['fullName'] as String).substring(0, 1))),
          title: Text(user['fullName'] as String, style: const TextStyle(fontWeight: FontWeight.w700)),
          subtitle: Text('${user['phone']} • ${user['city'] ?? ''} ${user['village'] ?? ''}'),
          trailing: Chip(label: Text(user['role'] == 'REPRESENTATIVE' ? 'نماینده' : 'مدیر')),
        ));
      });
    }),
    Positioned(bottom: 18, left: 18, child: FloatingActionButton.extended(onPressed: add, icon: const Icon(Icons.person_add), label: const Text('نماینده جدید'))),
  ]);
}
