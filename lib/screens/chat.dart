import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../core/widgets.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final List<List<String>> chats = [
    ['ZenjiGO Support', 'How can we help you today?', 'Pinned'],
    ['Asha Salim', 'I am near the entrance.', '2'],
    ['Juma Omar', 'Thank you for the ride!', '1'],
    ['Fatma Said', 'Okay, I see your car.', ''],
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Messages',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ),
                IconButton.filledTonal(
                  onPressed: () => toast(
                    context,
                    'New chats begin automatically from rides or ZenjiGO support.',
                  ),
                  icon: const Icon(Icons.edit_square),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 18),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search chats',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.builder(
              itemCount: chats.length,
              itemBuilder: (context, index) {
                final chat = chats[index];
                final isSupport = index == 0;
                return Dismissible(
                  key: ValueKey(chat[0]),
                  direction: isSupport
                      ? DismissDirection.none
                      : DismissDirection.endToStart,
                  confirmDismiss: (_) => confirmDialog(
                    context,
                    title: 'Delete chat?',
                    message:
                        'This removes the conversation from this device. ZenjiGO Support cannot be deleted.',
                    confirm: 'Delete',
                  ),
                  background: Container(
                    color: Colors.redAccent,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 24),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (_) => setState(() => chats.removeAt(index)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 7,
                    ),
                    leading: CircleAvatar(
                      radius: 27,
                      backgroundColor: isSupport
                          ? ZenjiColors.green.withValues(alpha: .14)
                          : null,
                      child: Icon(
                        isSupport ? Icons.support_agent : Icons.person,
                        color: isSupport ? ZenjiColors.green : null,
                      ),
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            chat[0],
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ),
                        if (isSupport)
                          const Icon(
                            Icons.push_pin,
                            size: 15,
                            color: ZenjiColors.green,
                          ),
                      ],
                    ),
                    subtitle: Text(
                      chat[1],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: chat[2].isEmpty
                        ? const Text('18:42', style: TextStyle(fontSize: 11))
                        : chat[2] == 'Pinned'
                            ? const Text('Now', style: TextStyle(fontSize: 11))
                            : Badge(label: Text(chat[2])),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatScreen(
                          name: chat[0],
                          support: isSupport,
                        ),
                      ),
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

class ChatScreen extends StatefulWidget {
  final String name;
  final bool support;

  const ChatScreen({
    super.key,
    required this.name,
    required this.support,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  bool translate = false;
  final TextEditingController controller = TextEditingController();
  int? selected;

  final List<Map<String, dynamic>> messages = [
    {
      'mine': false,
      'text': 'Hello! I am ready at the pickup point.',
      'time': '18:30',
    },
    {
      'mine': true,
      'text': 'Great, I am 2 minutes away.',
      'time': '18:31',
    },
    {
      'mine': false,
      'text': 'Okay, I can see the ZenjiGO vehicle.',
      'time': '18:33',
    },
  ];

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              child: Icon(widget.support ? Icons.support_agent : Icons.person),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    widget.support ? 'Official ZenjiGO support' : 'Rider • online',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Translate', style: TextStyle(fontSize: 10)),
              SizedBox(
                height: 26,
                child: Switch(
                  value: translate,
                  onChanged: (value) => setState(() => translate = value),
                ),
              ),
            ],
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'delete' && !widget.support) {
                confirmDialog(
                  context,
                  title: 'Delete entire chat?',
                  message: 'This removes the conversation from your chat list.',
                  confirm: 'Delete',
                ).then((ok) {
                  if (ok == true && context.mounted) {
                    Navigator.pop(context);
                    toast(context, 'Chat deleted');
                  }
                });
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'media',
                child: Text('Shared media'),
              ),
              PopupMenuItem(
                value: 'delete',
                enabled: !widget.support,
                child: Text(
                  widget.support
                      ? 'ZenjiGO Support cannot be deleted'
                      : 'Delete chat',
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          if (translate)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              color: Theme.of(context).colorScheme.primary.withValues(alpha: .1),
              child: const Text(
                'Auto-translate enabled: English ⇄ Swahili',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(14),
              itemCount: messages.length,
              itemBuilder: (context, index) => _bubble(index),
            ),
          ),
          _composer(),
        ],
      ),
    );
  }

  Widget _bubble(int index) {
    final message = messages[index];
    final mine = message['mine'] as bool;
    final isSelected = selected == index;

    return GestureDetector(
      onLongPress: () => setState(() => selected = index),
      onTap: () => setState(() => selected = null),
      child: Align(
        alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 330),
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.fromLTRB(12, 9, 9, 6),
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).colorScheme.secondary.withValues(alpha: .35)
                : mine
                    ? ZenjiColors.green.withValues(alpha: .22)
                    : Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(mine ? 16 : 4),
              bottomRight: Radius.circular(mine ? 4 : 16),
            ),
            border: isSelected
                ? Border.all(color: Theme.of(context).colorScheme.secondary)
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isSelected)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (mine)
                      IconButton(
                        onPressed: () => _edit(index),
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.edit, size: 17),
                      ),
                    IconButton(
                      onPressed: () => _reply(index),
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.reply, size: 17),
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          messages.removeAt(index);
                          selected = null;
                        });
                      },
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.delete_outline, size: 17),
                    ),
                  ],
                ),
              Text(
                translate
                    ? _translate(message['text'] as String)
                    : message['text'] as String,
                style: const TextStyle(height: 1.35),
              ),
              const SizedBox(height: 3),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    message['time'] as String,
                    style: TextStyle(
                      fontSize: 9,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: .55),
                    ),
                  ),
                  if (mine) ...[
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.done_all,
                      size: 13,
                      color: ZenjiColors.skyBlue,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _composer() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 7, 10, 10),
        child: Row(
          children: [
            IconButton(
              onPressed: () => toast(context, 'Emoji picker integration point'),
              icon: const Icon(Icons.emoji_emotions_outlined),
            ),
            Expanded(
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Message',
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 10,
                  ),
                ),
              ),
            ),
            IconButton(
              onPressed: () => toast(context, 'Attachment picker ready'),
              icon: const Icon(Icons.attach_file),
            ),
            const SizedBox(width: 4),
            IconButton.filled(
              onPressed: _send,
              icon: const Icon(Icons.send_rounded),
            ),
          ],
        ),
      ),
    );
  }

  void _send() {
    final text = controller.text.trim();
    if (text.isEmpty) return;
    setState(() {
      messages.add({'mine': true, 'text': text, 'time': 'Now'});
    });
    controller.clear();
  }

  void _edit(int index) {
    final editController = TextEditingController(
      text: messages[index]['text'] as String,
    );
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit message'),
        content: TextField(controller: editController, maxLines: 4),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final value = editController.text.trim();
              if (value.isNotEmpty) {
                setState(() {
                  messages[index]['text'] = value;
                  selected = null;
                });
              }
              Navigator.pop(dialogContext);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _reply(int index) {
    controller.text = '↪ ${messages[index]['text']}\n';
    controller.selection = TextSelection.collapsed(offset: controller.text.length);
    setState(() => selected = null);
  }

  String _translate(String source) {
    if (source.startsWith('Hello')) {
      return 'Habari! Niko tayari kwenye eneo la kuchukuliwa.';
    }
    if (source.startsWith('Great')) {
      return 'Vizuri, nitafika baada ya dakika 2.';
    }
    if (source.startsWith('Okay')) {
      return 'Sawa, ninaiona gari ya ZenjiGO.';
    }
    return source;
  }
}
