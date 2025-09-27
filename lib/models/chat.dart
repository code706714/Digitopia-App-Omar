// lib/models/message.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String id;
  final String text;
  final String senderId;
  final String senderName;
  final DateTime sentAt;

  Message({
    required this.id,
    required this.text,
    required this.senderId,
    required this.senderName,
    required this.sentAt,
  });

  // ازاى نبني من JSON مع حماية من القيم null و أنواع مختلفة
  factory Message.fromJson(Map<String, dynamic> json, {String? id}) {
    final text = (json['text'] ?? '').toString();
    final senderId = (json['senderId'] ?? '').toString();
    final senderName = (json['senderName'] ?? '').toString();

    // sentAt ممكن يكون Timestamp أو int أو String أو null
    DateTime sentAt;
    final sentAtRaw = json['sentAt'];
    if (sentAtRaw is Timestamp) {
      sentAt = sentAtRaw.toDate();
    } else if (sentAtRaw is int) {
      sentAt = DateTime.fromMillisecondsSinceEpoch(sentAtRaw);
    } else if (sentAtRaw is String) {
      sentAt = DateTime.tryParse(sentAtRaw) ?? DateTime.now();
    } else {
      sentAt = DateTime.now();
    }

    return Message(
      id: id ?? (json['id']?.toString() ?? ''),
      text: text,
      senderId: senderId,
      senderName: senderName,
      sentAt: sentAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'text': text,
        'senderId': senderId,
        'senderName': senderName,
        // توصية: تحفظ كـ Timestamp
        'sentAt': Timestamp.fromDate(sentAt),
      };
}
