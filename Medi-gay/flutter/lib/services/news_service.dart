import '../models/news_model.dart';

class NewsService {
  Future<List<NewsArticle>> getHealthNews() async {
    // Mock news data
    await Future.delayed(const Duration(seconds: 1));
    
    return [
      NewsArticle(
        title: "WHO warns about rising flu cases this season",
        description: "Health authorities recommend vaccination",
        url: "",
        imageUrl: "https://source.unsplash.com/random/300x200?virus",
        source: "WHO",
        publishedAt: DateTime.now().toIso8601String(),
      ),
      NewsArticle(
        title: "New study links walking 30 mins/day to better heart health",
        description: "Research shows significant cardiovascular benefits",
        url: "",
        imageUrl: "https://source.unsplash.com/random/300x200?heart",
        source: "Health Research",
        publishedAt: DateTime.now().toIso8601String(),
      ),
      NewsArticle(
        title: "Researchers develop painless glucose monitoring patch",
        description: "Breakthrough in diabetes management technology",
        url: "",
        imageUrl: "https://source.unsplash.com/random/300x200?glucose",
        source: "Medical Innovation",
        publishedAt: DateTime.now().toIso8601String(),
      ),
      NewsArticle(
        title: "Meditation shown to reduce stress hormones by 25%",
        description: "Study confirms mental health benefits",
        url: "",
        imageUrl: "https://source.unsplash.com/random/300x200?meditation",
        source: "Wellness Research",
        publishedAt: DateTime.now().toIso8601String(),
      ),
    ];
  }
}
