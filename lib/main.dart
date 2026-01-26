import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'widgets/chat/chat_screen.dart';

void main() {
  runApp(
    const ProviderScope(
      child: GLMChatApp(),
    ),
  );
}

class GLMChatApp extends StatelessWidget {
  const GLMChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GLM Chat',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const ChatScreen(),
    );
  }
}
