import 'dart:async';

import 'package:duration/duration.dart';
import 'package:duration/locale.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:resurgence/constants.dart';
import 'package:resurgence/duration.dart';
import 'package:resurgence/enum.dart';
import 'package:resurgence/item/item.dart';
import 'package:resurgence/money.dart';
import 'package:resurgence/task/model.dart';
import 'package:resurgence/task/select_item.dart';
import 'package:resurgence/task/service.dart';

typedef OnPerform = void Function(List<PlayerItem> selectedItems);

class TaskListTile extends StatelessWidget {
  static const double height = 120.0;
  static const double imageSize = 72.0;
  static const double paddingSize = imageSize / 2;
  static const double expandedPaddingSize = (imageSize / 2) + (imageSize / 4);

  final Task task;
  final OnPerform onPerform;

  const TaskListTile(
    this.task, {
    Key key,
    @required this.onPerform,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.only(
              left: paddingSize,
              top: 8.0,
              right: 8.0,
              bottom: 8.0,
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.only(left: expandedPaddingSize),
                  height: 48.0,
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(8.0),
                      topRight: Radius.circular(8.0),
                    ),
                    boxShadow: [
                      BoxShadow(color: Colors.grey[800], blurRadius: 1.0),
                    ],
                  ),
                  child: Row(
                    children: [
                      Text(
                        task.value,
                        style: Theme.of(context)
                            .textTheme
                            .bodyText1
                            .copyWith(color: task.color()),
                      ),
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            Icon(
                              Icons.trending_up,
                            ),
                            SizedBox(width: 4.0),
                            Text(
                              Money.format(task.moneyGain),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyText1
                                  .copyWith(fontSize: 16.0),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8.0),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.only(left: expandedPaddingSize),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(8.0),
                      bottomRight: Radius.circular(8.0),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.timer),
                      const SizedBox(width: 4.0),
                      Text(
                        prettyDuration(
                          Duration(milliseconds: task.durationMills),
                          locale: const TurkishDurationLocale(),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          alignment: Alignment.centerRight,
                          child: TaskPerformButton(
                            task,
                            onPressed: () {
                              var requiredItemCat = task.requiredItemCategory;
                              if (requiredItemCat != null &&
                                  requiredItemCat.isNotEmpty) {
                                Navigator.push<List<PlayerItem>>(
                                  context,
                                  SelectItemRoute(task),
                                ).then((selectedItems) {
                                  // if `selectedItems` is null,
                                  //  it means player canceled the task
                                  if (selectedItems == null) return;
                                  onPerform(selectedItems);
                                });
                              } else {
                                onPerform([]);
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 8.0),
                    ],
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.push(context, TaskDetailRoute(task)),
            child: Container(
              margin: EdgeInsets.only(left: 8.0),
              child: Hero(
                tag: task,
                child: Image.network(
                  task.image,
                  width: imageSize,
                  height: height,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TaskPerformButton extends StatefulWidget {
  final Task task;
  final Function onPressed;

  const TaskPerformButton(
    this.task, {
    Key key,
    @required this.onPressed,
  }) : super(key: key);

  @override
  _TaskPerformButtonState createState() => _TaskPerformButtonState();
}

class _TaskPerformButtonState extends State<TaskPerformButton> {
  Duration _duration = Duration.zero;
  bool _finished = false;
  Timer _timer;

  Future<SuccessRatio> _successRatio;
  TaskService _taskService;

  @override
  void initState() {
    super.initState();
    _duration = Duration(milliseconds: widget.task.leftMillis);
    if (_duration.inMilliseconds <= 0) {
      _finished = true;
    } else {
      _timer = Timer.periodic(Duration(seconds: 1), (timer) {
        if (_duration.inMilliseconds <= 999) {
          setState(() => _finished = true);
          timer.cancel();
          return;
        }
        setState(
          () => _duration = Duration(
            milliseconds: _duration.inMilliseconds - 1000,
          ),
        );
      });
    }
    this._taskService = context.read<TaskService>();
    this._successRatio = this._taskService.successRatio(widget.task);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_finished) {
      return FutureBuilder<SuccessRatio>(
        future: this._successRatio,
        builder: (context, snapshot) {
          if (!snapshot.hasError &&
              snapshot.connectionState == ConnectionState.done &&
              snapshot.hasData) {
            var successRatio = snapshot.data;
            return OutlineButton(
              highlightColor: _buttonColor(successRatio.ratio),
              splashColor: _buttonColor(successRatio.ratio),
              child: Text(
                '${S.perform} | %${successRatio.ratio}',
                textAlign: TextAlign.right,
              ),
              onPressed: widget.onPressed,
            );
          }

          return OutlineButton(
            child: Text(S.perform, textAlign: TextAlign.right),
            onPressed: widget.onPressed,
          );
        },
      );
    }
    return FlatButton(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18.0),
      ),
      child: Text(
        ISO8601Duration.from(_duration).pretty(abbreviated: true),
        textAlign: TextAlign.right,
      ),
      onPressed: null,
    );
  }

  Color _buttonColor(int ratio) {
    if (ratio >= 50) {
      return Colors.green[700];
    } else if (ratio >= 25) {
      return Colors.amber[800];
    }
    return Colors.red[700];
  }
}

class TaskDetail extends StatelessWidget {
  final Task task;

  const TaskDetail(
    this.task, {
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(18.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Card(
              child: Column(
                children: [
                  Container(
                    color: const Color(0xff202020),
                    padding: EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        Hero(
                          tag: task,
                          child: Image.network(
                            task.image,
                            width: 64.0,
                            height: 64,
                          ),
                        ),
                        SizedBox(width: 8.0),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(task.value),
                            SizedBox(height: 4.0),
                            Text(
                              task.difficulty.value,
                              style: Theme.of(context)
                                  .primaryTextTheme
                                  .bodyText1
                                  .copyWith(color: task.color()),
                            ),
                          ],
                        ),
                        Expanded(child: Container()),
                        Row(
                          children: [
                            Icon(Icons.star, color: Colors.amber),
                            Text(
                              NumberFormat.compact().format(
                                task.experienceGain,
                              ),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyText1
                                  .copyWith(color: Colors.amber),
                            )
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    color: const Color(0xff303030),
                    padding: EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        EnumWrapper(
                          task.auxiliary,
                          text: S.auxiliary,
                          color: Colors.deepPurple[600],
                        ),
                        SizedBox(height: 8.0),
                        EnumWrapper(
                          task.skillGain,
                          text: S.skillGain,
                          color: Colors.green[700],
                        ),
                        SizedBox(height: 8.0),
                        EnumWrapper(
                          task.drop.map((e) => e.item),
                          text: S.drop,
                          color: Colors.blueGrey[700],
                        ),
                        SizedBox(height: 16.0),
                        OutlineButton(
                          child: Text(S.ok),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Routes

class TaskDetailRoute<T> extends PageRouteBuilder<T> {
  final Task task;

  @override
  bool get opaque => false;

  @override
  bool get barrierDismissible => true;

  @override
  Color get barrierColor => Colors.black54;

  TaskDetailRoute(this.task)
      : super(
          pageBuilder: (context, animation, secondaryAnimation) =>
              new TaskDetail(task),
        );

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation, Widget child) {
    return FadeTransition(opacity: animation, child: child);
  }
}
