import 'package:resurgence/constants.dart';

class Message {
  final String from;
  final String content;
  final int sequence;
  final DateTime time;

  Message(this.from, this.content, this.sequence, this.time);

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      json['from'],
      json['content'],
      json['sequence'],
      DateTime.parse(json['time']),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Message &&
          runtimeType == other.runtimeType &&
          sequence == other.sequence;

  @override
  int get hashCode => sequence.hashCode;
}

class Subscription {
  final String topic;
  final String _name;
  Message lastMessage;
  bool unread;

  Subscription(this.topic, this._name, this.unread, {this.lastMessage});

  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription(
      json['topic'],
      json['name'],
      json['unread'],
      lastMessage: json['last_message'] == null
          ? null
          : Message.fromJson(json['last_message']),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Subscription &&
          runtimeType == other.runtimeType &&
          topic == other.topic;

  @override
  int get hashCode => topic.hashCode;

  bool isGroup() => topic.startsWith('grp');

  String get name {
    if (this.isGroup()) {
      return S.groupName(this._name);
    }
    return _name;
  }

  @override
  String toString() => topic;
}

class Presence {
  final String name;
  final bool online;
  final DateTime _time;

  Presence(this.name, this.online, this._time);

  factory Presence.fromJson(Map<String, dynamic> json) {
    var time = DateTime.parse(json['time']);

    var localDuration = DateTime.now().difference(time);
    var diff = localDuration.inMilliseconds - json['duration_millis'];

    time = time.add(Duration(milliseconds: diff));

    return Presence(json['name'], json['online'], time);
  }

  @override
  String toString() => 'UserStat{name: $name, online: $online, time: $_time}';

  Duration get duration => DateTime.now().difference(_time);
}
