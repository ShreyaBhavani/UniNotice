import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'firebase_options.dart';
import 'config/theme.dart';
import 'config/constants.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/dashboard/student_dashboard.dart';
import 'services/database_service.dart';
import 'services/notification_service.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Initialize notifications
    await NotificationService().init(navigatorKey);

    // Configure Firebase Messaging for push notifications
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission();

    // Subscribe to a general topic so test push notifications
    // can be sent from Firebase Console without needing a token.
    await messaging.subscribeToTopic('all');

    // Listen for foreground messages and show as local notifications
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      if (notification != null) {
        NotificationService().showInstantNotification(
          title: notification.title ?? 'New Update',
          body: notification.body ?? 'You have a new message',
          payload: 'open_student_dashboard',
        );
      }
    });

    // When a notification is tapped and opens the app
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const StudentDashboard()),
        (route) => false,
      );
    });
    
    // Initialize sample data (creates staff/students if collections are empty)
    await DatabaseService().initializeSampleData();
  } catch (e) {
    // Already initialized, ignore
    print('Error during initialization: $e');
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      navigatorKey: navigatorKey,
      // Route used when tapping timetable reminder notification
      onGenerateRoute: (settings) {
        if (settings.name == '/studentDashboardFromNotification') {
          return MaterialPageRoute(
            builder: (_) => const StudentDashboard(),
          );
        }
        return null;
      },
      home: const SplashScreen(),
    );
  }
}
