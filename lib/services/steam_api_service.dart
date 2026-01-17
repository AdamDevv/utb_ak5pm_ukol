import 'dart:convert';

import '../models/game.dart';
import 'package:http/http.dart' as http;

import '../models/game_detail.dart';

class SteamApiService {
  static const String _apiKey = '535D0C1D4372C9C3C1DB3AE54E8A8522';
  static const String _appListUrl = 'http://api.steampowered.com/IStoreService/GetAppList/v1/';
  static const String _appDetailsUrl = 'https://store.steampowered.com/api/appdetails';

  Future<List<Game>> fetchAllGames(Function(int gamesLoaded)? onProgress) async {
    List<Game> allGames = [];

    var lastAppId = 0;
    while (true) {
      final url = '$_appListUrl?format=json&max_results=50000&key=$_apiKey&last_appid=$lastAppId';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode != 200) {
        throw Exception('Failed to fetch games: ${response.statusCode}');
      }

      final dynamic json = jsonDecode(response.body);
      final bool haveMoreResults = json["response"]["have_more_results"] ?? false;
      final List<dynamic> games = json["response"]["apps"] ?? [];

      var parsedGames = games.map((game) => Game.fromDynamic(game)).toList();
      allGames.addAll(parsedGames);
      onProgress?.call(allGames.length);

      if (haveMoreResults) {
        lastAppId = json["response"]["last_appid"];
        continue;
      }

      break;
    }

    await Future.delayed(const Duration(milliseconds: 100));

    return allGames;
  }

  Future<GameDetail?> fetchGameDetail(int appid) async {
    final url = '$_appDetailsUrl?appids=$appid';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch game detail: ${response.statusCode}');
    }

    final dynamic json = jsonDecode(response.body);

    var root = json[appid.toString()];

    if (root == null || root['success'] != true) {
      throw Exception('Game detail not found for appid: $appid');
    }

    var data = root['data'];
    var genresJsonList = data['genres'] as List<dynamic>? ?? [];

    return GameDetail(
      appid: appid,
      name: data['name'] as String? ?? '',
      capsuleImage: data['capsule_image'] as String?,
      priceFormatted: data['price_overview']?['final_formatted'] as String?,
      genres: genresJsonList.map<String>((g) => g["description"]).toList(),
      comingSoon: data['release_date']?['coming_soon'] as bool? ?? false,
      releaseDate: data['release_date']?['date'] as String? ?? '',
    );
  }
}
