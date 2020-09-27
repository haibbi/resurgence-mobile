import 'package:resurgence/enum.dart';
import 'package:resurgence/item/item.dart';
import 'package:resurgence/task/model.dart';

class MultiplayerTask extends AbstractEnum {
  MultiplayerTask({
    this.positions,
    this.leaderTask,
    this.left,
    key,
    value,
  }) : super(key: key, value: value);

  final List<Position> positions;
  final Task leaderTask;
  final int left;

  factory MultiplayerTask.fromJson(Map<String, dynamic> json) {
    var abstractEnum = AbstractEnum.fromJson(json);
    return MultiplayerTask(
        positions: json["positions"] == null
            ? null
            : List<Position>.from(
                json["positions"].map((x) => Position.fromJson(x))),
        leaderTask: json["leader_task"] == null
            ? null
            : Task.fromJson(json["leader_task"]),
        left: json["left"] == null ? null : json["left"],
        key: abstractEnum.key,
        value: abstractEnum.value);
  }
}

class Position extends AbstractEnum {
  Position({this.leader, key, value}) : super(key: key, value: value);

  final bool leader;

  factory Position.fromJson(Map<String, dynamic> json) {
    var abstractEnum = AbstractEnum.fromJson(json);
    return Position(
      leader: json["leader"] == null ? null : json["leader"],
      key: abstractEnum.key,
      value: abstractEnum.value,
    );
  }
}

class Plan {
  Plan({
    this.leader,
    this.task,
    this.members,
  });

  final String leader;
  final MultiplayerTask task;
  final List<Member> members;

  factory Plan.fromJson(Map<String, dynamic> json) {
    return Plan(
      leader: json["leader"] == null ? null : json["leader"],
      task:
          json["task"] == null ? null : MultiplayerTask.fromJson(json["task"]),
      members: json["members"] == null
          ? null
          : List<Member>.from(json["members"].map((x) => Member.fromJson(x))),
    );
  }
}

class Member {
  Member({
    this.position,
    this.task,
    this.name,
    this.status,
    this.selectedItems,
  });

  final Position position;
  final Task task;
  final String name;
  final Status status;
  final List<PlayerItem> selectedItems;

  factory Member.fromJson(Map<String, dynamic> json) {
    return Member(
      position:
          json["position"] == null ? null : Position.fromJson(json["position"]),
      task: json["task"] == null ? null : Task.fromJson(json["task"]),
      name: json["name"] == null ? null : json["name"],
      status: _findStatus(json["status"]),
      selectedItems: json["selected_items"] == null
          ? null
          : List<PlayerItem>.from(
              json["selected_items"].map((x) => PlayerItem.fromJson(x))),
    );
  }
}

enum Status { waiting, ready }

Status _findStatus(String status) {
  if (status == null) return null;

  switch (status) {
    case 'WAITING':
      return Status.waiting;
    case 'READY':
      return Status.ready;
    default:
      return null;
  }
}

class MultiplayerTaskResult extends TaskResult {
  MultiplayerTaskResult({this.player, TaskResult result})
      : super(
          succeed: result.succeed,
          experienceGain: result.experienceGain,
          moneyGain: result.moneyGain,
          skillGain: result.skillGain,
          drop: result.drop,
        );

  final String player;

  factory MultiplayerTaskResult.fromJson(Map<String, dynamic> json) {
    return MultiplayerTaskResult(
      player: json['player'] == null ? null : json['player'],
      result:
          json['result'] == null ? null : TaskResult.fromJson(json['result']),
    );
  }
}
