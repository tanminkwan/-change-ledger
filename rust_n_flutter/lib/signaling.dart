// signaling.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:web_socket_channel/io.dart';

class Signaling {
  RTCPeerConnection? _peerConnection;
  RTCDataChannel? _dataChannel;
  late IOWebSocketChannel _channel;
  Function(String message)? onMessageReceived;
  Function()? onLocalCandidate;

  Signaling(String webSocketUrl) {
    _channel = IOWebSocketChannel.connect(webSocketUrl);
    _connectSignaling();
  }

  Future<void> _connectSignaling() async {
    _channel.stream.listen((message) async {
      final data = jsonDecode(message);

      if (data['type'] == 'offer') {
        await _createAnswer(data['sdp']);
      } else if (data['type'] == 'answer') {
        await _peerConnection?.setRemoteDescription(
          RTCSessionDescription(data['sdp'], 'answer'),
        );
      } else if (data['type'] == 'candidate') {
        final candidate = RTCIceCandidate(
          data['candidate'],
          '',
          data['sdpMLineIndex'],
        );
        await _peerConnection?.addCandidate(candidate);
      }
    });
  }

  Future<void> createOffer() async {
    _peerConnection = await _createPeerConnection();
    _dataChannel = await _peerConnection!.createDataChannel(
      'chat',
      RTCDataChannelInit(),
    );
    _setupDataChannel();

    final offer = await _peerConnection!.createOffer();
    await _peerConnection!.setLocalDescription(offer);

    _channel.sink.add(jsonEncode({
      'type': 'offer',
      'sdp': offer.sdp,
    }));
  }

  Future<void> _createAnswer(String sdp) async {
    _peerConnection = await _createPeerConnection();
    _peerConnection!.onDataChannel = (RTCDataChannel channel) {
      _dataChannel = channel;
      _setupDataChannel();
    };

    await _peerConnection!.setRemoteDescription(
      RTCSessionDescription(sdp, 'offer'),
    );

    final answer = await _peerConnection!.createAnswer();
    await _peerConnection!.setLocalDescription(answer);

    _channel.sink.add(jsonEncode({
      'type': 'answer',
      'sdp': answer.sdp,
    }));
  }

  Future<RTCPeerConnection> _createPeerConnection() async {
    final Map<String, dynamic> config = {
      // 'iceServers': [
      //   {'urls': 'stun:stun.l.google.com:19302'}
      // ]
    };

    final pc = await createPeerConnection(config);

    pc.onIceCandidate = (candidate) {
      if (candidate != null) {
        _channel.sink.add(jsonEncode({
          'type': 'candidate',
          'candidate': candidate.candidate,
          'sdpMLineIndex': candidate.sdpMLineIndex,
        }));
      }
    };

    return pc;
  }

  void _setupDataChannel() {
    _dataChannel?.onMessage = (RTCDataChannelMessage message) {
      if (onMessageReceived != null) {
        onMessageReceived!(message.text);
      }
    };
  }

  void sendMessage(String message) {
    if (message.isNotEmpty && _dataChannel != null) {
      _dataChannel!.send(RTCDataChannelMessage(message));
    }
  }

  void dispose() {
    _channel.sink.close();
  }
}
