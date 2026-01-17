class Game {
  final int appid;
  final String name;
  final int lastModified;

  Game(
    this.appid,
    this.name,
    this.lastModified,
  );

  factory Game.fromDynamic(dynamic object) {
    return Game(
      object['appid'] as int,
      object['name'] as String,
      object['last_modified'] as int,
    );
  }
}
