// lib/services/post_service.dart
import 'package:bluesky/atproto.dart' as atp;
import 'package:bluesky/bluesky.dart' as bsky;
import 'package:at_uri/at_uri.dart';
import 'dart:core';

class PostService {
  final bsky.Bluesky bluesky;

  PostService(this.bluesky);

  Future<void> likePost(AtUri uri, String cid) async {
    try {
      await bluesky.feed.like(uri: uri, cid: cid);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> unlikePost(AtUri uri) async {
    try {
      await bluesky.atproto.repo.deleteRecord(uri: uri);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> repost(AtUri uri, String cid) async {
    try {
      await bluesky.feed.repost(uri: uri, cid: cid);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> unrepost(AtUri uri) async {
    try {
      // send delete record request
      await bluesky.atproto.repo.deleteRecord(uri: uri);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> createPost(String text) async {
    try {
      await bluesky.feed.post(text: text);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> reply(String text, AtUri uri, String cid) async {
    try {
      await bluesky.feed.post(
        text: text,
        reply: bsky.ReplyRef(
          parent: atp.StrongRef(uri: uri, cid: cid),
          root: atp.StrongRef(uri: uri, cid: cid),
        ),
      );
    } catch (e) {
      rethrow;
    }
  }
}
