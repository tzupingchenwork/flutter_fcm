import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// 初始化本地通知插件
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// 用於處理後台訊息的函數
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("Handling a background message: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // 初始化本地通知設定
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const DarwinInitializationSettings darwinInitializationSettings =
      DarwinInitializationSettings();
  const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: darwinInitializationSettings);
  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse:
        (NotificationResponse notificationResponse) {
      switch (notificationResponse.notificationResponseType) {
        case NotificationResponseType.selectedNotification:
          debugPrint(
              'NotificationResponseType.selectedNotification:${notificationResponse.payload}');
          break;
        case NotificationResponseType.selectedNotificationAction:
          debugPrint('NotificationResponseType.selectedNotificationAction:');
          break;
      }
    },
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FCM Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  MyHomePageState createState() => MyHomePageState();
}

class MyHomePageState extends State<MyHomePage> {
  List<String> messages = [];
  String _message = '';
  String? token;

  @override
  void initState() {
    super.initState();
    _initFirebaseMessaging();
  }

  Future<void> _initFirebaseMessaging() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    // 請求權限
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint("用戶已授予消息權限");

      // 設置消息處理器
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        // 顯示通知
        _showNotification(message.notification?.title ?? 'No title',
            message.notification?.body ?? 'No body');
        _handleMessage(message);
      });
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);
      FirebaseMessaging.onBackgroundMessage(
          _firebaseMessagingBackgroundHandler);

      token = await messaging.getToken();
      debugPrint("FCM Token: $token");
    } else {
      debugPrint("用戶未授權消息");
    }
  }

  void _showNotification(String title, String body) async {
    var bigTextStyleInformation = BigTextStyleInformation(
      body,
      htmlFormatBigText: true,
      contentTitle: title,
      htmlFormatContentTitle: true,
      summaryText: body,
      htmlFormatSummaryText: true,
    );

    var androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'your channel id',
      'your channel name',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: false,
      styleInformation: bigTextStyleInformation,
    );

    var iosDetails = const DarwinNotificationDetails();
    var details = NotificationDetails(
        android: androidPlatformChannelSpecifics, iOS: iosDetails);
    await flutterLocalNotificationsPlugin.show(
      0,
      title,
      body,
      details,
      payload: 'item x',
    );
  }

  void _showHistoryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("歷史訊息"),
        content: SingleChildScrollView(
          child: ListBody(
            children: messages.map((msg) => Text(msg)).toList(),
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('關閉'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  void _handleMessage(RemoteMessage message) {
    final messageText = message.notification?.body ?? 'Empty message';
    setState(() {
      _message = messageText;
      messages.add(messageText);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Firebase Messaging Demo',
      theme: ThemeData(
        primarySwatch: Colors.blueGrey, // 更新主題顏色
        visualDensity: VisualDensity.adaptivePlatformDensity,
        textTheme: const TextTheme(
          // 自定義文本樣式
          titleLarge: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
          bodyMedium: TextStyle(fontSize: 14.0, fontFamily: 'Hind'),
        ),
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('FCM Demo'),
          actions: <Widget>[
            IconButton(
              icon: const Icon(Icons.notifications),
              onPressed: () {
                _showHistoryDialog();
              },
            ),
          ],
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              elevation: 4.0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.message,
                      size: 100,
                      color: Colors.blue,
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Message: $_message',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8.0),
                    Text(
                      'Token: ${token ?? 'No token available'}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
