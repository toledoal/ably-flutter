import 'dart:async';
import 'dart:io';

import 'package:ably_flutter/ably_flutter.dart' as ably;
import 'package:rxdart/rxdart.dart';

import 'constants.dart';

class PushNotificationService {
  late final ably.Realtime? realtime;
  late final ably.Rest? rest;
  ably.RealtimeChannelInterface? _realtimeChannel;
  ably.RealtimeChannelInterface? _pushLogMetachannel;
  ably.RestChannelInterface? _restChannel;
  late ably.PushChannel? _pushChannel;

  final BehaviorSubject<
          ably.PaginatedResultInterface<ably.PushChannelSubscription>>
      _pushChannelSubscriptionSubject = BehaviorSubject<
          ably.PaginatedResultInterface<ably.PushChannelSubscription>>();

  ValueStream<ably.PaginatedResultInterface<ably.PushChannelSubscription>>
      get pushChannelSubscriptionStream =>
          _pushChannelSubscriptionSubject.stream;

  ably.PaginatedResultInterface<ably.PushChannelSubscription>
      get _pushChannelSubscription => _pushChannelSubscriptionSubject.value;

  final BehaviorSubject<bool> _hasPushChannelSubject =
      BehaviorSubject<bool>.seeded(false);

  ValueStream<bool> get hasPushChannelStream => _hasPushChannelSubject.stream;

  bool get hasPushChannel => _hasPushChannelSubject.value;

  final BehaviorSubject<ably.LocalDevice?> _localDeviceSubject =
      BehaviorSubject.seeded(null);
  late final ValueStream<ably.LocalDevice?> localDeviceStream =
      _localDeviceSubject.stream;

  ably.LocalDevice? get localDevice => localDeviceStream.value;

  final BehaviorSubject<bool> _userNotificationPermissionGrantedSubject =
      BehaviorSubject();
  late final ValueStream<bool> userNotificationPermissionGrantedStream =
      _userNotificationPermissionGrantedSubject.stream;

  bool get userNotificationPermissionGranted =>
      userNotificationPermissionGrantedStream.value;

  void setRealtimeClient(ably.Realtime realtime) {
    this.realtime = realtime;
    _getChannels();
    getDevice();
  }

  Future<void> ensureRealtimeClientConnected() async {
    if (realtime?.connection.state != ably.ConnectionState.connected) {
      await realtime!.connect();
    }
  }

  void setRestClient(ably.Rest rest) {
    this.rest = rest;
    _getChannels();
  }

  Future<void> requestNotificationPermission() async {
    if (realtime != null) {
      final granted = await realtime!.push.requestNotificationPermission();
      _userNotificationPermissionGrantedSubject.add(granted);
    } else if (rest != null) {
      final granted = await rest!.push.requestNotificationPermission();
      _userNotificationPermissionGrantedSubject.add(granted);
    } else {
      throw Exception('No ably client available');
    }
  }

  Future<void> activateDevice() async {
    if (realtime != null) {
      await realtime!.push.activate();
      print('Push: ${realtime!.push}');
    } else if (rest != null) {
      await rest!.push.activate();
      print('Push: ${rest!.push}');
    } else {
      throw Exception('No ably client available');
    }
  }

  Future<void> deactivateDevice() async {
    if (realtime != null) {
      await realtime!.push.deactivate();
      print('Push: ${realtime!.push}');
    } else {
      await rest!.push.deactivate();
      print('Push: ${rest!.push}');
    }
    await getDevice();
  }

  Future<void> getDevice() async {
    if (realtime != null) {
      final localDevice = await realtime!.device();
      _localDeviceSubject.add(localDevice);
    } else {
      final localDevice = await rest!.device();
      _localDeviceSubject.add(localDevice);
    }
  }

  /// Subscribes to the channel (not the push channel) which has a Push channel
  /// rule. This allows the device to receive push notifications when
  /// messages contain a push notification payload.
  ///
  /// See Channel-based broadcasting for more information
  /// https://ably.com/documentation/general/push/publish#channel-broadcast
  Future<Stream<ably.Message?>> subscribeToChannelWithPushChannelRule() async {
    await _realtimeChannelStreamSubscription?.cancel();
    await ensureRealtimeClientConnected();
    final stream = _realtimeChannel!.subscribe();
    _realtimeChannelStreamSubscription = stream.listen((message) {
      print('Message clientId: ${message?.clientId}');
      print('Message extras: ${message?.extras}');
    });
    return stream;
  }

  StreamSubscription<ably.Message?>? _realtimeChannelStreamSubscription;

  Future<Stream<ably.Message?>> subscribeToPushLogMetachannel() async {
    await ensureRealtimeClientConnected();
    final stream = _pushLogMetachannel!.subscribe();
    _pushLogMetaChannelSubscription = stream.listen((message) {
      print('MetaChannel message');
      print(message);
    });
    return stream;
  }

  StreamSubscription<ably.Message?>? _pushLogMetaChannelSubscription;

  Future<void> unsubscribeToChannelWithPushChannelRule() async {
    await _realtimeChannelStreamSubscription?.cancel();
  }

  final ably.Message _pushNotificationMessage = ably.Message(
      data: 'This is a channel message that is also sent as a '
          'notification message to registered push devices.',
      extras: const ably.MessageExtras({
        'push': {
          'notification': {
            'title': 'Hello from Ably!',
            'body': 'Example push notification from Ably.'
          },
          'data': {'foo': 'bar', 'baz': 'quz'},
        },
      }));

  Future<void> publishNotificationMessageToChannel() async {
    await ensureRealtimeClientConnected();
    if (_realtimeChannel != null) {
      await _realtimeChannel!.publish(message: _pushNotificationMessage);
    } else if (_restChannel != null) {
      await _restChannel!.publish(message: _pushNotificationMessage);
    }
  }

  final ably.Message _pushDataMessage = ably.Message(
      data: 'This is a channel message that is also sent as a '
          'data message to registered push devices.',
      extras: const ably.MessageExtras({
        'push': {
          'data': {'foo': 'bar', 'baz': 'quz'},
          'apns': {
            'aps': {'content-available': 1}
          }
        },
      }));

  Future<void> publishDataMessageToChannel() async {
    await ensureRealtimeClientConnected();
    if (_realtimeChannel != null) {
      await _realtimeChannel!.publish(message: _pushDataMessage);
    } else if (_restChannel != null) {
      await _restChannel!.publish(message: _pushDataMessage);
    }
  }

  void close() {
    _hasPushChannelSubject.close();
    _localDeviceSubject.close();
    _userNotificationPermissionGrantedSubject.close();
    _realtimeChannelStreamSubscription?.cancel();
    _realtimeChannelStreamSubscription = null;
    _pushLogMetaChannelSubscription?.cancel();
    _pushLogMetaChannelSubscription = null;
  }

  void _getChannels() {
    _hasPushChannelSubject.add(false);
    if (realtime != null) {
      _realtimeChannel =
          realtime!.channels.get(Constants.channelNameForPushNotifications);
      _pushChannel = _realtimeChannel!.push;
      _pushLogMetachannel =
          realtime!.channels.get(Constants.pushMetaChannelName);
      _hasPushChannelSubject.add(true);
    } else if (rest != null) {
      _restChannel =
          rest!.channels.get(Constants.channelNameForPushNotifications);
      _pushChannel = _restChannel!.push;
      _hasPushChannelSubject.add(true);
    } else {
      throw Exception(
          'No Ably client exists, cannot get rest/ realtime channels or push channels.');
    }
  }

  /// Unfortunately ably-cocoa and ably-java are inconsistent here.
  /// Ably-java will list all subscriptions (clientId and deviceId), where as
  /// ably-cocoa will only give the one you specify in params.
  /// This behavior is the same for [listSubscriptionsWithDeviceId]
  Future<ably.PaginatedResultInterface<ably.PushChannelSubscription>>
      listSubscriptionsWithClientId() async {
    await getDevice();
    final subscriptions = await _pushChannel!.listSubscriptions({
      'clientId': Constants.clientId,
      // Optionally, limit the size of the paginated response.
      // 'limit': '1'
    });
    _pushChannelSubscriptionSubject.add(subscriptions);
    return subscriptions;
  }

  Future<ably.PaginatedResultInterface<ably.PushChannelSubscription>>
      listSubscriptionsWithDeviceId() async {
    await getDevice();
    final subscriptions = await _pushChannel!.listSubscriptions({
      'deviceId': localDevice!.id!,
      // Optionally, limit the size of the paginated response.
      // 'limit': '1'
    });
    _pushChannelSubscriptionSubject.add(subscriptions);
    return subscriptions;
  }

  Future<void> subscribeClient() async {
    await _pushChannel!.subscribeClient();
  }

  Future<void> unsubscribeClient() async {
    await _pushChannel!.unsubscribeClient();
  }

  Future<void> subscribeDevice() async {
    await _pushChannel!.subscribeDevice();
  }

  Future<void> unsubscribeDevice() async {
    await _pushChannel!.unsubscribeDevice();
  }
}