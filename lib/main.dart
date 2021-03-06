import 'dart:developer';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:resurgence/authentication/service.dart';
import 'package:resurgence/authentication/state.dart';
import 'package:resurgence/bank/service.dart';
import 'package:resurgence/chat/chat.dart' as chat;
import 'package:resurgence/constants.dart';
import 'package:resurgence/family/service.dart';
import 'package:resurgence/family/state.dart';
import 'package:resurgence/item/service.dart';
import 'package:resurgence/multiplayer-task/service.dart';
import 'package:resurgence/network/client.dart';
import 'package:resurgence/notification/service.dart';
import 'package:resurgence/player/player.dart';
import 'package:resurgence/player/service.dart';
import 'package:resurgence/quest/service.dart';
import 'package:resurgence/real-estate/service.dart';
import 'package:resurgence/task/service.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'application.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Firebase.apps.isEmpty) {
    try {
      await Firebase.initializeApp(
        name: 'Resurgence',
        options: FirebaseOptions(
          apiKey: 'AIzaSyAtKPl8C8ARr3rKviG6kdbKjp9EjLKal-g',
          appId: '1:203290350160:android:bf3acbc376fb1de328f755',
          projectId: 'rsrgnc',
          messagingSenderId: '203290350160',
        ),
      );
    } catch (err, stackTrace) {
      var errMessage = 'Firebase application initialization error.';
      log(errMessage, error: err, stackTrace: stackTrace);
      Sentry.captureException(
        err,
        stackTrace: stackTrace,
        hint: errMessage,
      );
    }
  }

  // Monitoring
  final analytics = FirebaseAnalytics();
  analytics.setAnalyticsCollectionEnabled(!S.isInDebugMode);

  final authenticationState = AuthenticationState(analytics: analytics);
  final client = Client(authenticationState);

  // Authentication
  final authenticationStateProvider = ChangeNotifierProvider.value(
    value: authenticationState,
  );
  final authenticationServiceProvider = Provider(
    create: (_) => AuthenticationService(client, analytics: analytics),
  );

  // Player
  final playerStateProvider = ChangeNotifierProvider(
    create: (BuildContext context) => PlayerState(),
  );
  final playerServiceProvider = Provider(
    create: (_) => PlayerService(client),
  );

  // Task
  final taskServiceProvider = Provider(
    create: (_) => TaskService(client, analytics: analytics),
  );

  final itemServiceProvider = Provider(
    create: (_) => ItemService(client),
  );

  final bankServiceProvider = Provider(
    create: (_) => BankService(client),
  );

  // Real Estate
  final realEstateServiceProvider = Provider(
    create: (_) => RealEstateService(client),
  );

  // Family Estate
  final familyServiceProvider = Provider(
    create: (_) => FamilyService(client),
  );
  final familyStateProvider = ChangeNotifierProvider(
    create: (context) => FamilyState(),
  );

  // Chat
  final chat.ChatState _chatState = chat.ChatState();
  final chatStateProvider = ChangeNotifierProvider.value(
    value: _chatState,
  );
  final chatClientProvider = Provider<chat.Client>(
    create: (_) => chat.Client(_chatState, authenticationState),
    lazy: false,
  );

  // Multiplayer Task
  final multiplayerServiceProvider = Provider(
    create: (_) => MultiplayerService(client),
  );

  // Notification Message
  final messageServiceProvider = Provider(
    create: (_) => MessageService(client),
  );

  // Quest
  final questServiceProvider = Provider(
    create: (_) => QuestService(client),
  );

  var mainApp = MultiProvider(
    providers: [
      // Authentication
      authenticationStateProvider,
      authenticationServiceProvider,

      // Player
      playerServiceProvider,
      playerStateProvider,

      // Task
      taskServiceProvider,

      // Item
      itemServiceProvider,

      // Bank
      bankServiceProvider,

      // Real Estate
      realEstateServiceProvider,

      // Family
      familyServiceProvider,
      familyStateProvider,

      // Chat
      chatClientProvider,
      chatStateProvider,

      // Multiplayer Task
      multiplayerServiceProvider,

      // Notification Message
      messageServiceProvider,

      // Quest
      questServiceProvider,
    ],
    child: Application(analytics: analytics),
  );

  if (S.isInDebugMode) {
    runApp(mainApp);
  } else {
    await SentryFlutter.init(
      (options) {
        options.dsn = S.DSN;
      },
      // Init your App.
      appRunner: () => runApp(mainApp),
    );
  }
}
