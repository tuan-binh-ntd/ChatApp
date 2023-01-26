import 'package:flutter/foundation.dart';

enum ReceiptStatus {sent, delivered, read} 

extension EnumParsing on ReceiptStatus {
  String  value() {
    return this.toString().split('.').last;
    //ReceiptStatus.sent
  }
  static ReceiptStatus fromString(String status) {
    return ReceiptStatus.values.firstWhere((element) => element.value() == status);
  }
}

class Receipt {
  String get id => _id;
  final String recipient;
  final String messageId;
  final ReceiptStatus status;
  final DateTime timestamp;
  String _id;

  Receipt({
    @required this.recipient,
    @required this.messageId,
    @required this.status,
    @required this.timestamp
  });

  Map<String, dynamic> toJson() => {
    'recipient': this.recipient,
    'messageId': this.messageId,
    'status': this.status.value(),
    'timestamp': this.timestamp
  };

  factory Receipt.fromJson(Map<String, dynamic> json) {
    var receipt = Receipt(
      recipient: json['recipient'], 
      messageId: json['messageId'],
      status: EnumParsing.fromString(json['status']), 
      timestamp: json['timestamp']);
      receipt._id = json['id'];
      return receipt;
  }
}