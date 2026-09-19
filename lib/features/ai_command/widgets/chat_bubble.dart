import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

import 'package:omnibrain_ai/core/constants/app_colors.dart';
import 'package:omnibrain_ai/core/models/chat_message.dart';

class ChatBubble extends StatelessWidget {
  final ChatMessage message;

  const ChatBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == MessageRole.user;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            _buildAvatar(isUser: false),
            const SizedBox(width: 8),
          ],
          
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser ? AppColors.neonPurple.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isUser ? 20 : 0),
                  bottomRight: Radius.circular(isUser ? 0 : 20),
                ),
                border: Border.all(
                  color: isUser ? AppColors.neonPurple.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.1),
                ),
              ),
              child: message.isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 40,
                      child: Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.neonPurple,
                        ),
                      ),
                    )
                  : message.isError
                      ? Text(
                          message.text,
                          style: GoogleFonts.inter(color: AppColors.coralRed, fontSize: 15),
                        )
                      : isUser
                          ? Text(
                              message.text,
                              style: GoogleFonts.inter(color: Colors.white, fontSize: 15),
                            )
                          : MarkdownBody(
                              data: message.text,
                              styleSheet: MarkdownStyleSheet(
                                p: GoogleFonts.inter(color: Colors.white, fontSize: 15),
                                h1: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.bold),
                                h2: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.bold),
                                h3: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.bold),
                                strong: GoogleFonts.inter(color: AppColors.amber, fontWeight: FontWeight.bold),
                                em: GoogleFonts.inter(color: Colors.white70, fontStyle: FontStyle.italic),
                                code: GoogleFonts.firaCode(
                                  backgroundColor: Colors.black45,
                                  color: AppColors.iceBlue,
                                ),
                                codeblockDecoration: BoxDecoration(
                                  color: Colors.black45,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
            ),
          ),
          
          if (isUser) ...[
            const SizedBox(width: 8),
            _buildAvatar(isUser: true),
          ]
        ],
      ),
    );
  }

  Widget _buildAvatar({required bool isUser}) {
    if (isUser) {
      return const CircleAvatar(
        radius: 16,
        backgroundColor: AppColors.neonPurple,
        child: Icon(Icons.person, size: 18, color: Colors.white),
      );
    } else {
      return Container(
        width: 32,
        height: 32,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [AppColors.neonPurple, AppColors.iceBlue],
          ),
        ),
        child: const Icon(Icons.auto_awesome, size: 18, color: Colors.white),
      );
    }
  }
}
