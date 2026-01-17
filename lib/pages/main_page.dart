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
  var _isRefreshing = false;
  String _loadingMessage = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Games'),
        actions: [
          IconButton(
            onPressed: _isRefreshing ? null : _refreshData,
            icon: _isRefreshing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.refresh),
            tooltip: "Refresh",
          )
        ],
      ),
      body: _isRefreshing ? _buildLoadingWidget() : _buildGamesList(),
    );
  }

  Future<void> _refreshData() async {
    setState(() {
      _isRefreshing = true;
      _games = [];
      _loadingMessage = 'Fetching games from Steam...';
    });

    var games = await _apiService.fetchAllGames((gamesLoaded) {
      setState(() {
        _loadingMessage = 'Loaded $gamesLoaded games...';
      });
    });

    setState(() {
      _isRefreshing = false;
      _games = games;
    });
  }

  Widget _buildLoadingWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            _loadingMessage,
            style: const TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
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
