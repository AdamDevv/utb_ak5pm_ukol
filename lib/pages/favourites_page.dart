import 'package:flutter/material.dart';
import 'package:utb_ak5pm_ukol/models/favourite_game_data.dart';
import 'package:utb_ak5pm_ukol/pages/game_detail_page.dart';
import '../models/game.dart';
import '../services/database_service.dart';

class FavouritesPage extends StatefulWidget {
  const FavouritesPage({super.key});

  @override
  State<FavouritesPage> createState() => _FavouritesPageState();
}

class _FavouritesPageState extends State<FavouritesPage> {
  final DatabaseService _dbService = DatabaseService.instance;

  List<FavouriteGameData> _favouriteGames = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFavourites();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Favourite Games'),
        backgroundColor: const Color(0xFF1b2838),
        foregroundColor: Colors.white,
      ),
      body: _buildContent(),
    );
  }

  Future<void> _loadFavourites() async {
    setState(() {
      _isLoading = true;
    });

    final games = await _dbService.getAllGamesMarkedAsFavourite();
    final favourites = await _dbService.getAllFavouriteGamesData();

    final gamesMap = <int, Game>{};
    for (final game in games) {
      gamesMap[game.appid] = game;
    }
    for (var e in favourites) {
      e.gameData = gamesMap[e.appid];
    }

    setState(() {
      _favouriteGames = favourites;
      _isLoading = false;
    });

    setState(() {
      _isLoading = false;
    });
  }

  void _navigateToDetail(Game game) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GameDetailPage(
          appid: game.appid,
          gameName: game.name,
        ),
      ),
    );
    
    // Reload favourites when returning in case we removed this game from favourites
    _loadFavourites();
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_favouriteGames.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite_border,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            const Text(
              'No favourite games added',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add games to favourites from the detail screen',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: _favouriteGames.length,
        itemBuilder: (context, index) {
          final favouriteGameData = _favouriteGames[index];
          final note = favouriteGameData.note ?? '';
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: ListTile(
              title: Text(
                favouriteGameData.gameData!.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: note.isNotEmpty
                  ? Text(
                      note,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12),
                    )
                  : null,
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _navigateToDetail(favouriteGameData.gameData!),
            ),
          );
        });
  }
}
