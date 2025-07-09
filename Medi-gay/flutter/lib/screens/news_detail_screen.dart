import 'package:flutter/material.dart';
import '../models/news_model.dart';
import '../utils/theme.dart';

class NewsDetailScreen extends StatelessWidget {
  final NewsArticle article;

  const NewsDetailScreen({
    Key? key,
    required this.article,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Health News'),
        backgroundColor: AppTheme.bgGlassLight,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.bgGradient,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // News image
              Hero(
                tag: 'news_image',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    article.imageUrl,
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: double.infinity,
                        height: 200,
                        color: Colors.grey[800],
                        child: const Icon(
                          Icons.image_not_supported,
                          color: Colors.white54,
                          size: 48,
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Title
              Text(
                article.title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              
              // Source and date
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      article.source,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textTeal,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatDate(article.publishedAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Description
              Text(
                article.description,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              
              // Mock content
              _buildMockContent(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMockContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Health Implications',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nullam euismod, nisl eget ultricies aliquam, nunc nisl aliquet nunc, vitae aliquam nisl nunc eu nisl. Nullam euismod, nisl eget ultricies aliquam, nunc nisl aliquet nunc, vitae aliquam nisl nunc eu nisl.',
          style: TextStyle(
            fontSize: 16,
            color: Colors.white70,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Expert Recommendations',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur.',
          style: TextStyle(
            fontSize: 16,
            color: Colors.white70,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'Today';
    }
  }
}
