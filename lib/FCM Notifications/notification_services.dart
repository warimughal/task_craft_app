// ignore_for_file: avoid_print, unused_field, unused_local_variable, prefer_const_constructors, use_build_context_synchronously, avoid_function_literals_in_foreach_calls

import 'dart:io';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:task_craft_app/home/assignedProjectsScreen.dart';

class NotificationServices {
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  void requestNotificationPermission() async {
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      announcement: true,
      badge: true,
      carPlay: true,
      criticalAlert: true,
      provisional: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('user granted permission');
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      print('user granted provisional permission');
    } else {
      print('user denied permission');
    }
  }

  void requestPermission() async {}

  void initLocalNotifications(
      BuildContext context, RemoteMessage message) async {
    var androidInitializationSettings = AndroidInitializationSettings('logo');

    var initializationSetting = InitializationSettings(
      android: androidInitializationSettings,
    );
    await _flutterLocalNotificationsPlugin.initialize(initializationSetting,
        onDidReceiveNotificationResponse: (payload) {
      handleMessage(context, message);
    });
  }

  void firebaseInit(BuildContext context) {
    FirebaseMessaging.onMessage.listen((message) {
      if (kDebugMode) {
        print(message.notification!.title.toString());
        print(message.notification!.body.toString());
        print(message.data['type']);
        print(message.data['id']);
      }

      if (Platform.isAndroid) {
        initLocalNotifications(context, message);
      } else {
        initLocalNotifications(context, message);
        showNotification(message);
      }

      showNotification(message);
    });
  }

  Future<void> showNotification(RemoteMessage message) async {
    AndroidNotificationChannel channel = AndroidNotificationChannel(
      Random.secure().nextInt(100000).toString(),
      'high_importance_channel',
      importance: Importance.max,
    );

    AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      channel.id.toString(),
      channel.name.toString(),
      channelDescription: 'your channel description',
      importance: Importance.high,
      priority: Priority.high,
      ticker: 'ticker',
    );

    DarwinNotificationDetails darwinNotificationDetails =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
    );

    Future.delayed(Duration.zero, () {
      _flutterLocalNotificationsPlugin.show(
          0,
          message.notification!.title.toString(),
          message.notification!.body.toString(),
          notificationDetails);
    });
  }

  Future<String> getDeviceToken() async {
    String? token = await messaging.getToken();
    return token!;
  }

  void isTokenRefresh() async {
    messaging.onTokenRefresh.listen((event) {
      event.toString();
      print('refresh');
    });
  }

//   Future<void> setupInteractMessage(BuildContext context) async {
//     //when app is terminated
//     RemoteMessage? initialMessage =
//         await FirebaseMessaging.instance.getInitialMessage();

//     if (initialMessage != null) {
//       handleMessage(context, initialMessage);
//     }

// //when app is in the foreground
//     FirebaseMessaging.onMessage.listen((message) {
//       if (kDebugMode) {
//         print(message.notification!.title.toString());
//         print(message.notification!.body.toString());
//         print(message.data['type']);
//         print(message.data['id']);
//       }

//       if (Platform.isAndroid) {
//         initLocalNotifications(context, message);
//       } else {
//         initLocalNotifications(context, message);
//         showNotification(message);
//       }

//       showNotification(message);
//     });

//     //when notification is tapped and app is in the background
//     FirebaseMessaging.onMessageOpenedApp.listen((event) {
//       handleMessage(context, event);
//     });
//   }

  Future<void> setupInteractMessage(BuildContext context) async {
    FirebaseMessaging.onMessage.listen((message) {
      if (Platform.isAndroid) {
        initLocalNotifications(context, message);
      } else {
        initLocalNotifications(context, message);
        showNotification(message);
      }
    });

    // when notification is tapped and app is in the background
    FirebaseMessaging.onMessageOpenedApp.listen((event) {
      handleMessage(context, event);
    });

    // when app is terminated
    RemoteMessage? initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();

    if (initialMessage != null) {
      handleMessage(context, initialMessage);
    }
  }

  void handleMessage(BuildContext context, RemoteMessage message) {
    if (message.data['type'] == 'message') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AssignedProjectScreen()),
      );
    } else if (message.data['type'] == 'message') {
      String projectName = message.data['projectName'] ?? '';
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AssignedProjectScreen(),
        ),
      );
    }
  }

  Future<Map<String, String>> fetchUsersData() async {
    Map<String, String> usersData = {};

    try {
      QuerySnapshot querySnapshot =
          await FirebaseFirestore.instance.collection('users').get();

      querySnapshot.docs.forEach((doc) {
        String email = doc['userEmail'];
        String token = doc['deviceToken'];

        if (email.isNotEmpty && token.isNotEmpty) {
          usersData[email] = token;
        }
      });
    } catch (e) {
      print('Error fetching users data: $e');
    }

    return usersData;
  }
}




// void handleMessage(BuildContext context, RemoteMessage message) {
//   if (message.data['type'] == 'message') {
//     String projectName = message.data['projectName'] ?? ''; // Extract projectName from message
//     Navigator.push(
//         context, MaterialPageRoute(builder: (context) => AssignedTasksScreen(projectName: projectName)));
//   }
// }

