import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/message_model.dart';
import '../utils/constants.dart';

class MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isSent;

  const MessageBubble({super.key, required this.message, required this.isSent});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      child: Column(
        crossAxisAlignment: isSent
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: isSent ? AppColors.primary : (isDark ? AppColors.darkSurface : Colors.grey[200]),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: isSent ? const Radius.circular(16) : Radius.zero,
                bottomRight: isSent ? Radius.zero : const Radius.circular(16),
              ),
            ),
            child: Text(
              message.text,
              style: TextStyle(
                color: isSent ? Colors.white : (isDark ? Colors.white : Colors.black87),
                fontSize: 15,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                DateFormat('jm').format(message.timestamp), // e.g., 5:30 PM
                style: TextStyle(color: isDark ? Colors.white54 : Colors.grey[600], fontSize: 10),
              ),
              if (isSent) ...[
                const SizedBox(width: 4),
                Icon(
                  message.isRead ? Icons.done_all : Icons.check,
                  size: 14,
                  color: message.isRead ? AppColors.secondary : Colors.grey,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

