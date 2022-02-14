import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';

class ScanResultTile extends StatelessWidget {
  ScanResultTile({Key? key, required this.item}) : super(key: key);
  RouteItem item;

  Widget _buildTitle(BuildContext context) {
    var date =
        DateTime.fromMicrosecondsSinceEpoch(item.begin_time * 1000000).toUtc();
    String tile = "";
    if (item.items.length == 1) {
      if (item.items[0].source_train_no != null) {
        tile = "${item.items[0].source_train_no} 直达";
      }
      if (item.items[0].plane_no != null) {
        tile = "${item.items[0].plane_no} 直达";
      }
    } else {
      for (var i = 0; i < item.items.length; i++) {
        if (i.isOdd) continue;
        if (tile != "") {
          tile += " 转 ";
        }
        if (item.items[i].source_train_no != null) {
          tile += "${item.items[i].source_train_no}";
        }
        if (item.items[i].plane_no != null) {
          tile += "${item.items[i].plane_no}";
        }
      }
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          tile,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          "出发时间：${date.year}-${date.month}-${date.day} ${date.hour}:${date.minute}  用时：${item.between_time ~/ 3600} 小时 ${(item.between_time ~/ 60) % 60} 分 ${item.between_time % 60} 秒",
          style: Theme.of(context).textTheme.caption,
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: _buildTitle(context),
      children: _buildChildren(context),
    );
  }

  List<Widget> _buildChildren(BuildContext context) {
    List<Widget> widgets = [];
    for (var i = 0; i < item.items.length; i++) {
      switch (item.items[i].getType()) {
        case ItemType.transit:
          final end_time = DateTime.parse(item.items[i - 1].end_time!);
          final begin_time = DateTime.parse(item.items[i + 1].begin_time!);
          final time = begin_time.difference(end_time);
          if (item.items[i - 1].getType() == ItemType.train) {
            widgets.add(TransitItem(
              item: item.items[i],
              transitType: TransitType.train_to_plane,
              time: time,
            ));
          } else {
            widgets.add(TransitItem(
              item: item.items[i],
              transitType: TransitType.plane_to_train,
              time: time,
            ));
          }
          break;
        case ItemType.train:
          widgets.add(TrainItem(item: item.items[i]));
          break;
        case ItemType.plane:
          widgets.add(PlaneItem(item: item.items[i]));
      }
    }
    return widgets;
  }
}

class TrainItem extends StatelessWidget {
  TrainItem({Key? key, required this.item}) : super(key: key);
  Item item;

  Widget _buildAdvRow(BuildContext context, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: Theme.of(context).textTheme.caption),
          const SizedBox(
            width: 12.0,
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context)
                  .textTheme
                  .caption
                  ?.apply(color: Colors.black),
              softWrap: true,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          title: Text("火车"),
          subtitle: Text("车次：${item.source_train_no}",
              style: Theme.of(context)
                  .textTheme
                  .caption
                  ?.apply(color: Colors.black)),
          trailing: ElevatedButton(
            child: const Text('查看详情'),
            style: ElevatedButton.styleFrom(
                primary: Colors.blue,
                textStyle: const TextStyle(
                  color: Colors.white,
                )),
            onPressed: () {
              BotToast.showText(text: "开发中");
            },
          ),
        ),
        ListBody(
          children: [
            _buildAdvRow(context, "出发站",
                "${item.begin_train_station_name}(${item.begin_train_station_no})"),
            _buildAdvRow(context, "到达站",
                "${item.end_train_station_name}(${item.end_train_station_no})"),
            _buildAdvRow(context, "出发时间", "${item.begin_time}"),
            _buildAdvRow(context, "到达时间", "${item.end_time}"),
          ],
        )
      ],
    );
  }
}

class TransitItem extends StatelessWidget {
  TransitItem({Key? key, required this.item, required this.transitType, required this.time})
      : super(key: key);
  Item item;
  TransitType transitType;
  Duration time;

  Widget _buildAdvRow(BuildContext context, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: Theme.of(context).textTheme.caption),
          const SizedBox(
            width: 12.0,
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context)
                  .textTheme
                  .caption
                  ?.apply(color: Colors.black),
              softWrap: true,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          title: Text("中转"),
          subtitle: Text("城市：${item.city_name}(${item.city_no})",
              style: Theme.of(context)
                  .textTheme
                  .caption
                  ?.apply(color: Colors.black)),
          trailing: ElevatedButton(
            child: const Text('查看详情'),
            style: ElevatedButton.styleFrom(
                primary: Colors.blue,
                textStyle: const TextStyle(
                  color: Colors.white,
                )),
            onPressed: () {
              BotToast.showText(text: "开发中");
            },
          ),
        ),
        ListBody(
          children: getList(context),
        )
      ],
    );
  }

  List<Widget> getList(BuildContext context) {
    if (transitType == TransitType.train_to_plane) {
      return [
        _buildAdvRow(context, "起点",
            "${item.train_station_name}(${item.train_station_no})"),
        _buildAdvRow(
            context, "目的地", "${item.airport_name}(${item.airport_no})"),
        _buildAdvRow(context, "预计用时",
            "${item.time! ~/ 3600} 小时 ${(item.time! ~/ 60) % 60} 分 ${item.time! % 60} 秒"),
        _buildAdvRow(context, "可用时间",
            "${time.inHours} 小时 ${time.inMinutes % 60} 分 ${time.inSeconds % 60} 秒"),
      ];
    }
    return [
      _buildAdvRow(context, "起点", "${item.airport_name}(${item.airport_no})"),
      _buildAdvRow(context, "目的地",
          "${item.train_station_name}(${item.train_station_no})"),
      _buildAdvRow(context, "预计用时",
          "${item.time! ~/ 3600} 小时 ${(item.time! ~/ 60) % 60} 分 ${item.time! % 60} 秒"),
    ];
  }
}

class PlaneItem extends StatelessWidget {
  PlaneItem({Key? key, required this.item}) : super(key: key);
  Item item;

  Widget _buildAdvRow(BuildContext context, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: Theme.of(context).textTheme.caption),
          const SizedBox(
            width: 12.0,
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context)
                  .textTheme
                  .caption
                  ?.apply(color: Colors.black),
              softWrap: true,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          title: Text("飞机"),
          subtitle: Text("航班号：${item.plane_no}",
              style: Theme.of(context)
                  .textTheme
                  .caption
                  ?.apply(color: Colors.black)),
          trailing: ElevatedButton(
            child: const Text('查看详情'),
            style: ElevatedButton.styleFrom(
                primary: Colors.blue,
                textStyle: const TextStyle(
                  color: Colors.white,
                )),
            onPressed: () {
              BotToast.showText(text: "开发中");
            },
          ),
        ),
        ListBody(
          children: [
            _buildAdvRow(context, "出发机场",
                "${item.begin_airport_name}(${item.begin_airport_no})"),
            _buildAdvRow(context, "到达机场",
                "${item.end_airport_name}(${item.end_airport_no})"),
            _buildAdvRow(context, "出发时间", "${item.begin_time}"),
            _buildAdvRow(context, "到达时间", "${item.end_time}"),
          ],
        )
      ],
    );
  }
}

class RouteItem {
  late int begin_time;
  late int between_time;
  late int end_time;
  late List<Item> items;

  RouteItem(this.items, this.begin_time, this.between_time, this.end_time);
}

class Item {
  String? plane_no;
  String? begin_airport_no;
  String? begin_airport_name;
  String? begin_city_no;
  String? begin_city_name;
  String? end_airport_no;
  String? end_airport_name;
  String? end_city_no;
  String? end_city_name;
  String? begin_time;
  String? end_time;
  String? source_train_no;
  String? begin_train_station_name;
  String? begin_train_station_no;
  String? end_train_station_name;
  String? end_train_station_no;
  String? train_station_no;
  String? train_station_name;
  String? airport_no;
  String? airport_name;
  String? city_no;
  String? city_name;
  int? time;

  ItemType getType() {
    if (plane_no != null) {
      return ItemType.plane;
    } else if (source_train_no != null) {
      return ItemType.train;
    } else {
      return ItemType.transit;
    }
  }

  Item(
      {this.plane_no,
      this.begin_airport_no,
      this.begin_airport_name,
      this.begin_city_name,
      this.end_airport_name,
      this.end_city_name,
      this.end_time,
      this.begin_train_station_name,
      this.end_train_station_name,
      this.train_station_no,
      this.airport_no,
      this.city_no,
      this.time,
      this.begin_city_no,
      this.end_airport_no,
      this.end_city_no,
      this.source_train_no,
      this.begin_train_station_no,
      this.end_train_station_no,
      this.begin_time,
      this.airport_name,
      this.city_name,
      this.train_station_name}) {}

  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      plane_no: json["plane_no"] as String?,
      begin_airport_no: json["begin_airport_no"] as String?,
      begin_airport_name: json["begin_airport_name"] as String?,
      begin_city_no: json["begin_city_no"] as String?,
      begin_city_name: json["begin_city_name"] as String?,
      end_airport_no: json["end_airport_no"] as String?,
      end_airport_name: json["end_airport_name"] as String?,
      end_city_no: json["end_city_no"] as String?,
      end_city_name: json["end_city_name"] as String?,
      begin_time: json["begin_time"] as String?,
      end_time: json["end_time"] as String?,
      source_train_no: json["source_train_no"] as String?,
      begin_train_station_name: json["begin_train_station_name"] as String?,
      begin_train_station_no: json["begin_train_station_no"] as String?,
      end_train_station_name: json["end_train_station_name"] as String?,
      end_train_station_no: json["end_train_station_no"] as String?,
      train_station_no: json["train_station_no"] as String?,
      train_station_name: json["train_station_name"] as String?,
      airport_no: json["airport_no"] as String?,
      airport_name: json["airport_name"] as String?,
      city_no: json["city_no"] as String?,
      city_name: json["city_name"] as String?,
      time: json["time"] as int?,
    );
  }
}

enum ItemType {
  train,
  plane,
  transit,
}

enum TransitType {
  train_to_plane,
  plane_to_train,
}
