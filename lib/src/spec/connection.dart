import 'enums.dart';
import 'common.dart';


abstract class ConnectionBase extends EventEmitter<ConnectionEvent> {

  ///current state of this connection
  ConnectionState state;

  ///Error information associated with connection failure
  ErrorInfo errorReason;

  ///A public identifier for this connection, used to identify
  /// this member in presence events and message ids.
  String id;

  /// The assigned connection key.
  String key;

  /// RTN16b) Connection#recoveryKey is an attribute composed of the
  /// connection key and latest serial received on the connection
  String recoveryKey;

  /// The serial number of the last message to be received on this connection.
  int serial;
  void close();
  void connect();
}


abstract class Connection extends ConnectionBase {
  Future<int> ping();
//  Future<ConnectionStateChange> whenState(ConnectionState targetState); //TODO remove?
}