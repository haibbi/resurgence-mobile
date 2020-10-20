import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:resurgence/authentication/state.dart';
import 'package:resurgence/constants.dart';
import 'package:resurgence/enum.dart';
import 'package:resurgence/player/service.dart';
import 'package:resurgence/ui/button.dart';
import 'package:resurgence/ui/error_handler.dart';

class PlayerCreationPage extends StatefulWidget {
  final Function onDone;

  const PlayerCreationPage({Key key, this.onDone}) : super(key: key);

  @override
  _PlayerCreationPageState createState() => _PlayerCreationPageState();
}

class _PlayerCreationPageState extends State<PlayerCreationPage> {
  final _formKey = GlobalKey<FormState>();
  final nicknameController = TextEditingController();

  AbstractEnum _race;
  List<AbstractEnum> _races = [
    AbstractEnum(key: 'COSA_NOSTRA', value: S.cosaNostra),
    AbstractEnum(key: 'YAKUZA', value: S.yakuza),
  ];

  @override
  void initState() {
    super.initState();
    _race = _races.first;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: W.defaultAppBar,
      body: Center(
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Column(
                children: <Widget>[
                  FittedBox(
                    child: Text(
                      S.playerCreationTitle,
                      style: Theme.of(context).primaryTextTheme.headline6,
                    ),
                  ),
                  SizedBox(height: 4.0),
                  FittedBox(
                    child: Text(
                      S.playerCreationDescription,
                      style: Theme.of(context).primaryTextTheme.headline6,
                    ),
                  ),
                  SizedBox(height: 24.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: this
                        ._races
                        .map(
                          (e) => GestureDetector(
                            onTap: () {
                              setState(() {
                                this._race = e;
                              });
                            },
                            child: RaceWidget(
                              e,
                              selected: this._race == e,
                            ),
                          ),
                        )
                        .toList(growable: false),
                  ),
                  SizedBox(height: 24.0),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: S.nickname,
                    ),
                    keyboardType: TextInputType.text,
                    textInputAction: TextInputAction.done,
                    controller: nicknameController,
                    onFieldSubmitted: (value) =>
                        FocusScope.of(context).nextFocus(),
                    validator: (value) {
                      if (value.isEmpty) return S.validationRequired;
                      return null;
                    },
                  ),
                  SizedBox(height: 24.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Button(
                        onPressed: () {
                          if (!_formKey.currentState.validate())
                            return; // form is not valid

                          var nickname = nicknameController.text;
                          context
                              .read<PlayerService>()
                              .create(nickname, _race)
                              .then((player) => widget.onDone())
                              .catchError(
                                  (e) => ErrorHandler.showError(context, e));
                        },
                        child: Text(S.create),
                      ),
                      Button(
                        onPressed: () =>
                            context.read<AuthenticationState>().logout(),
                        child: Text(S.logout),
                      ),
                    ],
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

class RaceWidget extends StatelessWidget {
  final AbstractEnum race;
  final bool selected;

  const RaceWidget(
    this.race, {
    Key key,
    this.selected = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: selected ? Colors.grey[800] : null,
        border: Border.all(
          color: Colors.grey,
        ),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Text(
            race.value,
            style: Theme.of(context).textTheme.headline6,
          ),
        ),
      ),
    );
  }
}
