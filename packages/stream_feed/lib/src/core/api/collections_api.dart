import 'package:dio/dio.dart';
import 'package:stream_feed/src/core/http/stream_http_client.dart';
import 'package:stream_feed/src/core/http/token.dart';
import 'package:stream_feed/src/core/models/collection_entry.dart';
import 'package:stream_feed/src/core/util/extension.dart';
import 'package:stream_feed/src/core/util/routes.dart';

/// The http layer api for CRUD operations on Collections
class CollectionsApi {
  /// [CollectionsApi] constructor
  const CollectionsApi(this._client);

  final StreamHttpClient _client;

  /// Add item to collection
  /// Note: when using client-side auth the user_id field must not be provided
  /// as the value will be taken from the user token.
  /// Note: If a collection object with the same ID already exists,
  /// the request will error with code 409 Conflict.
  Future<CollectionEntry> add(
      Token token, String? userId, CollectionEntry entry) async {
    checkNotNull(entry.collection, "Collection name can't be null");
    checkArgument(
        entry.collection!.isNotEmpty, "Collection name can't be empty");
    checkNotNull(entry.data, "Collection data can't be null");
    final result = await _client.post<Map>(
      Routes.buildCollectionsUrl(entry.collection),
      headers: {'Authorization': '$token'},
      data: {
        'data': entry.data,
        if (userId != null) 'user_id': userId,
        if (entry.id != null) 'id': entry.id,
      },
    );
    return CollectionEntry.fromJson(result.data as Map<String, dynamic>);
  }

  /// Delete entry from collection
  ///Will return an empty response on success.
  Future<Response> delete(
      Token token, String collection, String entryId) async {
    checkArgument(collection.isNotEmpty, "Collection name can't be empty");
    checkArgument(entryId.isNotEmpty, "Collection id can't be empty");
    return _client.delete(
      Routes.buildCollectionsUrl('$collection/$entryId/'),
      headers: {'Authorization': '$token'},
    );
  }

  ///Remove all objects by id from the collection.
  Future<Response> deleteMany(
      Token token, String collection, Iterable<String> entryIds) async {
    checkArgument(collection.isNotEmpty, "Collection name can't be empty");
    checkArgument(entryIds.isNotEmpty, "Collection ids can't be empty");
    return _client.delete(
      Routes.buildCollectionsUrl(),
      headers: {'Authorization': '$token'},
      queryParameters: {
        'collection_name': collection,
        'ids': entryIds.join(','),
      },
    );
  }

  ///Get item from collection and sync data
  Future<CollectionEntry> get(
      Token token, String collection, String entryId) async {
    checkArgument(collection.isNotEmpty, "Collection name can't be empty");
    checkArgument(entryId.isNotEmpty, "Collection id can't be empty");
    final result = await _client.get<Map>(
      Routes.buildCollectionsUrl('$collection/$entryId/'),
      headers: {'Authorization': '$token'},
    );
    return CollectionEntry.fromJson(result.data as Map<String, dynamic>);
  }

  /// Select all objects with ids from the collection.
  Future<List<CollectionEntry>> select(
      Token token, String collection, Iterable<String> entryIds) async {
    checkArgument(collection.isNotEmpty, "Collection name can't be empty");
    checkArgument(entryIds.isNotEmpty, "Collection ids can't be empty");
    final result = await _client.get<Map>(
      Routes.buildCollectionsUrl(),
      headers: {'Authorization': '$token'},
      queryParameters: {
        'foreign_ids': entryIds.map((id) => '$collection:$id').join(','),
      },
    );
    final data = (result.data!['response']['data'] as List)
        .map((e) => CollectionEntry.fromJson(e))
        .toList(growable: false);
    return data;
  }

  /// Update item in the object storage
  Future<CollectionEntry> update(
      Token token, String? userId, CollectionEntry entry) async {
    checkNotNull(entry, "Collection can't be null");
    checkNotNull(entry.collection, "Collection name can't be null");
    checkArgument(
        entry.collection!.isNotEmpty, "Collection name can't be empty");
    final result = await _client.put<Map>(
      Routes.buildCollectionsUrl('${entry.collection}/${entry.id}/'),
      headers: {'Authorization': '$token'},
      data: {
        'data': entry.data,
        if (userId != null) 'user_id': userId,
      },
    );
    return CollectionEntry.fromJson(result.data as Map<String, dynamic>);
  }

  ///Upsert one or more items within a collection.
  Future<Response> upsert(
      //TODO: Map<String, Iterable<CollectionEntry>>
      Token token,
      String collection,
      Iterable<CollectionEntry> entries) async {
    checkArgument(collection.isNotEmpty, "Collection name can't be empty");
    checkArgument(entries.isNotEmpty, "Collection data can't be empty");
    return _client.post(Routes.buildCollectionsUrl(), headers: {
      'Authorization': '$token'
    }, data: {
      'data': {collection: entries}
    });
  }
}
