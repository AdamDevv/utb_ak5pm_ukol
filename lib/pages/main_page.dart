import 'package:flutter/material.dart';
import 'package:utb_ak5pm_ukol/models/game.dart';

import '../services/steam_api_service.dart';

class GamesPage extends StatefulWidget {
  const GamesPage({super.key});

  @override
  State<StatefulWidget> createState() => _GamesPageState();
}

class _GamesPageState extends State<GamesPage> {
  final SteamApiService _apiService = SteamApiService();
  final ScrollController _scrollController = ScrollController();

  List<Game> _games = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Games'),
        actions: [
          IconButton(
            onPressed: _refreshData,
            icon: const Icon(Icons.refresh),
            tooltip: "Refresh",
          )
        ],
      ),
      body: _buildGamesList(),
    );
  }

  Future<void> _refreshData() async {
    setState(() {
      _games = [];
    });
    var games = await _apiService.fetchAllGames();
    setState(() {
      _games = games;
    });
  }

  Widget _buildGamesList() {
    return ListView.builder(
      controller: _scrollController,
      itemCount: _games.length,
      itemBuilder: (context, index) {
        if (index == _games.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final game = _games[index];
        return _buildGameTile(game);
      },
    );
  }

  Widget _buildGameTile(Game game) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        title: Text(
          game.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
