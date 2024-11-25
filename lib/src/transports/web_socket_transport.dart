
import 'dart:async';

import 'package:http/http.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../signalr_core.dart';
import 'web_socket_channel_api.dart'
    if (dart.library.html) 'web_socket_channel_html.dart'
    if (dart.library.io) 'web_socket_channel_io.dart' as platform;

class WebSocketTransport implements Transport {
  final Logging? _logging;
  final AccessTokenFactory? _accessTokenFactory;
  final bool? _logMessageContent;
  final BaseClient? _client;

  StreamSubscription<dynamic>? _streamSubscription;
  WebSocketChannel? _channel;

  WebSocketTransport({
    BaseClient? client,
    AccessTokenFactory? accessTokenFactory,
    Logging? logging,
    bool? logMessageContent,
  })  : _logging = logging,
        _accessTokenFactory = accessTokenFactory,
        _logMessageContent = logMessageContent,
        _client = client {
    onreceive = null;
    onclose = null;
  }

  @override
  OnClose? onclose;

  @override
  OnReceive? onreceive;

  @override
  Future<void> connect(String? url, TransferFormat? transferFormat) async {
    assert(url != null);
    assert(transferFormat != null);

    _logging?.call(LogLevel.trace, '(WebSockets transport) Connecting.');

    if (_accessTokenFactory != null) {
      final token = await _accessTokenFactory!();
      if (token!.isNotEmpty) {
        final encodedToken = Uri.encodeComponent(token);
        url = '${url!}${url.contains('?') ? '&' : '?'}access_token=$encodedToken';
      }
    }

    url = url!.replaceFirst(RegExp(r'^http'), 'ws');

    _channel = await platform.connect(Uri.parse(url), client: _client!);

    _logging?.call(LogLevel.information, 'WebSocket connected to $url.');

    _streamSubscription = _channel?.stream.listen(
      (data) {
        final dataDetail = getDataDetail(data, _logMessageContent);
        _logging?.call(LogLevel.trace, '(WebSockets transport) data received. $dataDetail');
        onreceive?.call(data);
      },
      onError: (error) {
        _logging?.call(LogLevel.error, '(WebSockets transport) socket error: ${error.toString()}');
      },
      onDone: () {
        _close(null);
      },
    );
  }

  @override
  Future<void> send(dynamic data) async {
    if (_channel == null || _channel!.closeCode != null) {
      throw Exception('WebSocket is not in the OPEN state');
    }
    _logging?.call(
      LogLevel.trace,
      '(WebSockets transport) sending data. ${getDataDetail(data, _logMessageContent)}.',
    );
    _channel!.sink.add(data);
  }

  @override
  Future<void> stop() async {
    _close(null);
  }

  void _close(Exception? error) {
    _streamSubscription?.cancel();
    _channel?.sink.close();
    _channel = null;

    _logging?.call(LogLevel.trace, '(WebSockets transport) socket closed.');
    onclose?.call(error);
  }
}
