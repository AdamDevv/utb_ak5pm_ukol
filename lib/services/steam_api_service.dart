import 'dart:convert';

import '../models/game.dart';
import 'package:http/http.dart' as http;

class SteamApiService {
  static const String _apiKey = '535D0C1D4372C9C3C1DB3AE54E8A8522';
  static const String _appListUrl = 'http://api.steampowered.com/IStoreService/GetAppList/v1/';
  static const String _appDetailsUrl = 'https://store.steampowered.com/api/appdetails';

  Future<List<Game>> fetchAllGames() async {
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

      var parsedGames = games.map((game) => Game(game["appid"], game["name"], game['last_modified'])).toList();
      allGames.addAll(parsedGames);

      if (haveMoreResults) {
        lastAppId = json["response"]["last_appid"];
        continue;
      }

      break;
    }

    return allGames;
  }
}
