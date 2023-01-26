import 'package:chat/src/models/message.dart';
import 'package:chat/src/models/user.dart';
import 'package:chat/src/services/message/message_service_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rethinkdb_dart/rethinkdb_dart.dart';

import 'helpers.dart';

void main() {
  Rethinkdb r = Rethinkdb();
  Connection connection;
  MessageService sut;

  setUp(() async {
    connection = await r.connect(host: "127.0.0.1", port: 28015);
    await createDb(r, connection);
    sut = MessageService(r, connection);
  });

  tearDown(() async {
    sut.dispose();
    await cleanDb(r, connection);
  });

  final user1 = User.fromJson({
    'id': '1234',
    'active': true,
    'lastSeen': DateTime.now()
  });

  final user2 = User.fromJson({
    'id': '1111',
    'active': true,
    'lastSeen': DateTime.now()
  });
  
  test('sent message successfully', () async {
    Message message = Message(
      from: user1.id, 
      to: '3456', 
      timestamp: DateTime.now(), 
      contents: 'Hello'
    );

    final res = await sut.send(message);
    expect(res, true);
  });

  test('successfully subscribe and receive message', () async {
    sut.messages(activeUser: user2).listen(expectAsync1((message) {
      expect(message.to, user2.id);
      expect(message.id, isNotEmpty);
    }, count: 2));

    Message message = Message(
      from: user1.id, 
      to: user2.id, 
      timestamp: DateTime.now(), 
      contents: 'Hello'
    );

    Message secondMessage = Message(
      from: user1.id, 
      to: user2.id, 
      timestamp: DateTime.now(), 
      contents: 'Hello again'
    );

    await sut.send(message);
    await sut.send(secondMessage);
  });
  
  test('successfully subscribe and receive new message', () async {
    Message message = Message(
      from: user1.id, 
      to: user2.id, 
      timestamp: DateTime.now(), 
      contents: 'Hello'
    );

    Message secondMessage = Message(
      from: user1.id, 
      to: user2.id, 
      timestamp: DateTime.now(), 
      contents: 'Hello again'
    );

    await sut.send(message);
    await sut.send(secondMessage)
      .whenComplete(() => 
        sut.messages(activeUser: user2)
        .listen(
          expectAsync1((message) {
              expect(message.to, user2.id);
            }, count: 2
          )
        )
      );
  });
  
}