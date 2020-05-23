import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:resurgence/authentication/state.dart';
import 'package:resurgence/constants.dart';
import 'package:resurgence/menu_page.dart';
import 'package:resurgence/player/player.dart';
import 'package:resurgence/player/player_creation_page.dart';
import 'package:resurgence/player/service.dart';
import 'package:resurgence/profile/profile_page.dart';
import 'package:resurgence/ui/button.dart';

class PlayerControlPage extends StatefulWidget {
  @override
  _PlayerControlPageState createState() => _PlayerControlPageState();
}

class _PlayerControlPageState extends State<PlayerControlPage> {
  Future<Player> futurePlayer;

  @override
  void initState() {
    super.initState();
    futurePlayer = fetchPlayer();
  }

  Future<Player> fetchPlayer() => context
      .read<PlayerService>()
      .info()
      .then((player) => onPlayerInfoSucceed(player))
      .catchError((e) => onPlayerInfoError(e));

  Player onPlayerInfoSucceed(Player player) {
    context.read<PlayerState>().updatePlayer(player);
    return player;
  }

  void onPlayerInfoError(e) {
    if (e is DioError &&
        e.type == DioErrorType.RESPONSE &&
        e.response.statusCode == 404) {
      throw PlayerNotCreatedError();
    }
    // todo maybe dead player comes here to re-create new player
    throw e;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Player>(
      future: futurePlayer,
      builder: (BuildContext context, AsyncSnapshot<Player> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _loadingWidget();
        } else if (snapshot.hasError) {
          if (snapshot.error is PlayerNotCreatedError) {
            return _playerCreateWidget(context);
          }
          return _onErrorWidget(context);
        }

        return MenuPage();
      },
    );
  }

  Widget _onErrorWidget(BuildContext context) {
    return Scaffold(
      appBar: W.defaultAppBar,
      body: Center(
        child: Column(
          children: [
            Text('An error occurred while fetching player info'),
            refreshButton(context),
            logoutButton(context),
          ],
        ),
      ),
    );
  }

  Widget _playerCreateWidget(BuildContext context) {
    return Scaffold(
      appBar: W.defaultAppBar,
      body: Row(
        children: [
          Button(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (BuildContext context) => PlayerCreationPage(),
                ),
              ).then(
                (value) => setState(() {
                  futurePlayer = fetchPlayer();
                }),
              );
            },
            child: Text('create a player'),
          ),
          logoutButton(context),
        ],
      ),
    );
  }

  Widget _loadingWidget() {
    return Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget logoutButton(BuildContext context) {
    return Button(
      child: Text(S.logout),
      onPressed: () => context.read<AuthenticationState>().logout(),
    );
  }

  Widget refreshButton(BuildContext context) {
    return Button(
      child: Text(S.reload),
      onPressed: () => setState(() {
        futurePlayer = fetchPlayer();
      }),
    );
  }
}

class PlayerNotCreatedError extends Error {}