/*import 'package:digitopia_app/models/chat.dart';
import 'package:flutter/material.dart';

Widget _buildMessageBubbleFromMessage(Message msg) {
  final mine = msg.senderId == currentUserId;
  final timeStr =
      '${msg.sentAt.hour.toString().padLeft(2, '0')}:${msg.sentAt.minute.toString().padLeft(2, '0')}';

  return Align(
    alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
    child: Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
      decoration: BoxDecoration(
        color: mine ? const Color(0xFF6366F1) : Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (!mine && msg.senderName.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                msg.senderName,
                style: TextStyle(fontSize: 12, color: Colors.grey[700], fontWeight: FontWeight.w600),
              ),
            ),
          Text(
            msg.text,
            style: TextStyle(color: mine ? Colors.white : Colors.black87, fontSize: 15),
          ),
          const SizedBox(height: 6),
          Text(timeStr, style: TextStyle(fontSize: 11, color: mine ? Colors.white70 : Colors.grey[600])),
        ],
      ),
    ),
  );
}*/
