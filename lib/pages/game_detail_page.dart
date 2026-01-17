import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class GameDetailPage extends StatefulWidget {
  final int appid;
  final String gameName;

  const GameDetailPage({
    super.key,
    required this.appid,
    required this.gameName,
  });

  @override
  State<GameDetailPage> createState() => _GameDetailPageState();
}

class _GameDetailPageState extends State<GameDetailPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.gameName),
      ),
    );
  }
}
