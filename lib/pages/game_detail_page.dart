import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:utb_ak5pm_ukol/pages/game_detail.dart';

import '../services/steam_api_service.dart';

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
  final SteamApiService _apiService = SteamApiService();

  bool _isLoading = false;
  bool _isFavourite = false;

  GameDetail? _gameDetail;

  @override
  void initState() {
    super.initState();
    _loadGameDetail();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Game Detail')),
      body: _buildBody(),
    );
  }

  Future<void> _loadGameDetail() async {
    setState(() {
      _isLoading = true;
    });

    _gameDetail = await _apiService.fetchGameDetail(widget.appid);

    setState(() {
      _isLoading = false;
    });
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    var gameDetail = _gameDetail!;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Capsule image
          if (gameDetail.capsuleImage != null)
            AspectRatio(
              aspectRatio: 184 / 69,
              child: CachedNetworkImage(
                imageUrl: gameDetail.capsuleImage!,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.grey[300],
                  child: const Center(child: CircularProgressIndicator()),
                ),
              ),
            ),

          // Content
          Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildInfoCards(gameDetail),
                  const SizedBox(height: 24),
                  _buildAddToFavouritesSection(),
                ],
              ))
        ],
      ),
    );
  }

  Widget _buildInfoCards(GameDetail gameDetail) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Game name
        Text(
          _gameDetail!.name.isNotEmpty ? _gameDetail!.name : widget.gameName,
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),

        // Price
        _buildInfoCard(
          icon: Icons.attach_money,
          title: 'Price',
          content: gameDetail.comingSoon ? "Not yet announced" : gameDetail.priceFormatted ?? 'Free',
        ),
        const SizedBox(height: 6),

        // Genres
        if (gameDetail.genres.isNotEmpty)
          _buildInfoCard(
            icon: Icons.tag,
            title: 'Genres',
            content: gameDetail.genres.join(', '),
          ),
        const SizedBox(height: 6),

        // Release date
        _buildInfoCard(
          icon: Icons.calendar_today,
          title: 'Release Date',
          content: gameDetail.releaseDate,
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF1b2838)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    content,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddToFavouritesSection() {
    return Column(children: [
      // Favourite button
      SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _toggleFavourite,
          icon: Icon(_isFavourite ? Icons.favorite : Icons.favorite_border),
          label: Text(_isFavourite ? 'Remove from Favourites' : 'Add to Favourites'),
          style: ElevatedButton.styleFrom(
            backgroundColor: _isFavourite ? Colors.red : const Color(0xFF1b2838),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
      const SizedBox(height: 12),
    ]);
  }

  Future<void> _toggleFavourite() async {
    if (_isFavourite) {
      setState(() {
        _isFavourite = false;
      });
    } else {
      setState(() {
        _isFavourite = true;
      });
    }
  }
}
