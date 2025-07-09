class NewsArticle {
  final String title;
  final String description;
  final String url;
  final String imageUrl;
  final String source;
  final String publishedAt;

  NewsArticle({
    required this.title,
    required this.description,
    required this.url,
    required this.imageUrl,
    required this.source,
    required this.publishedAt,
  });

  factory NewsArticle.fromJson(Map<String, dynamic> json) {
    return NewsArticle(
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      url: json['url'] ?? '',
      imageUrl: json['urlToImage'] ?? 'https://source.unsplash.com/random/300x200?health',
      source: json['source']['name'] ?? 'Unknown',
      publishedAt: json['publishedAt'] ?? DateTime.now().toIso8601String(),
    );
  }
}
