import 'package:faye_dart/faye_dart.dart';
import 'package:stream_feed_dart/src/client/aggregated_feed.dart';
import 'package:stream_feed_dart/src/client/feed.dart';
import 'package:stream_feed_dart/src/client/flat_feed.dart';
import 'package:stream_feed_dart/src/client/notification_feed.dart';
import 'package:stream_feed_dart/src/client/batch_operations_client.dart';
import 'package:stream_feed_dart/src/client/collections_client.dart';
import 'package:stream_feed_dart/src/client/file_storage_client.dart';
import 'package:stream_feed_dart/src/client/image_storage_client.dart';
import 'package:stream_feed_dart/src/client/reactions_client.dart';
import 'package:stream_feed_dart/src/core/api/stream_api.dart';
import 'package:stream_feed_dart/src/core/api/stream_api_impl.dart';
import 'package:stream_feed_dart/src/core/http/stream_http_client.dart';
import 'package:stream_feed_dart/src/core/http/token.dart';
import 'package:stream_feed_dart/src/core/index.dart';
import 'package:stream_feed_dart/src/core/models/feed_id.dart';

import 'package:stream_feed_dart/src/client/users_client.dart';
import 'package:stream_feed_dart/src/client/stream_client.dart';
import 'package:stream_feed_dart/src/core/util/extension.dart';
import 'package:stream_feed_dart/src/core/util/token_helper.dart';
import 'package:logging/logging.dart';

typedef _LogHandlerFunction = void Function(LogRecord record);

// ignore: public_member_api_docs
class StreamClientImpl implements StreamClient {
  /// [StreamClientImpl] constructor
  StreamClientImpl(
    this.apiKey, {
    this.secret,
    this.userToken,
    this.logLevel = Level.WARNING,
    this.appId,
    this.fayeUrl = 'wss://faye-us-east.stream-io-api.com/faye',
    StreamApi? api,
    StreamHttpClientOptions? options,
  })  : assert(
          userToken != null || secret != null,
          'At least a secret or userToken must be provided',
        ),
        _api = api ?? StreamApiImpl(apiKey, options: options) {
    _setupLogger();
    logger.info('instantiating new client');
  }
  late _LogHandlerFunction logHandlerFunction;
  final Level logLevel;
  final Logger logger = Logger.detached('📡');
  final String apiKey;
  final String? appId;
  final Token? userToken;
  final StreamApi _api;
  final String? secret;
  final String fayeUrl;

  late final _authExtension = <String, MessageHandler>{
    'outgoing': (message) {
      final subscription = _subscriptions[message.subscription];
      if (subscription != null) {
        message.ext = {
          'user_id': subscription.userId,
          'api_key': apiKey,
          'signature': subscription.token,
        };
      }
      return message;
    },
  };

  late final FayeClient _faye = FayeClient(fayeUrl)
    ..addExtension(_authExtension);

  late final _subscriptions = <String, _FeedSubscription>{};

  @override
  BatchOperationsClient get batch {
    checkNotNull(secret, "You can't use batch operations client side");
    return BatchOperationsClient(_api.batch, secret: secret!);
  }

  @override
  CollectionsClient get collections =>
      CollectionsClient(_api.collections, userToken: userToken, secret: secret);

  @override
  ReactionsClient get reactions =>
      ReactionsClient(_api.reactions, userToken: userToken, secret: secret);

  @override
  UsersClient get users =>
      UsersClient(_api.users, userToken: userToken, secret: secret);

  @override
  FileStorageClient get files =>
      FileStorageClient(_api.files, userToken: userToken, secret: secret);

  @override
  ImageStorageClient get images =>
      ImageStorageClient(_api.images, userToken: userToken, secret: secret);

  Future<Subscription> _feedSubscriber(
    Token token,
    FeedId feedId,
    MessageDataCallback callback,
  ) async {
    checkNotNull(
      appId,
      'Missing app id, which is needed in order to subscribe feed',
    );
    final claim = feedId.claim;
    final notificationChannel = 'site-$appId-feed-$claim';
    _subscriptions['/$notificationChannel'] = _FeedSubscription(
      token: token.toString(),
      userId: notificationChannel,
    );
    await _faye.connect();
    final subscription = await _faye.subscribe(
      '/$notificationChannel',
      callback: callback,
    );
    _subscriptions.update(
      '/$notificationChannel',
      (it) => it.copyWith(fayeSubscription: subscription),
    );
    return subscription;
  }

  @override
  AggregatedFeed aggregatedFeed(String slug, String userId) {
    final id = FeedId(slug, userId);
    return AggregatedFeed(
      id,
      _api.feed,
      userToken: userToken,
      secret: secret,
      subscriber: _feedSubscriber,
    );
  }

  @override
  FlatFeed flatFeed(String slug, String userId) {
    final id = FeedId(slug, userId);
    return FlatFeed(
      id,
      _api.feed,
      userToken: userToken,
      secret: secret,
      subscriber: _feedSubscriber,
    );
  }

  @override
  NotificationFeed notificationFeed(String slug, String userId) {
    final id = FeedId(slug, userId);
    return NotificationFeed(
      id,
      _api.feed,
      userToken: userToken,
      secret: secret,
      subscriber: _feedSubscriber,
    );
  }

  @override
  Token frontendToken(
    String userId, {
    DateTime? expiresAt,
  }) {
    checkNotNull(secret, "You can't use the frontendToken method client side");
    return TokenHelper.buildFrontendToken(secret!, userId,
        expiresAt: expiresAt);
  }

  @override
  Future<OpenGraphData> openGraph(String targetUrl) {
    final token = userToken ?? TokenHelper.buildOpenGraphToken(secret!);
    return _api.openGraph(token, targetUrl);
  }

  void _setupLogger() {
    logger.level = logLevel;

    logHandlerFunction = _getDefaultLogHandler();

    logger.onRecord.listen(logHandlerFunction);

    logger.info('logger setup');
  }

  _LogHandlerFunction _getDefaultLogHandler() {
    final levelEmojiMapper = {
      Level.INFO.name: 'ℹ️',
      Level.WARNING.name: '⚠️',
      Level.SEVERE.name: '🚨',
    };
    return (LogRecord record) {
      print(
        '(${record.time}) '
        '${levelEmojiMapper[record.level.name] ?? record.level.name} '
        '${record.loggerName} ${record.message}',
      );
      if (record.stackTrace != null) {
        print(record.stackTrace);
      }
    };
  }
}

class _FeedSubscription {
  const _FeedSubscription({
    required this.token,
    required this.userId,
    this.fayeSubscription,
  });

  _FeedSubscription copyWith({
    String? token,
    String? userId,
    Subscription? fayeSubscription,
  }) =>
      _FeedSubscription(
        token: token ?? this.token,
        userId: userId ?? this.userId,
        fayeSubscription: fayeSubscription ?? this.fayeSubscription,
      );

  final String token;
  final String userId;
  final Subscription? fayeSubscription;
}
