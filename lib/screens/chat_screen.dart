import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/chat_panel.dart';

/// Full-screen chat thread for a request — opened by tapping the message
/// bar preview on the request detail screen. This is where the actual
/// conversation with admin happens (message list + input), keeping the
/// request detail screen itself compact.
class ChatScreen extends StatelessWidget {
  final String chassisNumber;
  final String userId;
  final bool autofocus;

  const ChatScreen({
    super.key,
    required this.chassisNumber,
    required this.userId,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
        title: Text(
          chassisNumber,
          style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        child: ChatPanel(
          chassisNumber: chassisNumber,
          userId: userId,
          autofocus: autofocus,
        ),
      ),
    );
  }
}