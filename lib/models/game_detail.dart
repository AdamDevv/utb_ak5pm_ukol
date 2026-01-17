class GameDetail {
  final int appid;
  final String name;
  final String? capsuleImage;
  final String? priceFormatted;
  final List<String> genres;
  final bool comingSoon;
  final String releaseDate;

  GameDetail({
    required this.appid,
    required this.name,
    required this.capsuleImage,
    required this.priceFormatted,
    required this.genres,
    required this.comingSoon,
    required this.releaseDate,
  });
}
