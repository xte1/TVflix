import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import '../models/movie.dart';

class StarcimaService {
  static const String baseUrl = 'https://starcima.com';

  static Map<String, String> get headers => {
    'User-Agent': 'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1',
    'Accept-Language': 'ar,en-US;q=0.9,en;q=0.8',
  };

  static Future<List<Movie>> fetchHomeMovies({int page = 1}) async {
    try {
      final url = page == 1 ? '$baseUrl/' : '$baseUrl/page/$page/';
      final response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        final document = parser.parse(response.body);
        final List<Movie> movies = [];

        final elements = document.querySelectorAll('.GridItem, .MovieBlock, .post-item, article');
        for (var element in elements) {
          final titleEl = element.querySelector('.Title, .title, h3, h2, a.title');
          final linkEl = element.querySelector('a');
          final imgEl = element.querySelector('img');

          String title = titleEl?.text.trim() ?? linkEl?.attributes['title'] ?? 'فيلم';
          String href = linkEl?.attributes['href'] ?? '';
          String img = imgEl?.attributes['data-src'] ?? imgEl?.attributes['src'] ?? '';

          if (href.isNotEmpty) {
            movies.add(Movie(
              title: title,
              url: href.startsWith('http') ? href : '$baseUrl$href',
              posterUrl: img.startsWith('http') ? img : '$baseUrl$img',
            ));
          }
        }
        return movies;
      }
    } catch (e) {
      print("Error: $e");
    }
    return [];
  }

  static Future<MovieDetail?> fetchMovieDetails(String url) async {
    try {
      final response = await http.get(Uri.parse(url), headers: headers);
      if (response.statusCode == 200) {
        final document = parser.parse(response.body);

        final title = document.querySelector('h1, .single-title')?.text.trim() ?? '';
        final desc = document.querySelector('.Story, .story, .entry-content')?.text.trim() ?? 'لا يوجد وصف.';
        final imgEl = document.querySelector('.Poster img, .single-poster img, meta[property="og:image"]');
        final posterUrl = imgEl?.attributes['src'] ?? imgEl?.attributes['content'] ?? '';

        final List<String> videoServers = [];
        final iframeElements = document.querySelectorAll('iframe, embed');
        for (var iframe in iframeElements) {
          String src = iframe.attributes['src'] ?? iframe.attributes['data-src'] ?? '';
          if (src.isNotEmpty) {
            if (src.startsWith('//')) src = 'https:$src';
            videoServers.add(src);
          }
        }

        return MovieDetail(
          title: title,
          description: desc,
          posterUrl: posterUrl,
          videoServers: videoServers,
        );
      }
    } catch (e) {
      print("Error details: $e");
    }
    return null;
  }
}
