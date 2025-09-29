import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  Color get bg => const Color(0xFF0F0F12);
  Color get card => const Color(0xFF232326);
  Color get muted => const Color(0xFF9A9AA0);

  final List<ChatMessage> messages = [
    ChatMessage(
      text: "Hello! I'm your Privacy Assistant. How can I help you today?",
      isUser: false,
      timeLabel: 'Just now',
    ),
    ChatMessage(
      text: 'Suggest me the best protocol for speed',
      isUser: true,
      timeLabel: '2 min ago',
    ),
    ChatMessage(
      text:
          'WireGuard is the fastest and most recommended protocol for high-speed connections',
      isUser: false,
      timeLabel: '1 min ago',
      speedRating: '95/100',
    ),
    ChatMessage(
      text: "Thanks! Can you also check my privacy score?",
      isUser: true,
      timeLabel: '30 sec ago',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                children: [
                  InkWell(
                    onTap: () => Navigator.maybePop(context),
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: card,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Ai Assistant',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.daysOne(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),

            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final m = messages[index];
                  return MessageBubble(message: m, card: card, muted: muted);
                },
              ),
            ),
            // Quick actions pinned above composer
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 6),
              child: QuickActionsRow(card: card, muted: muted),
            ),
            Composer(
              bg: bg,
              card: card,
              onSend: () {
                final text = _controller.text.trim();
                if (text.isEmpty) return;
                setState(() {
                  messages.add(
                    ChatMessage(text: text, isUser: true, timeLabel: 'now'),
                  );
                  _controller.clear();
                });
                scrollToEnd();
              },
              controller: _controller,
            ),
          ],
        ),
      ),
    );
  }

  void scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 120,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final String timeLabel;
  final String? speedRating;
  const ChatMessage({
    required this.text,
    required this.isUser,
    required this.timeLabel,
    this.speedRating,
  });
}

class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.message,
    required this.card,
    required this.muted,
  });
  final ChatMessage message;
  final Color card;
  final Color muted;

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final bubble = Container(
      constraints: const BoxConstraints(maxWidth: 560),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isUser ? null : card,
        gradient: isUser
            ? const LinearGradient(
                colors: [Color(0xFF35C8FF), Color(0xFFB84DFF)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              )
            : null,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(20),
          topRight: const Radius.circular(20),
          bottomLeft: Radius.circular(isUser ? 20 : 8),
          bottomRight: Radius.circular(isUser ? 8 : 20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message.text,
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              height: 1.4,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (!isUser && message.speedRating != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  'Speed Rating',
                  style: GoogleFonts.inter(color: Colors.white70),
                ),
                const Spacer(),
                Text(
                  message.speedRating!,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: isUser
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: isUser
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            children: [
              if (!isUser) const AssistantAvatar(),
              if (!isUser) const SizedBox(width: 12),
              Flexible(child: bubble),
              if (isUser) const SizedBox(width: 12),
            ],
          ),
          const SizedBox(height: 6),
          Padding(
            padding: EdgeInsets.only(
              left: isUser ? 0 : 52.0,
              right: isUser ? 0 : 0,
            ),
            child: Text(
              message.timeLabel,
              style: GoogleFonts.inter(color: muted, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class AssistantAvatar extends StatelessWidget {
  const AssistantAvatar({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [Color(0xFF35C8FF), Color(0xFFB84DFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Image.asset(
          'assets/images/brain.png',
          width: 20,
          height: 20,
          color: Colors.white,
        ),
      ),
    );
  }
}

// Typing row removed

class QuickActionsRow extends StatelessWidget {
  const QuickActionsRow({super.key, required this.card, required this.muted});
  final Color card;
  final Color muted;
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: const [
          QuickChip(image: 'assets/images/privacyscan.png', label: 'Privacy Scan'),
          SizedBox(width: 12),
          QuickChip(image: 'assets/images/bestserver.png', label: 'Best Server'),
          SizedBox(width: 12),
          QuickChip(image: 'assets/images/usagestatistics.png', label: 'Usage Stats'),
        ],
      ),
    );
  }
}

class QuickChip extends StatelessWidget {
  final String image;
  final String label;

  const QuickChip({super.key, required this.image, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF232326),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
            Image(
            image: AssetImage(image),
            width: 20,
            height: 20,
            ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

class Composer extends StatelessWidget {
  const Composer({
    super.key,
    required this.bg,
    required this.card,
    required this.onSend,
    required this.controller,
  });

  final Color bg;
  final Color card;
  final VoidCallback onSend;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Color(0xFF252525),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Divider(color: Colors.white.withValues(alpha: 0.06), height: 1),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      color: card,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            maxLines: 1,
                            controller: controller,
                            style: TextStyle(color: Colors.white, fontSize: 14),
                            cursorColor: Colors.white70,
                            decoration: const InputDecoration(
                              isCollapsed: true,
                              hintText: 'Type your message...',
                              hintStyle: TextStyle(color: Color(0xFF9A9AA0)),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        const Icon(EvaIcons.mic, color: Colors.white70),
                        const SizedBox(width: 4),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: onSend,
                  child: Container(
                    width: 45,
                    height: 45,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6C63FF), Color(0xFFB84DFF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6C63FF).withOpacity(0.35),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Image.asset(
                        "assets/images/send.png",
                        scale: 3,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
