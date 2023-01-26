import 'dart:async';

import 'package:chat/src/models/user.dart';
import 'package:chat/src/models/message.dart';
import 'package:chat/src/services/message/message_service_contract.dart';
import 'package:rethinkdb_dart/rethinkdb_dart.dart';

class MessageService implements IMessageService {
  final Rethinkdb r;
  final Connection _connection;

  final _controller = StreamController<Message>.broadcast();
  StreamSubscription _changefeed;
  MessageService(this.r, this._connection);

  @override
  dispose() {
    _changefeed?.cancel();
    _controller?.close();
  }

  @override
  Stream<Message> messages({User activeUser}) {
    _startReceivingMessages(activeUser);
    return _controller.stream;
  }

  @override
  Future<bool> send(Message message) async {
    Map record = await r.table('messages').insert(message.toJson()).run(_connection);
    return record['inserted'] == 1;
    
  }
  
  void _startReceivingMessages(User activeUser) {
    _changefeed = r
      .table('messages')
      .filter({'to': activeUser.id})
      .changes({'include_initial': true})
      .run(_connection)
      .asStream()
      .cast<Feed>()
      .listen((event) {
        event.forEach((feedData) { 
          if(feedData['new_val'] == null) return;
          
          final message = _messageFromFeed(feedData);
          _controller.add(message);
          _removeDeliveredMessage(message);
        }).catchError((err) => print(err))
        .onError((error, stackTrace) => print(error));
      });

  }

  Message _messageFromFeed(feedData) {
    return Message.fromJson(feedData['new_val']);
  }
  
  _removeDeliveredMessage(Message message) {
    r
      .table('messages')
      .get(message.id)
      .delete({'return_changes': false})
      .run(_connection);
  }
  

}