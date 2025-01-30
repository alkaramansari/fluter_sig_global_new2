import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

void main() async {
  final client = MqttServerClient('192.168.1.156', 'com-attendance-client');
  client.port = 1883; // Default MQTT port
  client.logging(on: true);
  client.keepAlivePeriod = 20;
  client.onConnected = onConnected;
  client.onDisconnected = onDisconnected;
  client.onSubscribed = onSubscribed;
  client.pongCallback = pong;

  final connMessage = MqttConnectMessage()
      .withClientIdentifier('flutter_client')
      .withWillTopic('willtopic')
      .withWillMessage('Client disconnected unexpectedly')
      .startClean()
      .withWillQos(MqttQos.atLeastOnce);

  client.connectionMessage = connMessage;

  try {
    await client.connect();
  } catch (e) {
    print('Error connecting: $e');
    client.disconnect();
  }

  if (client.connectionStatus!.state == MqttConnectionState.connected) {
    print('Connected');
    // Subscribe to a topic
    client.subscribe('test/notify', MqttQos.atLeastOnce);

    // Listen for incoming messages
    client.updates!.listen((List<MqttReceivedMessage<MqttMessage?>>? c) {
      final recMess = c![0].payload as MqttPublishMessage;
      final message = MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
      print('Notification received: $message');
    });

    // Publish a message
    const pubTopic = 'test/notify';
    final builder = MqttClientPayloadBuilder();
    builder.addString('Hello, self notification!');
    client.publishMessage(pubTopic, MqttQos.atLeastOnce, builder.payload!);
  } else {
    print('Connection failed');
  }

  // Disconnect when done
  client.disconnect();
}

void onConnected() {
  print('Connected to the MQTT server');
}

void onDisconnected() {
  print('Disconnected from the MQTT server');
}

void onSubscribed(String topic) {
  print('Subscribed to topic: $topic');
}

void pong() {
  print('Ping response received');
}
