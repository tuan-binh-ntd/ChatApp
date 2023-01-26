import 'dart:async';

import 'package:chat/src/models/user.dart';
import 'package:chat/src/models/typing_event.dart';
import 'package:chat/src/services/typing/typing_notification_service_contract.dart';
import 'package:rethinkdb_dart/rethinkdb_dart.dart';
import 'package:flutter/foundation.dart';

class TypingNotification implements ITypingNotification {
  final Connection _connection;
  final Rethinkdb r;
  final _controller = StreamController<TypingEvent>.broadcast();
  StreamSubscription _changeFeed;

  TypingNotification(this.r, this._connection);

  @override
  Future<bool> send({@required TypingEvent event, @required User to}) async {
    if(!to.active) return false;
    
    Map record = await r
      .table('typing_events')
      .insert(event.toJson(), {'conflict': 'update'})
      .run(_connection);
      return record['inserted'] == 1;
  }

  @override
  Stream<TypingEvent> subscribe(User user, List<String> userIds) {
    _startReceivingTypingEvents(user, userIds);
    return _controller.stream;
  }
  
  @override
  void dispose() {
    _changeFeed?.cancel();
    _controller?.close();
  }

  _startReceivingTypingEvents(User user, List<String> userIds) {
    _changeFeed = r
        .table('typing_events')
        .filter((event) {
          return event('to')
              .eq(user.id)
              .and(r.expr(userIds).contains(event('from')));
        })
        .changes({'include_initial': true})
        .run(_connection)
        .asStream()
        .cast<Feed>()
        .listen((event) {
          event
              .forEach((feedData) {
                if (feedData['new_val'] == null) return;

                final typing = _eventFromFeed(feedData);
                _controller.sink.add(typing);
                _removeEvent(typing);
              })
              .catchError((err) => print(err))
              .onError((dynamic error, stackTrace) => print(error));
        });
  }

  TypingEvent _eventFromFeed(feedData) {
    return TypingEvent.fromJson(feedData['new_val']);
  }

  _removeEvent(TypingEvent event) {
    r.table('typing_events').get(event.id).delete(
        {'return_changes': false}).run(_connection);
  }
}