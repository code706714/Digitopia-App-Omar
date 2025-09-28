import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:digitopia_app/constants/constants.dart';

class Message {
  final String message;
  final String id;

  Message(this.message, this.id);

  factory Message.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;

    return Message(
      data?[kMessage] ?? "", // لو مفيش رسالة نخليها نص فاضي
      doc.id,               // الـ id الأساسي للدوكيومنت
    );
  }
}
