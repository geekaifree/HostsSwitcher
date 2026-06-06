import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() => runApp(const HostsSwitcherApp());
class HostsSwitcherApp extends StatelessWidget {
  const HostsSwitcherApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(title: 'Hosts切换器', debugShowCheckedModeBanner: false,
    theme: ThemeData(colorSchemeSeed: Colors.brown, useMaterial3: true, brightness: Brightness.light),
    darkTheme: ThemeData(colorSchemeSeed: Colors.brown, useMaterial3: true, brightness: Brightness.dark),
    home: const HostsHomePage());
}

class HostsProfile {
  String id, name, content;
  bool active;
  HostsProfile({required this.id, required this.name, required this.content, this.active = false});
  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'content': content, 'active': active};
  factory HostsProfile.fromJson(Map<String, dynamic> j) => HostsProfile(id: j['id'], name: j['name'], content: j['content'], active: j['active'] ?? false);
}

class HostsHomePage extends StatefulWidget {
  const HostsHomePage({super.key});
  @override
  State<HostsHomePage> setState() => _HostsHomePageState();
}

class _HostsHomePageState extends State<HostsHomePage> {
  List<HostsProfile> _profiles = [];
  final _editCtrl = TextEditingController();

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    final d = p.getString('hosts_profiles');
    if (d != null) { setState(() => _profiles = (json.decode(d) as List).map((e) => HostsProfile.fromJson(e)).toList()); }
    else { _profiles = [
      HostsProfile(id: '1', name: '默认', content: '127.0.0.1 localhost\n255.255.255.255 broadcasthost\n::1 localhost', active: true),
      HostsProfile(id: '2', name: '开发环境', content: '127.0.0.1 localhost\n192.168.1.100 dev.example.com\n192.168.1.101 api.example.com\n10.0.0.50 db.example.com'),
      HostsProfile(id: '3', name: '测试环境', content: '127.0.0.1 localhost\n10.0.1.100 test.example.com\n10.0.1.101 test-api.example.com'),
    ]; _save(); }
  }

  Future<void> _save() async {
    final p = await SharedPreferences.getInstance();
    await p.setString('hosts_profiles', json.encode(_profiles.map((e) => e.toJson()).toList()));
  }

  void _activate(HostsProfile profile) {
    setState(() { for (var p in _profiles) { p.active = p.id == profile.id; } });
    _save();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('已切换到: ${profile.name}'), behavior: SnackBarBehavior.floating));
  }

  void _edit(HostsProfile profile) {
    _editCtrl.text = profile.content;
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: Text('编辑: ${profile.name}'),
      content: SizedBox(width: double.maxFinite, child: TextField(controller: _editCtrl, maxLines: 15, style: const TextStyle(fontFamily: 'monospace', fontSize: 12), decoration: const InputDecoration(border: OutlineInputBorder()))),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')), FilledButton(onPressed: () { setState(() => profile.content = _editCtrl.text); _save(); Navigator.pop(ctx); }, child: const Text('保存'))],
    ));
  }

  void _add() {
    final nameC = TextEditingController();
    final contentC = TextEditingController(text: '127.0.0.1 localhost\n');
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('新建配置'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: nameC, decoration: const InputDecoration(labelText: '配置名称', border: OutlineInputBorder())),
        const SizedBox(height: 12),
        TextField(controller: contentC, maxLines: 8, style: const TextStyle(fontFamily: 'monospace', fontSize: 12), decoration: const InputDecoration(labelText: 'Hosts内容', border: OutlineInputBorder())),
      ]),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')), FilledButton(onPressed: () { if (nameC.text.isNotEmpty) { setState(() => _profiles.add(HostsProfile(id: DateTime.now().millisecondsSinceEpoch.toString(), name: nameC.text, content: contentC.text))); _save(); } Navigator.pop(ctx); }, child: const Text('创建'))],
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('🔄 Hosts切换器'), centerTitle: true, actions: [IconButton(icon: const Icon(Icons.add), onPressed: _add)]),
      body: _profiles.isEmpty ? const Center(child: Text('点击 + 创建配置')) : ListView.builder(padding: const EdgeInsets.all(12), itemCount: _profiles.length, itemBuilder: (ctx, i) {
        final p = _profiles[i];
        return Card(color: p.active ? Colors.brown.shade50 : null, margin: const EdgeInsets.only(bottom: 12), child: ExpansionTile(
          leading: Icon(p.active ? Icons.check_circle : Icons.circle_outlined, color: p.active ? Colors.green : Colors.grey),
          title: Text(p.name, style: TextStyle(fontWeight: FontWeight.bold, color: p.active ? Colors.brown : null)),
          subtitle: Text('${p.content.split('\n').length} 条记录', style: const TextStyle(fontSize: 12)),
          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
            IconButton(icon: const Icon(Icons.edit, size: 20), onPressed: () => _edit(p), tooltip: '编辑'),
            IconButton(icon: Icon(p.active ? Icons.check : Icons.play_arrow, color: p.active ? Colors.green : null, size: 20), onPressed: p.active ? null : () => _activate(p), tooltip: '激活'),
            IconButton(icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red), onPressed: p.active ? null : () { setState(() => _profiles.removeAt(i)); _save(); }),
          ]),
          children: [Container(width: double.infinity, padding: const EdgeInsets.all(12), color: Colors.grey.shade100, child: Text(p.content, style: const TextStyle(fontFamily: 'monospace', fontSize: 12)))],
        ));
      }),
    );
  }
}
