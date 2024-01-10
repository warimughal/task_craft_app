// ignore_for_file: avoid_print, use_build_context_synchronously

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:task_craft_app/FCM%20Notifications/notification_services.dart';
import 'package:task_craft_app/firebase_options.dart';
import 'package:task_craft_app/home/homeScreen.dart';
import 'package:task_craft_app/splashscreen/splashscreen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  NotificationServices notificationServices = NotificationServices();
  notificationServices.requestNotificationPermission();

  // Get the initial message when the app is terminated
  RemoteMessage? initialMessage =
      await FirebaseMessaging.instance.getInitialMessage();

  // Handle the initial message if it exists
  if (initialMessage != null) {
    notificationServices.handleMessage(
      navigatorKey.currentState!.overlay!.context,
      initialMessage,
    );
  }

  runApp(const MyApp());
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print(message.notification!.title.toString());
  print(message.notification!.body.toString());
  print(message.data.toString());
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  User? user;

  @override
  void initState() {
    super.initState();
    user = FirebaseAuth.instance.currentUser;
    print(user?.uid.toString());

    // Initialize notification services if the user is authenticated
    if (user != null) {
      NotificationServices notificationServices = NotificationServices();
      notificationServices.setupInteractMessage(context);
    }

    // Listen for app lifecycle changes
    WidgetsBinding.instance.addObserver(AppLifecycleObserver());
  }

  @override
  Widget build(BuildContext context) {
    // Initialize notification services
    NotificationServices notificationServices = NotificationServices();
    notificationServices.setupInteractMessage(context);

    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.orange,
      ),
      home: user != null ? const HomeScreen() : const SplashScreen(),
    );
  }
}

class AppLifecycleObserver extends WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {}
  }
}
