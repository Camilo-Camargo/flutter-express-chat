import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a blue toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String id = "";
  String room = "";

  @override
  Widget build(BuildContext context) {
    final dio = Dio();

    return Scaffold(
        body: Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white),
      child: Column(
        children: [
          Row(
            children: [
              Text("room"),
              Expanded(
                child: TextField(
                  onChanged: (text) => setState(() {
                    room = text;
                  }),
                ),
              ),
            ],
          ),
          Row(
            children: [
              Text("id"),
              Expanded(
                child: TextField(
                  onChanged: (text) => setState(() {
                    id = text;
                  }),
                ),
              ),
            ],
          ),
          TextButton(
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            WidgetChat(dio: dio, id: id, room: room)));
              },
              child: Text("Open room"))
        ],
      ),
    ));
  }
}

class WidgetChat extends StatefulWidget {
  final Dio dio;
  final String id;
  final String room;
  const WidgetChat(
      {super.key, required this.dio, required this.id, required this.room});

  @override
  State<StatefulWidget> createState() => _WidgetChatState();
}

class _WidgetChatState extends State<WidgetChat> {
  String msg = "";
  late Socket socket;
  late Timer timer;

  List<dynamic> messages = [];

  void fetchMessages(data) {
    widget.dio.get('http://192.168.0.122:3000/message',
        data: {"id": data["id"], "room": data["room"]}).then((value) {
      setState(() {
        messages = value.data["messages"];
      });
    });
  }

  @override
  void initState() {
    // TODO: implement initState

    socket = io(
        'http://192.168.0.122:3000',
        OptionBuilder().setTransports(['websocket']).setExtraHeaders(
            {"id": widget.id}).build());

    socket.onConnect((data) {
      fetchMessages({"id": widget.id, "room": widget.room});
    });
    socket.on('msg:new', (data) => fetchMessages(jsonDecode(data)));

    /*
    Timer.periodic(const Duration(seconds: 1), (timer) {
      timer = timer;
      fetchMessages({"id": widget.id, "room": widget.room});
    });
    */

    super.initState();
  }

  @override
  void dispose() {
    socket.disconnect();
    //timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: EdgeInsets.all(20),
        child: Column(children: [
          TextButton(
              onPressed: () =>
                  fetchMessages({"id": widget.id, "room": widget.room}),
              child: Text("Load Messages")),
          Expanded(
              child: ListView(
                  children: messages
                      .map((e) {
                        return Row(
                          children: [Text(e["id"]), Text(": "), Text(e["msg"])],
                        );
                      })
                      .toList()
                      .reversed
                      .toList())),
          Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: (text) => setState(() {
                    msg = text;
                  }),
                ),
              ),
              TextButton(
                  child: Text("Send"),
                  onPressed: () {
                    widget.dio.post('http://192.168.0.122:3000/message',
                        data: {"room": "general", "id": widget.id, "msg": msg});
                  })
            ],
          )
        ]),
      ),
    );
  }
}
