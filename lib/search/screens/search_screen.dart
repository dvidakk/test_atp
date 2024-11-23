// lib/search/screens/search_screen.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:bluesky/bluesky.dart' as bsky;
import 'package:provider/provider.dart';
import 'package:test_atp/core/constants/colors.dart';
import 'package:test_atp/core/services/auth_service.dart';
import 'package:test_atp/core/services/post_service.dart';
import 'package:test_atp/core/services/search_service.dart';
import 'package:test_atp/profile/screens/profile_screen.dart';
import 'package:test_atp/feed/widgets/post_card/post_card.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late SearchService _searchService;
  late PostService _postService;
  final TextEditingController _searchController = TextEditingController();
  List<bsky.Actor> _userResults = [];
  List<bsky.FeedView> _postResults = [];
  bool _isLoading = false;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    final authService = Provider.of<AuthService>(context, listen: false);
    _postService = PostService(authService.bluesky!);

    _searchService = SearchService(authService.bluesky!);
    _tabController = TabController(length: 2, vsync: this);
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (query.isNotEmpty) {
        _performSearch(query);
      } else {
        setState(() {
          _userResults.clear();
          _postResults.clear();
        });
      }
    });
  }

  Future<void> _performSearch(String query) async {
    setState(() => _isLoading = true);

    try {
      if (_tabController.index == 0) {
        // Top/Posts tab
        final posts = await _searchService.searchPosts(query);
        if (!mounted) return;
        setState(() {
          _postResults = posts
              .map((post) => bsky.FeedView(
                    post: post,
                    reply: null,
                    reason: null,
                  ))
              .toList();
        });
      } else {
        // People tab
        final users = await _searchService.searchUsers(query);
        if (!mounted) return;
        setState(() {
          _userResults = users;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Search failed: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return Scaffold(
      appBar: AppBar(
        title: Container(
          height: 40,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(20),
          ),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search Bluesky',
              border: InputBorder.none,
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(10.0),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
            onChanged: _onSearchChanged,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          onTap: (_) {
            if (_searchController.text.isNotEmpty) {
              _performSearch(_searchController.text);
            }
          },
          tabs: const [
            Tab(text: 'Top'),
            Tab(text: 'People'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Posts tab
          _postResults.isEmpty && _searchController.text.isEmpty
              ? const Center(
                  child: Text('Try searching for posts'),
                )
              : ListView.separated(
                  itemCount: _postResults.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    return PostCard(
                      post: _postResults[index],
                      postService: _postService,
                      onUpdatePost: (updated) {
                        setState(() {
                          _postResults[index] = updated;
                        });
                      },
                    );
                  },
                ),

          // People tab
          _userResults.isEmpty && _searchController.text.isEmpty
              ? const Center(
                  child: Text('Try searching for people'),
                )
              : ListView.builder(
                  itemCount: _userResults.length,
                  itemBuilder: (context, index) {
                    final user = _userResults[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: user.avatar != null
                            ? NetworkImage(user.avatar!)
                            : null,
                        child: user.avatar == null
                            ? Text(user.handle[0].toUpperCase())
                            : null,
                      ),
                      title: Text(user.displayName ?? user.handle),
                      subtitle: Text('@${user.handle}'),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProfileScreen(
                              handle: user.handle,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
        ],
      ),
    );
  }
}
