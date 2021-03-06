import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:resurgence/constants.dart';
import 'package:resurgence/enum.dart';
import 'package:resurgence/family/management.dart';
import 'package:resurgence/family/service.dart';
import 'package:resurgence/family/state.dart';
import 'package:resurgence/money.dart';
import 'package:resurgence/player/player.dart';
import 'package:resurgence/ui/error_handler.dart';
import 'package:resurgence/ui/shared.dart';

class Family {
  String name;
  String image;
  String boss;
  String consultant;
  Building building;
  List<String> members;
  AbstractEnum race;
  List<Chief> chiefs;
  int size;

  Family({
    this.name,
    this.image,
    this.boss,
    this.consultant,
    this.building,
    this.members,
    this.race,
    this.chiefs,
    this.size,
  });

  Family.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    image = json['image'];
    boss = json['boss'];
    consultant = json['consultant'];
    building =
        json['building'] != null ? Building.fromJson(json['building']) : null;
    members = json['members'] != null
        ? List.of(json['members'].cast<String>())
        : null;
    race = json['race'] != null ? AbstractEnum.fromJson(json['race']) : null;
    if (json['chiefs'] != null) {
      chiefs = <Chief>[];
      json['chiefs'].forEach((v) {
        chiefs.add(Chief.fromJson(v));
      });
    }
    size = json['size'];
  }

  String available() {
    return '$size / ${building.size}';
  }

  List<String> sortMembers() {
    var members = List.of(this.members);
    var chiefNames = this.chiefs.map((e) => e.name);

    members.removeWhere((member) {
      return member == this.boss ||
          member == this.consultant ||
          chiefNames.contains(member);
    });
    members.insert(0, this.boss);
    if (this.consultant != null) members.insert(1, this.consultant);
    var chiefs = chiefNames.toList(growable: false);
    chiefs.sort();
    if (chiefs.isNotEmpty)
      members.insertAll(this.consultant == null ? 1 : 2, chiefs);
    return members;
  }
}

class Chief {
  String name;
  List<String> members;

  Chief({this.name, this.members});

  Chief.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    members = json['members'].cast<String>();
  }
}

class Building extends AbstractEnum {
  int size;
  int price;

  Building({String key, String value, this.size, this.price})
      : super(key: key, value: value);

  Building.fromJson(Map<String, dynamic> json) {
    var abstractEnum = AbstractEnum.fromJson(json);
    key = abstractEnum.key;
    value = abstractEnum.value;
    size = json['size'];
    price = json['price'];
  }
}

class Announcement {
  Announcement({
    this.id,
    this.title,
    this.content,
    this.secret,
    this.time,
  });

  final int id;
  final String title;
  final String content;
  final bool secret;
  final DateTime time;

  factory Announcement.fromJson(Map<String, dynamic> json) => Announcement(
        id: json['id'] == null ? null : json['id'],
        title: json['title'] == null ? null : json['title'],
        content: json['content'] == null ? null : json['content'],
        secret: json['secret'] == null ? null : json['secret'],
        time: json['time'] == null ? null : DateTime.parse(json['time']),
      );
}

class FamilyBank {
  FamilyBank({this.amount});

  final int amount;

  factory FamilyBank.fromJson(Map<String, dynamic> json) => FamilyBank(
        amount: json['amount'] == null ? null : json['amount'],
      );
}

class FamilyBankLog {
  FamilyBankLog({
    this.member,
    this.amount,
    this.reason,
    this.date,
  });

  final String member;
  final int amount;
  final Reason reason;
  final DateTime date;

  factory FamilyBankLog.fromJson(Map<String, dynamic> json) => FamilyBankLog(
        member: json['member'] == null ? null : json['member'],
        amount: json['amount'] == null ? null : json['amount'],
        reason: json['reason'] == null ? null : Reason.fromJson(json['reason']),
        date: json['date'] == null ? null : DateTime.parse(json['date']),
      );
}

class Reason extends AbstractEnum {
  Reason({
    String key,
    String value,
    this.revenue,
  }) : super(key: key, value: value);

  final bool revenue;

  factory Reason.fromJson(Map<String, dynamic> json) {
    var abstractEnum = AbstractEnum.fromJson(json);
    return Reason(
      key: abstractEnum.key,
      value: abstractEnum.value,
      revenue: json['revenue'] == null ? null : json['revenue'],
    );
  }
}

enum Direction { family, player, unknown }

extension Directions on Direction {
  static Direction valueOf(String value) {
    switch (value.toLowerCase()) {
      case 'family':
        return Direction.family;
      case 'player':
        return Direction.player;
      default:
        return Direction.unknown;
    }
  }
}

class Invitation {
  Invitation({
    this.id,
    this.player,
    this.family,
    this.time,
    this.direction,
  });

  final int id;
  final String player;
  final String family;
  final DateTime time;
  final Direction direction;

  factory Invitation.fromJson(Map<String, dynamic> json) {
    return Invitation(
      id: json['id'] == null ? null : json['id'],
      player: json['player'] == null ? null : json['player'],
      family: json['family'] == null ? null : json['family'],
      time: json['time'] == null ? null : DateTime.parse(json['time']),
      direction: json['direction'] == null
          ? null
          : Directions.valueOf(json['direction']),
    );
  }
}

class FamiliesPage extends StatefulWidget {
  @override
  _FamiliesPageState createState() => _FamiliesPageState();
}

class _FamiliesPageState extends State<FamiliesPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.families),
        actions: [
          Tooltip(
            message: S.createNewFamily,
            child: IconButton(
              icon: Icon(Icons.add),
              onPressed: () => Navigator.push(context, _CreateFamilyRoute()),
            ),
          )
        ],
      ),
      body: _Families(),
    );
  }
}

class _Families extends StatefulWidget {
  @override
  __FamiliesState createState() => __FamiliesState();
}

class __FamiliesState extends State<_Families> {
  Future<List<Family>> familiesFuture;

  @override
  void initState() {
    super.initState();
    familiesFuture = fetchFamilies();
  }

  Future<List<Family>> fetchFamilies() =>
      context.read<FamilyService>().allFamily();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Family>>(
      future: familiesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingWidget();
        } else if (snapshot.hasError) {
          return RefreshOnErrorWidget(onPressed: () {
            setState(() {
              familiesFuture = fetchFamilies();
            });
          });
        }

        var families = snapshot.data;

        return RefreshIndicator(
          onRefresh: () {
            var families = fetchFamilies();
            setState(() {
              familiesFuture = families;
            });
            return families;
          },
          child: ListView.builder(
            itemCount: families.length,
            itemBuilder: (context, index) {
              var family = families[index];
              return _FamilyListTile(family: family);
            },
          ),
        );
      },
    );
  }
}

class _FamilyListTile extends StatelessWidget {
  const _FamilyListTile({Key key, this.family}) : super(key: key);

  final Family family;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Hero(
        tag: family.name,
        child: Image.network(family.image),
      ),
      title: Text(
        family.name,
        style: Theme.of(context).textTheme.headline6,
      ),
      subtitle: Text(family.race.value),
      trailing: Text(family.available()),
      onTap: () {
        var service = context.read<FamilyService>();
        service.detail(family.name).then((family) {
          Navigator.push(context, FamilyDetailRoute(family));
        }).catchError((e) => ErrorHandler.showError(context, e));
      },
    );
  }
}

class _FamilyDetail extends StatelessWidget {
  const _FamilyDetail(
    this.family, {
    Key key,
  }) : super(key: key);

  final Family family;

  @override
  Widget build(BuildContext context) {
    String currentPlayer = context.watch<PlayerState>().name;
    bool isMember = family.members.contains(currentPlayer);

    return Scaffold(
      appBar: AppBar(
        title: Text(family.name),
        actions: [
          Consumer<FamilyState>(
            builder: (context, state, child) {
              if (state.haveFamily) {
                return Tooltip(
                  message: S.leave,
                  child: IconButton(
                    icon: Icon(Icons.exit_to_app),
                    onPressed: () {
                      showConfirmationDialog(
                        context,
                        S.leaveFamilyConfirmationTitle,
                        S.leaveFamilyConfirmationContent,
                        S.leave,
                        S.cancel,
                        () => context.read<FamilyService>().leave().then((_) {
                          context.read<FamilyState>().family = null;
                          Navigator.pop(context);
                        }).catchError(
                            (e) => ErrorHandler.showError(context, e)),
                      );
                    },
                  ),
                );
              }
              return child;
            },
            child: Tooltip(
              message: S.apply,
              child: IconButton(
                icon: Icon(Icons.mail_outline),
                onPressed: () => context
                    .read<FamilyService>()
                    .apply(family.name)
                    .then((_) =>
                        showInformationDialog(context, S.applySuccessInfo))
                    .catchError((e) => ErrorHandler.showError(context, e)),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              child: Column(
                children: [
                  Container(
                    child: Center(
                      child: Hero(
                        tag: family.name,
                        child: Image.network(
                          family.image,
                          width: min(400, MediaQuery.of(context).size.width),
                        ),
                      ),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        family.name,
                        style: Theme.of(context).textTheme.headline4,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.child_care),
                          const SizedBox(width: 8.0),
                          Text(
                            family.boss,
                            style: Theme.of(context).textTheme.subtitle1,
                          ),
                        ],
                      ),
                      family.consultant != null
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.book),
                                const SizedBox(width: 8.0),
                                Text(
                                  family.consultant,
                                  style: Theme.of(context).textTheme.subtitle1,
                                ),
                              ],
                            )
                          : Container(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.home),
                          SizedBox(width: 8.0),
                          Text(family.building.value),
                        ],
                      ),
                      Text(
                        family.race.value,
                        style: Theme.of(context).textTheme.subtitle2,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            ListTile(
              title: Text(S.regimes),
              trailing: const Icon(Icons.navigate_next),
              onTap: () => Navigator.push(context, _RegimesRoute(family)),
            ),
            ListTile(
              title: Text(S.members),
              trailing: const Icon(Icons.navigate_next),
              onTap: () => Navigator.push(context, _MembersRoute(family)),
            ),
            ListTile(
              title: Text(S.announcements),
              trailing: const Icon(Icons.navigate_next),
              onTap: () =>
                  Navigator.push(context, _AnnouncementsRoute(family.name)),
            ),
            isMember
                ? ListTile(
                    title: Text(S.bank),
                    trailing: const Icon(Icons.navigate_next),
                    onTap: () =>
                        Navigator.push(context, _BankRoute(family.boss)),
                  )
                : Container()
          ],
        ),
      ),
      floatingActionButton: currentPlayer == family.boss
          ? FloatingActionButton(
              child: Icon(Icons.build),
              onPressed: () =>
                  Navigator.push(context, _ManagementWidgetRoute(family)),
            )
          : null,
    );
  }
}

class RegimesWidget extends StatelessWidget {
  const RegimesWidget({Key key, this.family}) : super(key: key);

  final Family family;

  @override
  Widget build(BuildContext context) {
    var bossRegime = List.of(family.members);
    var chiefRegimes =
        family.chiefs.map((c) => c.members).expand((m) => m).toSet();
    bossRegime.removeWhere((m) => chiefRegimes.contains(m));
    bossRegime.remove(family.boss);

    return Scaffold(
      appBar: AppBar(
        title: Text('${family.name} ${S.regimes}'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            ExpansionTile(
              initiallyExpanded: true,
              title: Text(family.boss),
              subtitle: Text(
                S.boss,
                style: Theme.of(context).textTheme.subtitle2,
              ),
              children: bossRegime.map((m) => Text(m)).toList(growable: false),
            ),
            ...family.chiefs.map((chief) {
              return ExpansionTile(
                title: Text(chief.name),
                subtitle: Text(
                  S.chief,
                  style: Theme.of(context).textTheme.subtitle2,
                ),
                children:
                    chief.members.map((m) => Text(m)).toList(growable: false),
              );
            }).toList(growable: false),
          ],
        ),
      ),
    );
  }
}

class AnnouncementsWidget extends StatefulWidget {
  final String familyName;

  const AnnouncementsWidget(this.familyName, {Key key}) : super(key: key);

  @override
  _AnnouncementsWidgetState createState() => _AnnouncementsWidgetState();
}

class _AnnouncementsWidgetState extends State<AnnouncementsWidget> {
  Future<List<Announcement>> announcementsFuture;

  @override
  void initState() {
    super.initState();
    announcementsFuture = fetch();
  }

  Future<List<Announcement>> fetch() =>
      context.read<FamilyService>().announcement(family: widget.familyName);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: W.defaultAppBar,
      body: LoadingFutureBuilder<List<Announcement>>(
        future: announcementsFuture,
        onError: () => setState(() {
          announcementsFuture = fetch();
        }),
        builder: (context, snapshot) {
          var announcements = snapshot.data;

          return RefreshIndicator(
            onRefresh: () {
              var feature = fetch();
              setState(() {
                announcementsFuture = feature;
              });
              return feature;
            },
            child: ListView.separated(
              separatorBuilder: (_, __) => Divider(),
              itemCount: announcements.length,
              itemBuilder: (context, index) {
                var announcement = announcements[index];

                Widget title = Text(announcement.title);

                if (announcement.secret) {
                  var textStyle = Theme.of(context)
                      .textTheme
                      .bodyText1
                      .copyWith(fontWeight: FontWeight.bold);
                  title = Row(
                    children: [
                      title,
                      SizedBox(width: 8.0),
                      Chip(
                        label: Text(S.secret, style: textStyle),
                        backgroundColor: Colors.red,
                      )
                    ],
                  );
                }

                return ListTile(
                  title: title,
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(announcement.content),
                      SizedBox(height: 8.0),
                      Text(DateFormat(S.dateFormat).format(
                        announcement.time.toLocal(),
                      ))
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _MembersWidget extends StatelessWidget {
  const _MembersWidget(this.family, {Key key}) : super(key: key);

  final Family family;

  @override
  Widget build(BuildContext context) {
    var members = family.sortMembers();

    return Scaffold(
      appBar: W.defaultAppBar,
      body: ListView.separated(
        itemCount: members.length,
        separatorBuilder: (_, __) => Divider(),
        itemBuilder: (context, index) {
          var member = members[index];
          Widget subTitle;

          if (member == family.boss) {
            subTitle = Text(S.boss);
          } else if (member == family.consultant) {
            subTitle = Text(S.consultant);
          } else if (family.chiefs.map((c) => c.name).contains(member)) {
            subTitle = Text(S.chief);
          }

          return ListTile(
            title: Text(member),
            subtitle: subTitle,
          );
        },
      ),
    );
  }
}

class _BankWidget extends StatefulWidget {
  const _BankWidget(
    this.boss, {
    Key key,
  }) : super(key: key);

  final String boss;

  @override
  __BankWidgetState createState() => __BankWidgetState();
}

class __BankWidgetState extends State<_BankWidget> {
  final _formKey = GlobalKey<FormState>();
  final moneyController = TextEditingController();

  Future<FamilyBank> familyBankFuture;
  Future<List<FamilyBankLog>> familyBankLogFuture;

  @override
  void initState() {
    super.initState();
    familyBankFuture = fetch();
    familyBankLogFuture = fetchLog();
  }

  Future<FamilyBank> fetch() => context.read<FamilyService>().bank();

  Future<List<FamilyBankLog>> fetchLog() =>
      context.read<FamilyService>().bankLog();

  @override
  Widget build(BuildContext context) {
    var currentPlayer = context.watch<PlayerState>().name;
    var isBoss = currentPlayer == widget.boss;

    return Scaffold(
      appBar: W.defaultAppBar,
      body: FutureBuilder<FamilyBank>(
        future: familyBankFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingWidget();
          } else if (snapshot.hasError) {
            return RefreshOnErrorWidget(onPressed: () {
              setState(() {
                familyBankFuture = fetch();
              });
            });
          }

          var familyBank = snapshot.data;

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: FittedBox(
                  child: Text(
                    Money.format(familyBank.amount),
                    style: Theme.of(context)
                        .textTheme
                        .headline2
                        .copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              Form(
                key: _formKey,
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: TextFormField(
                    decoration: InputDecoration(labelText: S.money),
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    controller: moneyController,
                    onFieldSubmitted: (value) =>
                        FocusScope.of(context).nextFocus(),
                    validator: (value) {
                      if (value.isEmpty) return S.validationRequired;
                      if (int.tryParse(value) == null) return S.integerRequired;
                      return null;
                    },
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  RaisedButton(
                    color: Colors.green,
                    child: Text(S.deposit),
                    onPressed: this.deposit,
                  ),
                  RaisedButton(
                    color: Colors.red,
                    child: Text(S.withdraw),
                    onPressed: isBoss ? this.withdraw : null,
                  )
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Divider(height: 0, thickness: 4.0),
              ),
              Expanded(
                child: FutureBuilder<List<FamilyBankLog>>(
                  future: familyBankLogFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const LoadingWidget();
                    } else if (snapshot.hasError) {
                      return RefreshOnErrorWidget(onPressed: () {
                        setState(() {
                          familyBankLogFuture = fetchLog();
                        });
                      });
                    }

                    var familyBankLog = snapshot.data;

                    return ListView.builder(
                      primary: false,
                      itemCount: familyBankLog.length,
                      itemBuilder: (context, index) {
                        var log = familyBankLog[index];
                        return ListTile(
                          leading: Icon(
                            log.reason.revenue
                                ? Icons.arrow_drop_up
                                : Icons.arrow_drop_down,
                            color:
                                log.reason.revenue ? Colors.green : Colors.red,
                          ),
                          title: MoneyWidget(log.amount),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(log.reason.value),
                              Text(
                                DateFormat(S.dateFormat).format(
                                  log.date.toLocal(),
                                ),
                                style: Theme.of(context).textTheme.subtitle2,
                              )
                            ],
                          ),
                          trailing: Text(
                            log.member,
                            style: Theme.of(context)
                                .textTheme
                                .bodyText1
                                .copyWith(fontWeight: FontWeight.bold),
                          ),
                          isThreeLine: true,
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> withdraw() {
    if (!_formKey.currentState.validate()) return null; // form is not valid

    int amount = int.parse(moneyController.text);
    return context.read<FamilyService>().withdraw(amount).then((_) {
      moneyController.text = '';
      setState(() {
        familyBankFuture = fetch();
        familyBankLogFuture = fetchLog();
      });
    }).catchError((e) => ErrorHandler.showError(context, e));
  }

  Future<void> deposit() {
    if (!_formKey.currentState.validate()) return null; // form is not valid

    int amount = int.parse(moneyController.text);
    return context.read<FamilyService>().deposit(amount).then((_) {
      moneyController.text = '';
      setState(() {
        familyBankFuture = fetch();
        familyBankLogFuture = fetchLog();
      });
    }).catchError((e) => ErrorHandler.showError(context, e));
  }
}

class _ManagementWidget extends StatelessWidget {
  const _ManagementWidget(this.family, {Key key}) : super(key: key);

  final Family family;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.management),
      ),
      body: GridView.count(
        crossAxisCount: 1,
        padding: EdgeInsets.all(8.0),
        childAspectRatio: 8.0,
        crossAxisSpacing: 8.0,
        mainAxisSpacing: 8.0,
        children: [
          OutlinedButton(
            child: Text(
              S.humanResources,
              textAlign: TextAlign.center,
            ),
            onPressed: () =>
                Navigator.push(context, HumanResourceRoute(family)),
          ),
          OutlinedButton(
            child: Text(
              S.applicationsInvitations,
              textAlign: TextAlign.center,
            ),
            onPressed: () => Navigator.push(context, InvitationRoute(family)),
          ),
          OutlinedButton(
            child: Text(
              S.regimeManagement,
              textAlign: TextAlign.center,
            ),
            onPressed: () =>
                Navigator.push(context, ChiefManagementRoute(family)),
          ),
          OutlinedButton(
            child: Text(
              S.announcement,
              textAlign: TextAlign.center,
            ),
            onPressed: () => Navigator.push(context, AnnouncementRoute()),
          ),
          Container(),
          RaisedButton(
            child: Text(S.destroy, textAlign: TextAlign.center),
            color: Colors.red,
            onPressed: () {
              showConfirmationDialog(
                context,
                S.familyDestroyConfirmationTitle,
                S.familyDestroyConfirmationContent,
                S.destroy,
                S.cancel,
                () {
                  var service = context.read<FamilyService>();
                  return service.destroy().then((_) {
                    context.read<FamilyState>().family = null;
                  }).catchError((e) => ErrorHandler.showError(context, e));
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class FamilyController extends StatefulWidget {
  const FamilyController({
    Key key,
    @required this.child,
  }) : super(key: key);

  final Widget child;

  @override
  _FamilyControllerState createState() => _FamilyControllerState();
}

class _FamilyControllerState extends State<FamilyController> {
  @override
  void initState() {
    super.initState();
    var service = context.read<FamilyService>();
    var state = context.read<FamilyState>();
    service
        .info()
        .then((family) => state.family = family)
        .catchError((e) => ErrorHandler.showError(context, e));
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

class _FamilyCreate extends StatefulWidget {
  @override
  __FamilyCreateState createState() => __FamilyCreateState();
}

class __FamilyCreateState extends State<_FamilyCreate> {
  final _formKey = GlobalKey<FormState>();
  final controller = TextEditingController();
  final _picker = ImagePicker();
  File _image;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: W.defaultAppBar,
        body: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  Text(
                    S.familyCreationTitle,
                    style: Theme.of(context).textTheme.headline5,
                  ),
                  SizedBox(height: 16.0),
                  Column(
                    mainAxisSize: MainAxisSize.max,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FamilyRequirement(
                        S.familyCreationMoneyRequirement,
                        RequirementType.money,
                        5000000,
                      ),
                      FamilyRequirement(
                        S.familyCreationHonorRequirement,
                        RequirementType.honor,
                        1000,
                      ),
                    ],
                  ),
                  SizedBox(height: 8.0),
                  Builder(builder: (context) {
                    if (_image == null) return Container();

                    return Image.file(_image, width: 200);
                  }),
                  SizedBox(height: 8.0),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: S.familyName,
                    ),
                    keyboardType: TextInputType.name,
                    textInputAction: TextInputAction.done,
                    controller: controller,
                    onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(),
                    validator: (value) {
                      if (value.isEmpty) return S.validationRequired;
                      return null;
                    },
                  ),
                  SizedBox(height: 8.0),
                  SizedBox(
                    width: double.infinity,
                    child: RaisedButton(
                      child: Text(S.chooseImage),
                      onPressed: () async {
                        var pickedFile =
                            await _picker.getImage(source: ImageSource.gallery);
                        if (pickedFile == null || pickedFile.path == null) {
                          return;
                        }
                        setState(() {
                          _image = File(pickedFile.path);
                        });
                      },
                    ),
                  ),
                  SizedBox(height: 8.0),
                  SizedBox(
                    width: double.infinity,
                    child: RaisedButton(
                      child: Text(S.create),
                      onPressed: () {
                        if (!_formKey.currentState.validate())
                          return; // form is not valid
                        if (_image == null) {
                          showErrorDialog(context, S.chooseImage);
                          return;
                        }

                        var service = context.read<FamilyService>();

                        // todo add loading state
                        service.found(controller.text, _image).then((_) {
                          service.info().then((family) {
                            context.read<FamilyState>().family = family;
                            return Navigator.pushReplacement(
                                context, FamilyDetailRoute(family));
                          });
                        }).catchError(
                            (e) => ErrorHandler.showError(context, e));
                      },
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum RequirementType { money, honor }

class FamilyRequirement extends StatelessWidget {
  const FamilyRequirement(
    this.requirement,
    this.type,
    this.value, {
    Key key,
  }) : super(key: key);

  final String requirement;
  final RequirementType type;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          margin: EdgeInsets.only(left: 32.0),
          height: 8.0,
          width: 8.0,
          decoration: new BoxDecoration(
            color: Theme.of(context).colorScheme.secondary,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: 16.0),
        Consumer<PlayerState>(
          builder: (context, state, child) {
            if (isMeet(state)) {
              return Text(
                requirement,
                style: Theme.of(context)
                    .textTheme
                    .subtitle2
                    .copyWith(decoration: TextDecoration.lineThrough),
              );
            }
            return child;
          },
          child: Text(
            requirement,
            style: Theme.of(context).textTheme.subtitle2,
          ),
        ),
      ],
    );
  }

  bool isMeet(PlayerState state) {
    switch (type) {
      case RequirementType.money:
        return state.player.balance >= value;
      case RequirementType.honor:
        return state.player.honor >= value;
      default:
        return false;
    }
  }
}

class FamiliesPageRoute<T> extends MaterialPageRoute<T> {
  FamiliesPageRoute()
      : super(
            builder: (BuildContext context) =>
                FamilyController(child: FamiliesPage()));
}

class FamilyDetailRoute<T> extends MaterialPageRoute<T> {
  final Family family;

  FamilyDetailRoute(this.family)
      : super(builder: (BuildContext context) => _FamilyDetail(family));
}

class _RegimesRoute<T> extends MaterialPageRoute<T> {
  final Family family;

  _RegimesRoute(this.family)
      : super(builder: (BuildContext context) => RegimesWidget(family: family));
}

class _AnnouncementsRoute<T> extends MaterialPageRoute<T> {
  final String family;

  _AnnouncementsRoute(this.family)
      : super(builder: (BuildContext context) => AnnouncementsWidget(family));
}

class _MembersRoute<T> extends MaterialPageRoute<T> {
  final Family family;

  _MembersRoute(this.family)
      : super(builder: (BuildContext context) => _MembersWidget(family));
}

class _BankRoute<T> extends MaterialPageRoute<T> {
  final String boss;

  _BankRoute(this.boss)
      : super(builder: (BuildContext context) => _BankWidget(boss));
}

class _ManagementWidgetRoute<T> extends MaterialPageRoute<T> {
  final Family family;

  _ManagementWidgetRoute(this.family)
      : super(builder: (BuildContext context) => _ManagementWidget(family));
}

class _CreateFamilyRoute<T> extends MaterialPageRoute<T> {
  _CreateFamilyRoute()
      : super(builder: (BuildContext context) => _FamilyCreate());
}
