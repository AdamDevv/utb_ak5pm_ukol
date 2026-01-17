import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:utb_ak5pm_ukol/models/game.dart';
import 'package:utb_ak5pm_ukol/pages/game_detail_page.dart';

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
  late SharedPreferences _prefs;

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  static const _prefsKeyTotalGamesCount = 'total_games_count';
  static const _prefsKeyLastUpdateTime = "last_update_time";

  List<Game> _games = [];
  bool _allGamesLoaded = false;

  bool _isRefreshing = false;
  bool _isLoading = false;
  String _loadingMessage = '';

  bool _isSearching = false;
  List<Game> _searchResults = [];

  int _totalGamesCount = 0;
  DateTime? _lastUpdateTime;

  int pageSize = 50;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Games'),
        actions: [
          IconButton(
            onPressed: _isRefreshing ? null : _refreshData,
            disabledColor: Colors.grey,
            icon: const Icon(Icons.refresh),
            tooltip: "Refresh",
          )
        ],
      ),
      body: _buildContent(),
    );
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _initResources();
  }

  Future<void> _initResources() async {
    _prefs = await SharedPreferences.getInstance();
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
      _games = await _dbService.getGamesSortedByLastModified(pageSize, 0);
      _updateListMetaValues();
      _loadStats();
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _onScroll() {
    if (_isLoading || _allGamesLoaded || _isSearching) return;

    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 1000) {
      _loadMoreGames();
    }
  }

  Future<void> _refreshData() async {
    setState(() {
      _isRefreshing = true;
      _games = [];
      _loadingMessage = 'Fetching games from Steam...';
    });

    final games = await _apiService.fetchAllGames((gamesLoaded) {
      setState(() {
        _loadingMessage = 'Loaded $gamesLoaded games...';
      });
    });

    setState(() {
      _loadingMessage = 'Saving to database';
    });

    await _dbService.deleteAllGames();
    await _dbService.insertGames(games);

    _prefs.setInt(_prefsKeyTotalGamesCount, games.length);
    _prefs.setString(_prefsKeyLastUpdateTime, DateTime.now().toIso8601String());
    _loadStats();

    _games = await _dbService.getGamesSortedByLastModified(pageSize, 0);
    _updateListMetaValues();

    setState(() {
      _isRefreshing = false;
    });
  }

  Future<void> _loadMoreGames() async {
    setState(() {
      _isLoading = true;
    });

    final moreGames = await _dbService.getGamesSortedByLastModified(pageSize, _games.length);

    setState(() {
      _games.addAll(moreGames);
      _updateListMetaValues();
      _isLoading = false;
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

  void _loadStats() {
    _totalGamesCount = _prefs.getInt(_prefsKeyTotalGamesCount) ?? 0;
    final timeString = _prefs.getString(_prefsKeyLastUpdateTime);
    if (timeString != null) {
      _lastUpdateTime = DateTime.parse(timeString);
    }
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return 'Never';
    return '${dateTime.day}.${dateTime.month}.${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _updateListMetaValues() {
    _allGamesLoaded = _games.length == _totalGamesCount;
  }

  void _navigateToDetail(Game game) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GameDetailPage(
          appid: game.appid,
          gameName: game.name,
        ),
      ),
    );
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
    if (_isRefreshing) {
      return _buildLoadingWidget();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Stats bar
        Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          color: const Color(0xFF2a475e),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total games: $_totalGamesCount',
                style: const TextStyle(color: Colors.white70),
              ),
              Text(
                'Last update: ${_formatDateTime(_lastUpdateTime)}',
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),

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

    var itemsCount = displayedGames.length;

    // Extra item for loading indicator if not all games loaded and not searching
    if (!_allGamesLoaded && !_isSearching) {
      itemsCount++;
    }

    return ListView.builder(
      controller: _scrollController,
      itemCount: itemsCount,
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
        onTap: () => _navigateToDetail(game),
      ),
    );
  }
}
