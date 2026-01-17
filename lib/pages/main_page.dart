import 'package:flutter/material.dart';
import 'package:utb_ak5pm_ukol/models/game.dart';

import '../services/database_service.dart';
import '../services/steam_api_service.dart';

class GamesPage extends StatefulWidget {
  const GamesPage({super.key});

  @override
  State<StatefulWidget> createState() => _GamesPageState();
}

class _GamesPageState extends State<GamesPage> {
  final DatabaseService _dbService = DatabaseService.instance;
  final SteamApiService _apiService = SteamApiService();
  final ScrollController _scrollController = ScrollController();

  List<Game> _games = [];
  var _isRefreshing = false;
  var _isLoading = false;
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

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
    });

    final gamesInDb = await _dbService.getGamesCount();

    if (gamesInDb == 0) {
      await _refreshData();
    } else {
      _games = await _dbService.getGamesSortedByLastModified(50, 0);
    }

    setState(() {
      _isLoading = false;
    });
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
      _loadingMessage = 'Saving to database';
    });

    await _dbService.deleteAllGames();
    await _dbService.insertGames(games);

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
