import '../../signalr_core.dart' as transfer;
import '../../signalr_core.dart';

abstract class Connection {
  Connection({
    this.features,
    this.connectionId,
  });

  final dynamic features;

  final String? connectionId;

  String? baseUrl;

  OnReceive? onreceive;

  OnClose? onclose;

  Future<void> start({
    transfer.TransferFormat? transferFormat = transfer.TransferFormat.binary,
  });

  Future<void> send(dynamic data);

  Future<void> stop({Exception? exception});
}
