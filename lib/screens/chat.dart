import 'dart:async';
import 'package:flutter/material.dart';
import '../core/api/driver_api.dart';
import '../core/theme.dart';
import '../core/widgets.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});
  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  List<Map<String, dynamic>> chats = [];
  bool loading = true;
  String? error;
  final search = TextEditingController();

  @override
  void initState() { super.initState(); _load(); }
  @override
  void dispose() { search.dispose(); super.dispose(); }

  Future<void> _load() async {
    if (mounted) setState(() { loading = true; error = null; });
    try {
      final list = await DriverApi.conversations();
      if (!mounted) return;
      setState(() {
        chats = list.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
        loading = false;
      });
    } catch (e) {
      if (mounted) setState(() { error = e.toString().replaceFirst('Exception: ', ''); loading = false; });
    }
  }

  Future<void> _openSupport() async {
    try {
      final c = await DriverApi.openSupport();
      final id = (c['conversationId'] ?? c['id'] ?? '').toString();
      if (id.isEmpty) throw Exception('Server did not return a support conversation ID.');
      if (!mounted) return;
      await Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(
        name: 'ZenjiGO Support', support: true, conversationId: id)));
      _load();
    } catch (e) { if (mounted) toast(context, e.toString().replaceFirst('Exception: ', '')); }
  }

  @override
  Widget build(BuildContext context) {
    final q = search.text.trim().toLowerCase();
    final filtered = chats.where((c) {
      final title = (c['title'] ?? c['peerName'] ?? c['type'] ?? 'Chat').toString().toLowerCase();
      final preview = (c['lastMessage'] ?? c['last_message'] ?? '').toString().toLowerCase();
      return q.isEmpty || title.contains(q) || preview.contains(q);
    }).toList();
    return SafeArea(child: Column(children: [
      Padding(padding: const EdgeInsets.fromLTRB(18, 14, 10, 10), child: Row(children: [
        Expanded(child: Text('Messages', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900))),
        IconButton.filledTonal(onPressed: _openSupport, icon: const Icon(Icons.support_agent), tooltip: 'Contact support'),
        IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
      ])),
      Padding(padding: const EdgeInsets.symmetric(horizontal: 18), child: TextField(
        controller: search, onChanged: (_) => setState(() {}),
        decoration: const InputDecoration(hintText: 'Search conversations', prefixIcon: Icon(Icons.search)))),
      const SizedBox(height: 8),
      if (loading) const LinearProgressIndicator(),
      if (error != null) Padding(padding: const EdgeInsets.all(16), child: Column(children: [
        const Icon(Icons.cloud_off_outlined), const SizedBox(height: 8), Text(error!, textAlign: TextAlign.center),
        TextButton.icon(onPressed: _load, icon: const Icon(Icons.refresh), label: const Text('Retry')),
      ])),
      Expanded(child: filtered.isEmpty && !loading && error == null
        ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.forum_outlined, size: 44), const SizedBox(height: 12),
            const Text('No conversations yet', style: TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 6), const Text('Ride chats appear when available. Contact support to start a support conversation.', textAlign: TextAlign.center),
            const SizedBox(height: 12), FilledButton.icon(onPressed: _openSupport, icon: const Icon(Icons.support_agent), label: const Text('Contact support')),
          ])))
        : ListView.builder(itemCount: filtered.length, itemBuilder: (context, index) {
          final c = filtered[index];
          final id = (c['id'] ?? c['conversationId'] ?? '').toString();
          final title = (c['title'] ?? c['peerName'] ?? (c['type'] == 'support' ? 'ZenjiGO Support' : 'Ride chat')).toString();
          final preview = (c['lastMessage'] ?? c['last_message'] ?? '').toString();
          final support = c['type'] == 'support' || title.toLowerCase().contains('support');
          final unread = int.tryParse((c['unreadCount'] ?? c['unread_count'] ?? 0).toString()) ?? 0;
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
            leading: CircleAvatar(backgroundColor: support ? ZenjiColors.green.withValues(alpha: .14) : null,
              child: Icon(support ? Icons.support_agent : Icons.person, color: support ? ZenjiColors.green : null)),
            title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
            subtitle: Text(preview.isEmpty ? 'No messages yet' : preview, maxLines: 1, overflow: TextOverflow.ellipsis),
            trailing: unread > 0 ? Badge(label: Text('$unread')) : null,
            onTap: id.isEmpty ? null : () async {
              await Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(name: title, support: support, conversationId: id)));
              _load();
            },
          );
        })),
    ]));
  }
}

class ChatScreen extends StatefulWidget {
  final String name;
  final bool support;
  final String? conversationId;
  const ChatScreen({super.key, required this.name, required this.support, this.conversationId});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController controller = TextEditingController();
  final ScrollController scroll = ScrollController();
  List<Map<String, dynamic>> messages = [];
  String? conversationId;
  String? error;
  bool loading = true;
  bool sending = false;
  Timer? poller;

  @override
  void initState() {
    super.initState();
    conversationId = widget.conversationId;
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      if ((conversationId == null || conversationId!.isEmpty) && widget.support) {
        final c = await DriverApi.openSupport();
        conversationId = (c['conversationId'] ?? c['id'])?.toString();
      }
      if (conversationId == null || conversationId!.isEmpty) {
        throw Exception('This conversation has no server ID.');
      }
      await _loadMessages();
      poller = Timer.periodic(const Duration(seconds: 8), (_) => _loadMessages(silent: true));
    } catch (e) {
      if (mounted) setState(() { error = e.toString().replaceFirst('Exception: ', ''); loading = false; });
    }
  }

  Future<void> _loadMessages({bool silent = false}) async {
    final id = conversationId;
    if (id == null) return;
    try {
      final rows = await DriverApi.messages(id);
      await DriverApi.markRead(id);
      if (!mounted) return;
      setState(() {
        messages = rows.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
        loading = false;
        error = null;
      });
      if (!silent && scroll.hasClients) scroll.jumpTo(scroll.position.maxScrollExtent);
    } catch (e) {
      if (mounted) setState(() { if (!silent) error = e.toString().replaceFirst('Exception: ', ''); loading = false; });
    }
  }

  Future<void> _send() async {
    final text = controller.text.trim();
    final id = conversationId;
    if (text.isEmpty || id == null || sending) return;
    setState(() => sending = true);
    try {
      await DriverApi.sendMessage(id, text);
      controller.clear();
      await _loadMessages();
    } catch (e) {
      if (mounted) toast(context, e.toString().replaceFirst('Exception: ', ''));
    } finally { if (mounted) setState(() => sending = false); }
  }

  @override
  void dispose() { poller?.cancel(); controller.dispose(); scroll.dispose(); super.dispose(); }

  String _time(dynamic value) {
    if (value == null) return '';
    final d = DateTime.tryParse(value.toString());
    if (d == null) return value.toString();
    return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Row(children: [
        CircleAvatar(child: Icon(widget.support ? Icons.support_agent : Icons.person)),
        const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(widget.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
          Text(widget.support ? 'ZenjiGO Support' : 'Ride conversation', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.normal)),
        ])),
      ]), actions: [IconButton(onPressed: () => _loadMessages(), icon: const Icon(Icons.refresh))]),
      body: Column(children: [
        if (loading) const LinearProgressIndicator(),
        if (error != null) Padding(padding: const EdgeInsets.all(12), child: Text(error!, textAlign: TextAlign.center)),
        Expanded(child: messages.isEmpty && !loading
          ? const Center(child: Text('No messages yet. Send a message to start the conversation.'))
          : ListView.builder(controller: scroll, padding: const EdgeInsets.all(14), itemCount: messages.length, itemBuilder: (context, index) {
            final m = messages[index];
            final mine = m['isMine'] == true || m['mine'] == true;
            final body = (m['text'] ?? '').toString();
            return Align(alignment: mine ? Alignment.centerRight : Alignment.centerLeft, child: Container(
              constraints: const BoxConstraints(maxWidth: 330),
              margin: const EdgeInsets.symmetric(vertical: 4), padding: const EdgeInsets.fromLTRB(12, 9, 12, 7),
              decoration: BoxDecoration(color: mine ? ZenjiColors.green.withValues(alpha: .22) : Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.only(topLeft: const Radius.circular(16), topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(mine ? 16 : 4), bottomRight: Radius.circular(mine ? 4 : 16))),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(body, style: const TextStyle(height: 1.35)),
                const SizedBox(height: 3), Text(_time(m['createdAt'] ?? m['created_at']), style: TextStyle(fontSize: 9, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .55))),
              ]),
            ));
          })),
        SafeArea(top: false, child: Padding(padding: const EdgeInsets.fromLTRB(10, 7, 10, 10), child: Row(children: [
          Expanded(child: TextField(controller: controller, minLines: 1, maxLines: 4, textInputAction: TextInputAction.send,
            onSubmitted: (_) => _send(), decoration: const InputDecoration(hintText: 'Message...', prefixIcon: Icon(Icons.chat_bubble_outline)))),
          const SizedBox(width: 8),
          IconButton.filled(onPressed: sending ? null : _send, icon: sending ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.send)),
        ]))),
      ]),
    );
  }
}
