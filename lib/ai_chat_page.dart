import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AiChatPage extends StatefulWidget {
  const AiChatPage({super.key});

  @override
  State<AiChatPage> createState() => _AiChatPageState();
}

class _AiChatPageState extends State<AiChatPage>
    with AutomaticKeepAliveClientMixin {
  final TextEditingController _messageCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();

  final List<_ChatMessage> _messages = [
    const _ChatMessage(
      text:
          "Hi! I'm your AI expense assistant.\n\nYou can ask me things like:\n"
          "• Help me build a budget\n"
          "• How can I save money?\n"
          "• Categorize my spending\n"
          "• Give me tips for reducing food expenses",
      isUser: false,
    ),
  ];

  bool _isTyping = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _messageCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _messageCtrl.text.trim();
    if (text.isEmpty) return;

    HapticFeedback.selectionClick();

    setState(() {
      _messages.add(_ChatMessage(text: text, isUser: true));
      _isTyping = true;
    });

    _messageCtrl.clear();
    _scrollToBottom();

    await Future.delayed(const Duration(milliseconds: 700));

    final reply = _generateBotReply(text);

    if (!mounted) return;

    setState(() {
      _messages.add(_ChatMessage(text: reply, isUser: false));
      _isTyping = false;
    });

    _scrollToBottom();
  }

  String _generateBotReply(String input) {
    final msg = input.toLowerCase();

    if (msg.contains('budget')) {
      return "A simple budget rule is 50/30/20:\n\n"
          "• 50% for needs\n"
          "• 30% for wants\n"
          "• 20% for savings\n\n"
          "You can customize this based on your income and bills.";
    }

    if (msg.contains('save') || msg.contains('saving')) {
      return "To save more money, start by tracking your highest spending category first. "
          "Food delivery, entertainment, and impulse shopping are usually good places to cut back.";
    }

    if (msg.contains('food')) {
      return "Food expenses can be reduced by meal prepping, limiting takeout, and setting a weekly food cap.";
    }

    if (msg.contains('transport')) {
      return "For transport expenses, try comparing monthly transit costs with ride-share or taxi usage. "
          "That usually shows where money is leaking.";
    }

    if (msg.contains('bills')) {
      return "For bills, it helps to keep them in a fixed category and review recurring payments once a month.";
    }

    if (msg.contains('location')) {
      return "Adding a location to expenses is useful for map-based spending insights, store-based tracking, "
          "and seeing where your money is being spent most often.";
    }

    if (msg.contains('hello') || msg.contains('hi')) {
      return "Hey! Ask me anything about budgets, spending habits, or expense categories.";
    }

    return "I can help with budgeting, saving tips, expense categories, and spending habits. "
        "Try asking me something like: 'How can I reduce food spending?'";
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Widget _buildBubble({
    required BuildContext context,
    required _ChatMessage message,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final isUser = message.isUser;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        decoration: BoxDecoration(
          color: isUser
              ? scheme.primaryContainer
              : scheme.surfaceContainerHighest.withOpacity(0.75),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          message.text,
          style: TextStyle(
            color: isUser ? scheme.onPrimaryContainer : scheme.onSurface,
            height: 1.4,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final scheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Expanded(
          child: ListView(
            controller: _scrollCtrl,
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "AI Expense Assistant",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: scheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Ask questions about budgeting, saving money, spending habits, and expense categories.",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              ..._messages.map((message) {
                return _buildBubble(
                  context: context,
                  message: message,
                );
              }),
              if (_isTyping)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHighest.withOpacity(0.75),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      "Typing...",
                      style: TextStyle(
                        color: scheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageCtrl,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                    decoration: const InputDecoration(
                      hintText: "Ask the AI something...",
                      prefixIcon: Icon(Icons.smart_toy_outlined),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton.filled(
                  onPressed: _sendMessage,
                  icon: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ChatMessage {
  final String text;
  final bool isUser;

  const _ChatMessage({
    required this.text,
    required this.isUser,
  });
}