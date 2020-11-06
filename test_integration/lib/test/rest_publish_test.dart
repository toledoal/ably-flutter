import 'package:ably_flutter_integration_test/test/test_widget_abstract.dart';
import 'package:ably_flutter_plugin/ably.dart';

import '../test_dispatcher.dart';
import 'appkey_provision_helper.dart';

class RestPublishTest extends TestWidget {
  RestPublishTest(TestDispatcherState dispatcher) : super(dispatcher);

  @override
  TestWidgetState<TestWidget> createState() => RestPublishTestState();
}

class RestPublishTestState extends TestWidgetState<RestPublishTest> {
  @override
  Future<void> test() async {
    widget.dispatcher.reportLog('init start');
    final appKey = await provision('sandbox-');
    final logMessages = <List<String>>[];

    final rest = Rest(
      options: ClientOptions.fromKey(appKey.toString())
        ..environment = 'sandbox'
        ..clientId = 'someClientId'
        ..logLevel = LogLevel.verbose
        ..logHandler =
            ({msg, exception}) => logMessages.add([msg, exception.toString()]),
    );
    await restMessagesPublishUtil(rest);
    widget.dispatcher.reportTestCompletion(<String, dynamic>{
      'handle': await rest.handle,
      'log': logMessages,
    });
  }
}

Future<void> restMessagesPublishUtil(Rest rest) async {
  final name = 'Hello';
  final messageData = [
    null,   //null
    'Ably', //string
    [1, 2, 3],  //numeric list
    ['hello', 'ably'], //string list
    {'hello': 'ably', 'items': ['1', 2.2, '3 thousand']},  //map
    [{'hello': 'ably'}, 'ably', 'rest']
  ];

  final channel = rest.channels.get('test');
  await channel.publish();  //publish without name and data
  await channel.publish(data: messageData[1]);  //publish without name
  for(var data in messageData){
    await channel.publish(name: name, data: data);
  }
}