import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:provider/provider.dart';
import '../models/community_support_model.dart';
import '../providers/community_provider.dart';
import '../utils/theme.dart';
import '../utils/responsive.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'inbox_screen.dart';
import 'chat_thread_screen.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CommunityFacebookScreen extends StatefulWidget {
  const CommunityFacebookScreen({super.key});

  @override
  State<CommunityFacebookScreen> createState() => _CommunityFacebookScreenState();
}

class _CommunityFacebookScreenState extends State<CommunityFacebookScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final TextEditingController _postController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  bool _isPosting = false;
  bool _showPostForm = false;
  XFile? _selectedImage;
  Uint8List? _selectedImageBytes;
  String _selectedCategory = 'general';
  Map<String, bool> _expandedComments = {};
  Map<String, TextEditingController> _commentControllers = {};
  bool _showOnlyMyPosts = false;
  double? _uploadProgress;
  
  final List<String> _categories = [
    'general', 'health_tip', 'medication_experience', 'exercise', 
    'diet', 'mental_health', 'elderly_care', 'family_support'
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CommunityProvider>().loadPosts();
    });
  }

  @override
  void dispose() {
    _postController.dispose();
    _commentController.dispose();
    _scrollController.dispose();
    _commentControllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }

  void _onScroll() {
    final provider = context.read<CommunityProvider>();
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 200 &&
        !provider.isLoadingMore && provider.hasMorePosts) {
      provider.loadMorePosts();
    }
  }

  Future<void> _createPost() async {
    if (_postController.text.trim().isEmpty && _selectedImage == null) return;
    
    setState(() => _isPosting = true);
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Build Base64 image payload (Firestore) instead of Storage URL
      String? imageUrl; // keep null when using base64
      String? imageBase64;
      if (_selectedImage != null) {
        final bytes = _selectedImageBytes ?? await _selectedImage!.readAsBytes();
        // Detect mime type from extension
        String contentType = 'image/jpeg';
        final nameLower = _selectedImage!.name.toLowerCase();
        if (nameLower.endsWith('.png')) contentType = 'image/png';
        if (nameLower.endsWith('.webp')) contentType = 'image/webp';

        // Light size guard for Firestore 1MB limit (base64 ~ 1.33x). Aim < 700KB raw
        if (bytes.lengthInBytes > 700 * 1024) {
          _showSnackBar('⚠️ Image is large; consider a smaller photo for faster posting.');
        }
        final encoded = base64Encode(bytes);
        imageBase64 = 'data:$contentType;base64,$encoded';
      }

      final post = CommunityPostModel(
        userId: user.uid,
        userName: user.displayName ?? 'Anonymous User',
        userAvatar: user.photoURL ?? 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=80&h=80&fit=crop&crop=face',
        userLocation: 'Health Community',
        content: _postController.text.trim(),
        imageUrl: imageUrl,
        imageBase64: imageBase64,
        category: _selectedCategory,
        timestamp: DateTime.now(),
        tags: _extractTags(_postController.text),
      );
      
      await context.read<CommunityProvider>().createPost(post);
      
      _postController.clear();
      setState(() {
        _selectedImage = null;
        _selectedImageBytes = null;
        _uploadProgress = null;
        _showPostForm = false;
      });
      
      _showSnackBar('Post created successfully!');
    } catch (e) {
      _showSnackBar('Error creating post: $e');
    } finally {
      setState(() => _isPosting = false);
    }
  }

  List<String> _extractTags(String text) {
    final tags = <String>[];
    final words = text.split(' ');
    for (final word in words) {
      if (word.startsWith('#') && word.length > 1) {
        tags.add(word.substring(1));
      }
    }
    return tags;
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppTheme.bgDarkSecondary,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(FeatherIcons.image, color: Colors.white),
              title: const Text('Pick from Gallery', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(FeatherIcons.camera, color: Colors.white),
              title: const Text('Take a Photo', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (source == null) return;

    final pickedFile = await picker.pickImage(
      source: source,
      maxWidth: 1280,
      maxHeight: 1280,
      imageQuality: 85,
    );
    
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _selectedImage = pickedFile;
        _selectedImageBytes = bytes;
      });
    }
  }

  void _toggleComments(String postId) {
    setState(() {
      _expandedComments[postId] = !(_expandedComments[postId] ?? false);
    });
    
    if (_expandedComments[postId] == true) {
      context.read<CommunityProvider>().loadComments(postId);
    }
  }

  void _addComment(String postId) {
    final controller = _commentControllers[postId];
    if (controller != null && controller.text.trim().isNotEmpty) {
      context.read<CommunityProvider>().addComment(postId, controller.text.trim());
      controller.clear();
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.bgGradient),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: Consumer<CommunityProvider>(
                  builder: (context, provider, child) {
                    return RefreshIndicator(
                      backgroundColor: AppTheme.bgGlassMedium,
                      color: AppTheme.primaryColor,
                      onRefresh: () => provider.loadPosts(refresh: true),
                      child: ListView(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        children: [
                          _buildCreatePostCard(),
                          const SizedBox(height: 16),
                          _buildRealPosts(provider),
                          if (provider.isLoadingMore)
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: AppTheme.glassContainer,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(8),
            child: const Icon(
              FeatherIcons.users,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AidX Community',
                  style: AppTheme.headlineMedium.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Share your health experiences',
                  style: AppTheme.bodyText.copyWith(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.bgGlassMedium,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ChoiceChip(
                        label: const Text('All'),
                        selected: !_showOnlyMyPosts,
                        onSelected: (val) {
                          setState(() => _showOnlyMyPosts = false);
                        },
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('My Posts'),
                        selected: _showOnlyMyPosts,
                        onSelected: (val) {
                          setState(() => _showOnlyMyPosts = true);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // DM Button
          Container(
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.only(right: 8),
            child: IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const InboxScreen()),
                );
              },
              icon: const Icon(
                FeatherIcons.messageCircle,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          // Create Post Button
          Container(
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: () => setState(() => _showPostForm = !_showPostForm),
              icon: Icon(
                _showPostForm ? FeatherIcons.x : FeatherIcons.plus,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreatePostCard() {
    if (!_showPostForm) return const SizedBox.shrink();

    return Container(
      decoration: AppTheme.glassContainer,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundImage: NetworkImage(
                  'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=80&h=80&fit=crop&crop=face',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _postController,
                  style: AppTheme.bodyText.copyWith(color: AppTheme.textPrimary),
                  decoration: InputDecoration(
                    hintText: "What's on your mind?",
                    hintStyle: AppTheme.bodyText.copyWith(color: AppTheme.textMuted),
                    border: InputBorder.none,
                  ),
                  maxLines: 3,
                ),
              ),
            ],
          ),
          if (_selectedImageBytes != null) ...[
            const SizedBox(height: 16),
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: AspectRatio(
                    aspectRatio: 16/9,
                    child: Image.memory(
                      _selectedImageBytes!,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () => setState(() { _selectedImage = null; _selectedImageBytes = null; }),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(Icons.close, color: Colors.white, size: 16),
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.bgGlassMedium,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    dropdownColor: AppTheme.bgDarkSecondary,
                    style: AppTheme.bodyText.copyWith(color: AppTheme.textPrimary),
                    items: _categories.map((category) {
                      return DropdownMenuItem(
                        value: category,
                        child: Text(category.replaceAll('_', ' ').toUpperCase()),
                      );
                    }).toList(),
                    onChanged: (value) => setState(() => _selectedCategory = value!),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  onPressed: _pickImage,
                  icon: const Icon(FeatherIcons.image, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isPosting ? null : _createPost,
              style: AppTheme.primaryButtonStyle,
              child: _isPosting
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            value: _uploadProgress,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          _uploadProgress != null
                              ? 'Uploading ${(100 * _uploadProgress!).round()}%'
                              : 'Posting...'
                          ,
                          style: AppTheme.bodyText.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ],
                    )
                  : Text('Post', style: AppTheme.bodyText.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRealPosts(CommunityProvider provider) {
    if (provider.isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (provider.posts.isEmpty) {
      return Container(
        decoration: AppTheme.glassContainer,
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(FeatherIcons.fileText, size: 64, color: AppTheme.textMuted),
            const SizedBox(height: 16),
            Text(
              'No posts yet',
              style: AppTheme.headlineMedium.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Be the first to share something!',
              style: AppTheme.bodyText.copyWith(color: AppTheme.textMuted),
            ),
          ],
        ),
      );
    }

    final me = FirebaseAuth.instance.currentUser;
    final allPosts = provider.posts;
    List<CommunityPostModel> visiblePosts;
    if (me == null) {
      visiblePosts = allPosts;
    } else if (_showOnlyMyPosts) {
      // Show only my posts
      visiblePosts = allPosts.where((p) => p.userId == me.uid).toList();
    } else {
      // In "All" mode, show all posts
      visiblePosts = allPosts;
    }
    return Column(
      children: visiblePosts.map((post) => _buildRealPostCard(post, provider)).toList(),
    );
  }

  Widget _buildRealPostCard(CommunityPostModel post, CommunityProvider provider) {
    final isLiked = provider.isPostLiked(post.id!);
    final showComments = _expandedComments[post.id!] ?? false;
    final comments = provider.comments[post.id!] ?? [];
    
    // Get or create comment controller for this post
    if (!_commentControllers.containsKey(post.id!)) {
      _commentControllers[post.id!] = TextEditingController();
    }

    return Container(
      decoration: AppTheme.glassContainer,
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (post.imageBase64 != null && post.imageBase64!.isNotEmpty)
            const SizedBox(height: 0) // ensure layout spacing is consistent
          else if (post.imageUrl != null && post.imageUrl!.isNotEmpty)
            const SizedBox(height: 0),
          // Post header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: post.userAvatar.isNotEmpty 
                    ? NetworkImage(post.userAvatar)
                    : null,
                  child: post.userAvatar.isEmpty 
                    ? Text(
                        post.userName[0].toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.userName,
                        style: AppTheme.bodyText.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        DateFormat('MMM dd, yyyy • HH:mm').format(post.timestamp),
                        style: AppTheme.bodyText.copyWith(
                          color: AppTheme.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.bgGlassMedium,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Text(
                    post.category.replaceAll('_', ' ').toUpperCase(),
                    style: AppTheme.bodyText.copyWith(
                      fontSize: 10,
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (FirebaseAuth.instance.currentUser?.uid != post.userId)
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.bgGlassMedium,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      tooltip: 'Message',
                      icon: const Icon(FeatherIcons.messageCircle, size: 18, color: Colors.white),
                      onPressed: () {
                        final me = FirebaseAuth.instance.currentUser;
                        if (me == null) return;
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatThreadScreen(
                              currentUserId: me.uid,
                              peerId: post.userId,
                              peerName: post.userName,
                              category: 'community',
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                if (FirebaseAuth.instance.currentUser?.uid == post.userId)
                  PopupMenuButton<String>(
                    itemBuilder: (ctx) => [
                      const PopupMenuItem(value: 'delete', child: Text('Delete Post')),
                    ],
                    onSelected: (val) async {
                      if (val == 'delete') {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text('Delete Post'),
                            content: const Text('Are you sure you want to delete this post?'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                              TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          await provider.deletePost(post.id!);
                          _showSnackBar('Post deleted');
                        }
                      }
                    },
                  ),
              ],
            ),
          ),
          // Post content
          if (post.content.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                post.content,
                style: AppTheme.bodyText.copyWith(
                  fontSize: 16,
                  color: AppTheme.textPrimary,
                  height: 1.5,
                ),
              ),
            ),
          // Post image
          if (post.imageBase64 != null && post.imageBase64!.isNotEmpty)
            Container(
              width: double.infinity,
              height: 200,
              margin: const EdgeInsets.only(top: 12),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: Image.memory(
                  _decodeBase64Image(post.imageBase64!),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    debugPrint('Error decoding base64 image: $error');
                    return Container(
                      color: AppTheme.bgGlassMedium,
                      child: Icon(
                        FeatherIcons.image,
                        color: AppTheme.textMuted,
                        size: 40,
                      ),
                    );
                  },
                ),
              ),
            )
          else if (post.imageUrl != null && post.imageUrl!.isNotEmpty)
            Container(
              width: double.infinity,
              height: 200,
              margin: const EdgeInsets.only(top: 12),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: (post.imageUrl!.startsWith('http') || post.imageUrl!.startsWith('https'))
                  ? CachedNetworkImage(
                      imageUrl: post.imageUrl!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: AppTheme.bgGlassMedium,
                        child: Center(
                          child: CircularProgressIndicator(
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) {
                        debugPrint('Error loading image: $error');
                        return Container(
                          color: AppTheme.bgGlassMedium,
                          child: Icon(
                            FeatherIcons.image,
                            color: AppTheme.textMuted,
                            size: 40,
                          ),
                        );
                      },
                    )
                  : Image.file(
                      File(post.imageUrl!),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        debugPrint('Error loading local image: $error');
                        return Container(
                          color: AppTheme.bgGlassMedium,
                          child: Icon(
                            FeatherIcons.image,
                            color: AppTheme.textMuted,
                            size: 40,
                          ),
                        );
                      },
                    ),
              ),
            ),
          // Tags
          if (post.tags.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                children: post.tags.map((tag) => Container(
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Text(
                    '#$tag',
                    style: AppTheme.bodyText.copyWith(
                      fontSize: 12,
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                )).toList(),
              ),
            ),
          // Post actions
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                 _buildActionButton(
                   icon: FeatherIcons.heart,
                   label: '${post.likes}',
                   color: isLiked ? Colors.red : AppTheme.textSecondary,
                   onTap: () => provider.toggleLikePost(post.id!),
                 ),
                const SizedBox(width: 24),
                _buildActionButton(
                  icon: FeatherIcons.messageCircle,
                  label: '${comments.length}',
                  color: AppTheme.textSecondary,
                  onTap: () => _toggleComments(post.id!),
                ),
                const SizedBox(width: 24),
                _buildActionButton(
                  icon: FeatherIcons.share,
                  label: 'Share',
                  color: AppTheme.textSecondary,
                  onTap: () => provider.sharePost(post.id!),
                ),
              ],
            ),
          ),
          // Comments section
          if (showComments) ...[
            const Divider(height: 1, color: Colors.white12),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  ...comments.map((comment) => _buildComment(comment)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundImage: NetworkImage(
                          'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=32&h=32&fit=crop&crop=face',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _commentControllers[post.id!],
                          style: AppTheme.bodyText.copyWith(color: AppTheme.textPrimary),
                          decoration: InputDecoration(
                            hintText: 'Write a comment...',
                            hintStyle: AppTheme.bodyText.copyWith(color: AppTheme.textMuted),
                            border: InputBorder.none,
                          ),
                          onSubmitted: (_) => _addComment(post.id!),
                        ),
                      ),
                      IconButton(
                        onPressed: () => _addComment(post.id!),
                        icon: Icon(
                          FeatherIcons.send,
                          color: AppTheme.primaryColor,
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Helper: decode data URI base64 into bytes
  Uint8List _decodeBase64Image(String dataUri) {
    try {
      final commaIndex = dataUri.indexOf(',');
      final base64Part = commaIndex != -1 ? dataUri.substring(commaIndex + 1) : dataUri;
      return base64Decode(base64Part);
    } catch (e) {
      debugPrint('Failed to decode base64 image: $e');
      return Uint8List(0);
    }
  }

  Widget _buildComment(CommunityCommentModel comment) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundImage: NetworkImage(
              'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=32&h=32&fit=crop&crop=face',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.bgGlassMedium,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    comment.userName,
                    style: AppTheme.bodyText.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    comment.content,
                    style: AppTheme.bodyText.copyWith(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTheme.bodyText.copyWith(
              color: color,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
} 