import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:bot_toast/bot_toast.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'item.dart';

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
        '/': (context) => const SignUpScreen(),
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

  List<RouteItem>? nowRoute;
  final StreamController<List<RouteItem>?> _dataController =
      StreamController<List<RouteItem>?>();
  bool finish = false;
  final ScrollController _scrollController = ScrollController();

  Future<void> _onRefresh(String begin, String end) async {
    this.begin = begin;
    this.end = end;
    finish = false;
    _dataController.add([]);
    page = 0;
    try {
      var response = await Dio().get(
        'https://api.airrouter.top/route?begin_no=$begin&end_no=$end&page_size=20&page=$page',
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
      if (routes.isEmpty) {
        BotToast.showText(text: "路径不存在");
        nowRoute = null;
        _dataController.add(null);
        return;
      }
      nowRoute = routes;
      _dataController.add(nowRoute);
    } catch (e) {
      //print(e);
    }

    return;
  }

  void load() async {
    page++;
    var response = await Dio().get(
      'https://api.airrouter.top/route?begin_no=${begin!}&end_no=${end!}&page_size=20&page=$page',
    );
    var routes = (response.data as List).map((x) {
      var items = (x["route"] as List).map((ii) => Item.fromJson(ii)).toList();
      return RouteItem(
          items, x["begin_time"], x["between_time"], x["end_time"]);
    }).toList();
    if (routes.length < 20) {
      setState(() {
        finish = true;
      });
      BotToast.showText(text: "加载完毕");
      return;
    }
    nowRoute!.addAll(routes);
    _dataController.add(nowRoute);
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent) {
        if (nowRoute == null) return;
        if (finish) {
          BotToast.showText(text: "加载完毕");
          return;
        }
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
                  if (snapshot.data!.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  double padding = MediaQuery.of(context).size.width / 180;
                  if(kIsWeb) {
                    return ListView.builder(
                        controller: _scrollController,
                        itemCount: snapshot.data!.length * 2,
                        padding: EdgeInsets.all(padding + 5),
                        itemBuilder: (context, i) {
                          if (i ==  snapshot.data!.length * 2 - 1 && !finish) {
                            return const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }
                          if (i.isOdd) return const Divider();

                          final index = i ~/ 2;

                          return Theme(
                              data: Theme.of(context)
                                  .copyWith(dividerColor: Colors.transparent),
                              child: ScanResultTile(item: snapshot.data![index]));
                        });
                  }
                  return Scrollbar(
                    child: ListView.builder(
                        controller: _scrollController,
                        itemCount: snapshot.data!.length * 2,
                        padding: EdgeInsets.all(padding + 5),
                        itemBuilder: (context, i) {
                          if (i ==  snapshot.data!.length * 2 - 1 && !finish) {
                            return const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }
                          if (i.isOdd) return const Divider();

                          final index = i ~/ 2;

                          return Theme(
                              data: Theme.of(context)
                                  .copyWith(dividerColor: Colors.transparent),
                              child: ScanResultTile(item: snapshot.data![index]));
                        }),
                  );
                }),
          ),
        ],
      ),
    );
  }
}

class SignUpForm extends StatefulWidget {
  final Future<void> Function(String begin, String end) _onRefresh;

  const SignUpForm(this._onRefresh);

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
        SizedBox.fromSize(size: const Size(0, 30)),
        Text('路线搜索 demo', style: Theme.of(context).textTheme.headline4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            ...getInput(context),
            ElevatedButton(
              child: const Text('搜索'),
              style: ElevatedButton.styleFrom(
                  primary: Colors.black,
                  textStyle: const TextStyle(
                    color: Colors.white,
                  )),
              onPressed: () {
                FocusManager.instance.primaryFocus?.unfocus();
                widget._onRefresh(_beginCityNoController.text.toUpperCase(),
                    _endCityNoController.text.toUpperCase());
              },
            )
          ],
        ),
      ],
    );
  }

  List<Widget> getInput(BuildContext context) {
    if (MediaQuery.of(context).size.width > 800) {
      return [
        const Text("出发城市三字码"),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: SizedBox(
            width: min(400,
                max((MediaQuery.of(context).size.width - 300) / 3 - 60, 20)),
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
            width: min(400,
                max((MediaQuery.of(context).size.width - 300) / 3 - 60, 20)),
            child: TextFormField(
              controller: _endCityNoController,
              decoration: const InputDecoration(hintText: '到达城市'),
            ),
          ),
        ),
      ];
    } else {
      return [
        Column(
          children: [
            const Text("出发城市三字码"),
            SizedBox.fromSize(size: const Size(0, 30)),
            const Text("到达城市三字码"),
          ],
        ),
        Column(
          children: [
            SizedBox(
                width: min(400,
                    max((MediaQuery.of(context).size.width - 100) / 2, 20)),
                child: TextFormField(
                  controller: _beginCityNoController,
                  decoration: const InputDecoration(hintText: '出发城市'),
                ),
              ),
            SizedBox(
              width: min(400,
                  max((MediaQuery.of(context).size.width - 100) / 2 , 20)),
              child: TextFormField(
                controller: _endCityNoController,
                decoration: const InputDecoration(hintText: '到达城市'),
              ),
            ),
          ],
        )
      ];
    }
  }
}
