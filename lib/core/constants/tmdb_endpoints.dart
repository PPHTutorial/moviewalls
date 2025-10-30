enum PosterSize {
  w92('w92'),
  w154('w154'),
  w185('w185'),
  w342('w342'),
  w500('w500'),
  w780('w780'),
  original('original');
  final String value;
  const PosterSize(this.value);
}

enum BackdropSize {
  w300('w300'),
  w780('w780'),
  w1280('w1280'),
  original('original');
  final String value;
  const BackdropSize(this.value);
}

class TMDBEndpoints {
  static const String imageBase = 'https://image.tmdb.org/t/p';
  static String posterUrl(String path, {PosterSize size = PosterSize.w500}) => '$imageBase/${size.value}$path';
  static String backdropUrl(String path, {BackdropSize size = BackdropSize.w780}) => '$imageBase/${size.value}$path';
}
