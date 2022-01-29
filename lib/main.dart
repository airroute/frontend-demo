import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:bot_toast/bot_toast.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:untitled2/item.dart';

void main() => runApp(const SignUpApp());

class SignUpApp extends StatefulWidget {
  const SignUpApp();

  @override
  State<SignUpApp> createState() => _SignUpAppState();
}

class _SignUpAppState extends State<SignUpApp> {
  int idx = 0;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: true,
      builder: BotToastInit(),
      navigatorObservers: [
        BotToastNavigatorObserver(),
      ],
      color: Colors.lightBlue,
      title: "路线搜索 demo",
      routes: {
        '/': (context) => SignUpScreen(),
      },
    );
  }
}

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  int page = 0;
  String? begin;
  String? end;

  List<RouteItem>? now_route = null;
  StreamController<List<RouteItem>?> _dataController =
      StreamController<List<RouteItem>?>();
  bool _isFinash = false;
  ScrollController _scrollController = ScrollController();

  Future<void> _onRefresh(String begin, String end) async {
    this.begin = begin;
    this.end = end;
    _isFinash = false;
    _dataController.add([]);
    this.page = 0;
    try {
      var response = await Dio().get(
        'https://api.airrouter.top/route?begin_no=${begin}&end_no=${end}&page_size=20&page=$page',
        options: Options(
          validateStatus: (status) {
            return true;
          },
        ),
      );
      var routes = (response.data as List).map((x) {
        var items =
            (x["route"] as List).map((ii) => Item.fromJson(ii)).toList();
        return RouteItem(
            items, x["begin_time"], x["between_time"], x["end_time"]);
      }).toList();
      if (routes.length == 0) {
        BotToast.showText(text: "路径不存在");
        now_route = null;
        _dataController.add(null);
        return;
      }
      now_route = routes;
      _dataController.add(now_route);
    } catch (e) {
      //print(e);
    }

    return;
  }

  void load() async {
    this.page++;
    var response = await Dio().get(
      'https://api.airrouter.top/route?begin_no=${begin!}&end_no=${end!}&page_size=20&page=$page',
    );
    var routes = (response.data as List).map((x) {
      var items = (x["route"] as List).map((ii) => Item.fromJson(ii)).toList();
      return RouteItem(
          items, x["begin_time"], x["between_time"], x["end_time"]);
    }).toList();
    if (routes.length == 0) {
      _isFinash = true;
      return;
    }
    now_route!.addAll(routes);
    _dataController.add(now_route);
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent) {
        if (now_route == null) return;
        if (_isFinash) return;
        if (begin == null) return;
        if (end == null) return;
        load();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: Column(
        children: [
          Center(
              child: SizedBox(
            width: min(1200, max(MediaQuery.of(context).size.width - 200, 400)),
            child: SignUpForm(_onRefresh),
          )),
          const Divider(
            height: 30.0,
            indent: 0,
            color: Colors.black,
          ),
          Expanded(
            child: StreamBuilder<List<RouteItem>?>(
                stream: _dataController.stream,
                initialData: null,
                builder: (context, snapshot) {
                  if (snapshot.data == null) {
                    return Container();
                  }
                  print(snapshot.data!.length);
                  if (snapshot.data!.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  return ListView.builder(
                      controller: _scrollController,
                      itemCount: snapshot.data!.length,
                      padding: const EdgeInsets.all(16.0),
                      itemBuilder: (context, i) {
                        return ScanResultTile(item: snapshot.data![i]);
                      });
                }),
          ),
        ],
      ),
    );
  }
}

class SignUpForm extends StatefulWidget {
  final Future<void> Function(String begin, String end) _onRefresh;

  const SignUpForm(@required this._onRefresh);

  @override
  _SignUpFormState createState() => _SignUpFormState();
}

class _SignUpFormState extends State<SignUpForm> {
  final _beginCityNoController = TextEditingController();
  final _endCityNoController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('路线搜索 demo', style: Theme.of(context).textTheme.headline4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            const Text("出发城市三字码"),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: SizedBox(
                width: min(
                    400,
                    max((MediaQuery.of(context).size.width - 300) / 3 - 60,
                        20)),
                child: TextFormField(
                  controller: _beginCityNoController,
                  decoration: const InputDecoration(hintText: '出发城市'),
                ),
              ),
            ),
            const Text("到达城市三字码"),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: SizedBox(
                width: min(
                    400,
                    max((MediaQuery.of(context).size.width - 300) / 3 - 60,
                        20)),
                child: TextFormField(
                  controller: _endCityNoController,
                  decoration: const InputDecoration(hintText: '到达城市'),
                ),
              ),
            ),
            ElevatedButton(
              child: const Text('搜索'),
              style: ElevatedButton.styleFrom(
                  primary: Colors.black,
                  textStyle: const TextStyle(
                    color: Colors.white,
                  )),
              onPressed: () {
                if (_beginCityNoController.text.length != 3 ||
                    !(RegExp(r'[A-Za-z]{3}')
                        .hasMatch(_beginCityNoController.text))) {
                  BotToast.showText(text: "请输入正确的出发城市三字码");
                  return;
                }
                if (_endCityNoController.text.length != 3 ||
                    !(RegExp(r'[A-Za-z]{3}')
                        .hasMatch(_endCityNoController.text))) {
                  BotToast.showText(text: "请输入正确的到达城市三字码");
                  return;
                }
                widget._onRefresh(_beginCityNoController.text.toUpperCase(),
                    _endCityNoController.text.toUpperCase());
              },
            )
          ],
        ),
      ],
    );
  }
}
