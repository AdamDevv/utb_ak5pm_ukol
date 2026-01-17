import 'package:utb_ak5pm_ukol/models/game.dart';

class FavouriteGameData {
  final int appid;
  final String note;
  late Game? gameData;

  FavouriteGameData({
    required this.appid,
    required this.note,
  });

  factory FavouriteGameData.fromDynamic(dynamic object) {
    return FavouriteGameData(
      appid: object['appid'] as int,
      note: object['note'] as String? ?? '',
    );
  }
}
