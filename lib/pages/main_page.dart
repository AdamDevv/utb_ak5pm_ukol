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

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Game> _games = [];
  var _isRefreshing = false;
  var _isLoading = false;
  String _loadingMessage = '';

  bool _isSearching = false;
  List<Game> _searchResults = [];

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
      body: _isRefreshing ? _buildLoadingWidget() : _buildContent(),
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

  Future<void> _onSearchChanged(String query) async {
    if (query.isEmpty) {
      setState(() {
        _isSearching = false;
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    final results = await _dbService.searchGames(query);
    setState(() {
      _searchResults = results;
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

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        //Search bar
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search games...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _onSearchChanged('');
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey[100],
            ),
            onChanged: _onSearchChanged,
          ),
        ),

        // Header
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Latest Modified Games',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 8),

        // Games list
        Expanded(
          child: _buildGamesList(),
        ),
      ],
    );
  }

  Widget _buildGamesList() {
    final displayedGames = _isSearching ? _searchResults : _games;

    if (displayedGames.isEmpty && !_isLoading) {
      return Center(
        child: Text(
          _isSearching ? 'No games found' : 'No games loaded. Tap refresh to load.',
          style: const TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      itemCount: displayedGames.length,
      itemBuilder: (context, index) {
        if (index == displayedGames.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final game = displayedGames[index];
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
