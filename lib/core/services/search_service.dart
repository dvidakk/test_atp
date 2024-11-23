// lib/core/services/search_service.dart

import 'dart:async'; // Import for Future
import 'package:bluesky/bluesky.dart' as bsky;

class SearchService {
  final bsky.Bluesky bluesky;

  SearchService(this.bluesky);

  Future<List<bsky.Actor>> searchUsers(String query, {int limit = 20}) async {
    try {
      final response = await bluesky.actor.searchActors(
        term: query,
        limit: limit,
      );
      return response.data.actors;
    } catch (e) {
      rethrow;
    }
  }

  Future<List<bsky.Post>> searchPosts(
    String query, {
    String? sort,
    String? since,
    String? until,
    String? mentions,
    String? author,
    String? lang,
    String? domain,
    String? url,
    List<String>? tag,
    int? limit,
    String? cursor,
    Map<String, String>? headers,
  }) async {
    try {
      final response = await bluesky.feed.searchPosts(
        query,
        sort: sort,
        since: since,
        until: until,
        mentions: mentions,
        author: author,
        lang: lang,
        domain: domain,
        url: url,
        tag: tag,
        limit: limit,
        cursor: cursor,
        headers: headers,
      );
      return response.data.posts;
    } catch (e) {
      rethrow;
    }
  }
}
