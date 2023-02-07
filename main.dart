import 'package:flutter/material.dart';
import 'dart:async';
import 'package:telephony/telephony.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:smsspamfilter/classifier.dart';

int id = 0;

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

backgroundMessageHandler(SmsMessage message) {
  debugPrint("onBackgroundMessage called");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );
  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,

  );

  runApp(MyApp());
}


class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _message = "";
  final telephony = Telephony.instance;
  late Classifier _classifier;
  late List<Widget> _children;
  late TextEditingController _controller;
  List<SmsMessage> spamMessages = [];


  @override
  void initState() {
    super.initState();
    initPlatformState();
    _controller = TextEditingController();
    _classifier = Classifier();
    _children = [];
    _children.add(Container());
  }

  onMessage(SmsMessage message) async {
    telephony.listenIncomingSms(
        onNewMessage: (SmsMessage message) {
          // Handle message


          var prediction = _classifier.classify(message.body!);


          _showNotification(message.address!, message.body!);


          if (prediction[1] > prediction[0])
            {
              _showNotification(message.address!, message.body!);
            }
          else {
            setState(() {
              spamMessages.add(message);
            });

          }
        },
        onBackgroundMessage: backgroundMessageHandler
    );
    setState(() {
      _message = message.body ?? "Error reading message body.";

    });
  }


  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {

    final bool? result = await telephony.requestPhoneAndSmsPermissions;

    if (result != null && result) {
      telephony.listenIncomingSms(
          onNewMessage: onMessage, onBackgroundMessage: backgroundMessageHandler);
    }

    if (!mounted) return;
  }

  Future<void> _showNotification(String sender, String messageContent) async {

    const AndroidNotificationDetails androidNotificationDetails =
    AndroidNotificationDetails('your channel id', 'your channel name',
        channelDescription: 'your channel description',
        importance: Importance.max,
        priority: Priority.high,
        ticker: 'ticker');

    const NotificationDetails notificationDetails =
    NotificationDetails(android: androidNotificationDetails);
    await flutterLocalNotificationsPlugin.show(
        id++, sender, messageContent, notificationDetails,
        payload: 'item x');
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
        home: Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0.0,
            toolbarHeight: 70,
            title: const Text('SMS Spam Filter'),
            centerTitle: true,
            flexibleSpace: Container(
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.only(bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20)),
                gradient: LinearGradient(
                  colors: [Colors.teal, Colors.white10],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter
                )
              ),
            ),

          ),
          body: Column(

            // mainAxisAlignment: MainAxisAlignment.center,
            children: [

              // Center(child: Text("Latest received SMS: $_message")),
              ListView.builder(
                itemCount: spamMessages.length,
                scrollDirection: Axis.vertical,
                shrinkWrap: true,
                itemBuilder: (context, index) {
                return ListTile(
                  title: Text(spamMessages[index].address!),
                  subtitle: Text(spamMessages[index].body!),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(onPressed: () {
                        setState(() {
                          spamMessages.remove(spamMessages.elementAt(index));
                        });
                      },
                          icon: const Icon(Icons.delete)),
                    ],
                  ),
                );
              },)
            ],
          ),
        ));
  }
}
