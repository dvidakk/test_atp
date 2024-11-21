import 'package:bluesky/core.dart';
import 'package:flutter/material.dart';
import 'package:bluesky/bluesky.dart' as bsky;
import 'package:test_atp/auth/screens/login_screen.dart';
import 'package:test_atp/core/constants/colors.dart';
import 'package:test_atp/core/services/auth_service.dart';
import 'package:test_atp/core/services/post_service.dart';
import 'package:test_atp/feed/widgets/post_card/post_card.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatefulWidget {
  final String handle;

  const ProfileScreen({
    super.key,
    required this.handle,
  });

  @override
  ProfileScreenState createState() => ProfileScreenState();
}

class ProfileScreenState extends State<ProfileScreen> {
  late PostService _postService;
  List<bsky.FeedView> _userPosts = [];
  bsky.ActorProfile? _profile;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final authService = Provider.of<AuthService>(context, listen: false);
    _postService = PostService(authService.bluesky!);
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final authService = Provider.of<AuthService>(context, listen: false);

    if (!await authService.validateAndRefreshSession()) {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final profile = await authService.authenticatedRequest(
          () => authService.bluesky!.actor.getProfile(actor: widget.handle));
      final posts = await authService.authenticatedRequest(
          () => authService.bluesky!.feed.getAuthorFeed(actor: widget.handle));

      if (!mounted) return;
      setState(() {
        _profile = profile.data;
        _userPosts = List<bsky.FeedView>.from(posts.data.feed);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
      if (e is UnauthorizedException) {
        await authService.logout();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    }
  }

  Widget _buildProfileHeader() {
    return Container(
      height: 320, // Adjusted height to accommodate additional info
      child: Stack(
        children: [
          // Banner Image
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 150,
            child: _profile?.banner != null
                ? CachedNetworkImage(
                    imageUrl: _profile!.banner!,
                    fit: BoxFit.cover,
                    placeholder: (_, __) =>
                        Container(color: AppColors.lightGray),
                    errorWidget: (_, __, ___) =>
                        Container(color: AppColors.lightGray),
                  )
                : Container(color: AppColors.lightGray),
          ),
          // Avatar
          Positioned(
            left: 16,
            top: 110,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 4),
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
          // Follow Button
          Positioned(
            right: 16,
            top: 170,
            child: OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                side: BorderSide(color: AppColors.blue),
              ),
              child: Text(
                _profile?.viewer?.following != null ? 'Following' : 'Follow',
                style: TextStyle(color: AppColors.blue),
              ),
            ),
          ),
          // User Info
          Positioned(
            left: 16,
            top: 200,
            right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _profile?.displayName ?? '',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '@${_profile?.handle ?? ''}',
                  style: TextStyle(
                    color: AppColors.darkGray,
                  ),
                ),
                SizedBox(height: 8),
                if (_profile?.description != null)
                  Text(
                    _profile!.description!,
                    style: TextStyle(
                      fontSize: 14,
                    ),
                  ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      '${_profile?.followsCount ?? 0} Following',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 16),
                    Text(
                      '${_profile?.followersCount ?? 0} Followers',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_errorMessage != null) {
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
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 260, // Match this to your header's height
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                background: _buildProfileHeader(),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => PostCard(
                  post: _userPosts[index],
                  postService: _postService,
                  onUpdatePost: (updated) =>
                      setState(() => _userPosts[index] = updated),
                ),
                childCount: _userPosts.length,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
