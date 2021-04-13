import 'package:mocktail/mocktail.dart';
import 'package:stream_feed_dart/src/client/collections_client.dart';
import 'package:stream_feed_dart/src/core/api/collections_api.dart';
import 'package:stream_feed_dart/src/core/api/stream_api.dart';
import 'package:stream_feed_dart/src/core/http/stream_http_client.dart';
import 'package:stream_feed_dart/src/core/util/token_helper.dart';

class MockHttpClient extends Mock implements StreamHttpClient {}

class MockCollectionsClient extends Mock implements CollectionsClient {}

class MockCollectionsApi extends Mock implements CollectionsApi {}

class MockApi extends Mock implements StreamApi {}

class MockTokenHelper extends Mock implements TokenHelper {}
