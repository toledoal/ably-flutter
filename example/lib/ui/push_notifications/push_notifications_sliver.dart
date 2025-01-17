import 'package:flutter/material.dart';

import '../../push_notifications/push_notification_service.dart';
import 'push_notifications_activation_sliver.dart';
import 'push_notifications_device_information.dart';
import 'push_notifications_ios_permissions_sliver.dart';
import 'push_notifications_publishing_sliver.dart';
import 'push_notifications_subscriptions_sliver.dart';

class PushNotificationsSliver extends StatelessWidget {
  final PushNotificationService _pushNotificationService;
  final bool isIOSSimulator;

  const PushNotificationsSliver(this._pushNotificationService,
      {required this.isIOSSimulator, Key? key})
      : super(key: key);

  Widget buildCreateAblyClientText() => StreamBuilder(
        stream: _pushNotificationService.hasPushChannelStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.hasData && snapshot.data == false) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: RichText(
                  text: const TextSpan(children: [
                TextSpan(
                    text: 'Warning: ',
                    style: TextStyle(
                        color: Colors.red, fontWeight: FontWeight.bold)),
                TextSpan(
                    text: 'Create an Ably realtime or rest client above',
                    style: TextStyle(color: Colors.black))
              ])),
            );
          }

          return const SizedBox.shrink();
        },
      );

  @override
  Widget build(BuildContext context) => Container(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: Text(
                'Push Notifications',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
            buildCreateAblyClientText(),
            buildSummaryText(),
            PushNotificationsActivationSliver(
              _pushNotificationService,
              isIOSSimulator: isIOSSimulator,
            ),
            PushNotificationsDeviceInformation(_pushNotificationService),
            PushNotificationsIOSNotificationSettingsSliver(
                _pushNotificationService),
            PushNotificationsSubscriptionsSliver(_pushNotificationService),
            PushNotificationsPublishingSliver(_pushNotificationService),
          ],
        ),
      );

  Widget buildSummaryText() => Column(
        children: [
          const Text(
              'Activate your device, view your local device information, '
              'subscribe to a push channel with either your device or '
              'client ID, and then publish to the channel.',
              style: TextStyle(color: Colors.black)),
          const SizedBox(height: 16),
        ],
      );
}
