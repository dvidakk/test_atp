import 'package:flutter/material.dart';
import 'package:bluesky/bluesky.dart' as bsky;
import 'package:test_atp/core/constants/colors.dart';
import 'package:test_atp/core/services/post_service.dart';
import 'package:test_atp/feed/widgets/post_card/post_card.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatefulWidget {
  final bsky.Bluesky bluesky;
  final String handle;
  final PostService postService;

  const ProfileScreen({
    super.key,
    required this.bluesky,
    required this.handle,
    required this.postService,
  });

  @override
  ProfileScreenState createState() => ProfileScreenState();
}

class ProfileScreenState extends State<ProfileScreen> {
  late PostService _postService;
  List<bsky.FeedView> _userPosts = [];
  bsky.ActorProfile? _profile;
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _postService = PostService(widget.bluesky);
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
        _errorMessage = null;
      });

      final profile = await widget.bluesky.actor.getProfile(
        actor: widget.handle,
      );
      final posts = await widget.bluesky.feed.getAuthorFeed(
        actor: widget.handle,
      );

      if (!mounted) return;

      setState(() {
        _profile = profile.data;
        // Create a new modifiable list
        _userPosts = List<bsky.FeedView>.from(posts.data.feed);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = e.toString();
        _isLoading = false;
      });
      debugPrint('Error loading profile: $e');
    }
  }

  Widget _buildProfileHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Banner and Profile Picture Stack
        Stack(
          clipBehavior: Clip.none,
          children: [
            // Banner
            Container(
              height: 150,
              width: double.infinity,
              child: _profile?.banner != null
                  ? CachedNetworkImage(
                      imageUrl: _profile!.banner!,
                      fit: BoxFit.cover,
                    )
                  : Container(color: AppColors.lightGray),
            ),
            // Avatar
            Positioned(
              left: 16,
              bottom: -40,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 4,
                  ),
                ),
                child: CircleAvatar(
                  radius: 40,
                  backgroundImage: _profile?.avatar != null
                      ? CachedNetworkImageProvider(_profile!.avatar!)
                      : null,
                  backgroundColor: AppColors.lightGray,
                ),
              ),
            ),
          ],
        ),

        // Content below banner (with extra padding for avatar overflow)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 48, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Follow button
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    side: BorderSide(color: AppColors.blue),
                  ),
                  child: Text(
                    _profile?.viewer?.following != null
                        ? 'Following'
                        : 'Follow',
                    style: TextStyle(color: AppColors.blue),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Rest of profile info...
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_hasError) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error: $_errorMessage'),
              ElevatedButton(
                onPressed: _loadProfile,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: Provider<PostService>.value(
        value: _postService,
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                expandedHeight: 150, // Reduced height for banner
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: _profile?.banner != null
                      ? CachedNetworkImage(
                          imageUrl: _profile!.banner!,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: AppColors.lightGray,
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: AppColors.lightGray,
                          ),
                        )
                      : Container(color: AppColors.lightGray),
                ),
              ),
              SliverToBoxAdapter(
                child: _buildProfileHeader(),
              ),
            ];
          },
          body: ListView.separated(
            itemCount: _userPosts.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              return PostCard(
                post: _userPosts[index],
                postService: _postService,
                onUpdatePost: (updated) {
                  setState(() {
                    _userPosts[index] = updated;
                  });
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
