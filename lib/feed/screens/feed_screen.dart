import 'package:bluesky/bluesky.dart' as bsky;
import 'package:bluesky/moderation.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:test_atp/core/constants/colors.dart';
import 'package:test_atp/core/services/post_service.dart';
import 'package:test_atp/feed/widgets/post_card/post_card.dart';
import 'package:shimmer/shimmer.dart';
import 'package:test_atp/feed/widgets/post_skeleton.dart';
import 'package:test_atp/composer/widgets/base_composer.dart';
import 'package:provider/provider.dart';
import 'package:test_atp/core/services/auth_service.dart';
import 'package:test_atp/auth/screens/login_screen.dart';
import 'package:bluesky/core.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  FeedScreenState createState() => FeedScreenState();
}

class FeedScreenState extends State<FeedScreen> {
  List<bsky.FeedView> _feedPosts = [];
  bool _isLoading = false;
  final _logger = Logger('FeedScreen');
  late final PostService _postService;

  // Add selected post for desktop view
  bsky.FeedView? _selectedPost;

  void _handlePostUpdate(bsky.FeedView updatedPost) {
    setState(() {
      final index = _feedPosts
          .indexWhere((post) => post.post.uri == updatedPost.post.uri);
      if (index != -1) {
        _feedPosts[index] = updatedPost;
      }
      if (_selectedPost?.post.uri == updatedPost.post.uri) {
        _selectedPost = updatedPost;
      }
    });
  }

  @override
  void initState() {
    super.initState();
    final authService = Provider.of<AuthService>(context, listen: false);
    _postService = PostService(authService.bluesky!);
    _fetchFeed();
  }

  Future<void> _fetchFeed() async {
    final authService = Provider.of<AuthService>(context, listen: false);

    // Validate session before making API calls
    final isValid = await authService.validateAndRefreshSession();
    if (!isValid) {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final preferences = await authService.bluesky!.actor.getPreferences();
      final moderationPrefs = preferences.data.getModerationPrefs();

      final response = await authService.bluesky!.feed.getTimeline(
        headers: getLabelerHeaders(moderationPrefs),
        algorithm: 'bluesky:discover',
        limit: 20,
      );

      if (!mounted) return;

      setState(() {
        _feedPosts = response.data.feed;
        print(_feedPosts);
        _logger.info('Fetched ${_feedPosts.length} posts from discover feed');
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      _logger.severe('Error fetching discover feed: $e');

      // Handle session errors
      if (e is UnauthorizedException) {
        await authService.logout();
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    }
  }

  Future<void> _refreshFeed() async {
    await _fetchFeed();
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final isDesktop = MediaQuery.of(context).size.width > 1000;
    final isMediumWidth = MediaQuery.of(context).size.width > 600;

    Widget feedList = RefreshIndicator(
      onRefresh: _refreshFeed,
      child: _isLoading
          ? ListView.separated(
              itemCount: 5,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) => PostCardSkeleton(
                isCompact: isDesktop,
              ),
            )
          : ListView.separated(
              itemCount: _feedPosts.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: isDesktop
                      ? () {
                          setState(() {
                            _selectedPost = _feedPosts[index];
                          });
                        }
                      : null,
                  child: PostCard(
                    post: _feedPosts[index],
                    postService: _postService,
                    onUpdatePost: _handlePostUpdate,
                    isSelected: isDesktop && _feedPosts[index] == _selectedPost,
                    isCompact: isDesktop,
                  ),
                );
              },
            ),
    );

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(
              Icons.cloud,
              color: AppColors.blue,
              size: isMediumWidth ? 30 : 24,
            ),
            if (isMediumWidth) ...[
              const SizedBox(width: 16),
              const Text('Cumulus'),
            ],
          ],
        ),
        actions: [
          if (isMediumWidth) ...[
            IconButton(
              icon: const Icon(Icons.account_circle),
              onPressed: () {
                // Navigate to profile
              },
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                await authService.logout();
                if (!context.mounted) return;
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              },
            ),
          ],
        ],
      ),
      body: isDesktop
          ? Row(
              children: [
                if (isMediumWidth)
                  NavigationRail(
                    selectedIndex: 0,
                    onDestinationSelected: (index) {},
                    destinations: const [
                      NavigationRailDestination(
                        icon: Icon(Icons.home_outlined),
                        selectedIcon: Icon(Icons.home),
                        label: Text('Home'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.search_outlined),
                        selectedIcon: Icon(Icons.search),
                        label: Text('Search'),
                      ),
                    ],
                  ),
                Expanded(
                  flex: 4,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.symmetric(
                        horizontal: BorderSide(
                          color: Colors.grey.shade200,
                        ),
                      ),
                    ),
                    child: feedList,
                  ),
                ),
                if (_isLoading)
                  Expanded(
                    flex: 5,
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border(
                          left: BorderSide(
                            color: Colors.grey.shade200,
                          ),
                        ),
                      ),
                      child: const PostCardSkeleton(isCompact: false),
                    ),
                  )
                else if (_selectedPost != null)
                  Expanded(
                    flex: 5,
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border(
                          left: BorderSide(
                            color: Colors.grey.shade200,
                          ),
                        ),
                      ),
                      child: PostCard(
                        post: _selectedPost!,
                        postService: _postService,
                        onUpdatePost: _handlePostUpdate,
                        isCompact: false,
                      ),
                    ),
                  ),
              ],
            )
          : feedList,
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.blue,
        onPressed: () async {
          // Validate session before composing
          final isValid = await authService.validateAndRefreshSession();
          if (!isValid) {
            if (!mounted) return;
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const LoginScreen()),
            );
            return;
          }

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BaseComposer(
                postService: _postService,
                onCancel: () => Navigator.pop(context),
                onSubmit: (text) async {
                  await _postService.createPost(text);
                  await _fetchFeed(); // Refresh feed after posting
                },
                type: ComposerType.newPost,
              ),
            ),
          );
        },
        child: Icon(
          Icons.edit,
          size: isMediumWidth ? 24 : 20,
        ),
      ),
    );
  }
}
