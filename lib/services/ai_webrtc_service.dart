import 'dart:async';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class AiWebRtcService {
  RTCPeerConnection? _pc;
  MediaStream? _localStream;
  final RTCVideoRenderer localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer remoteRenderer = RTCVideoRenderer();

  RTCDataChannel? _analysisChannel;
  final StreamController<String> _analysisTextController = StreamController.broadcast();
  Stream<String> get analysisTextStream => _analysisTextController.stream;

  Future<void> initialize() async {
    await localRenderer.initialize();
    await remoteRenderer.initialize();
  }

  Future<void> dispose() async {
    try {
      await _analysisChannel?.close();
      await _analysisTextController.close();
      await localRenderer.dispose();
      await remoteRenderer.dispose();
      await _localStream?.dispose();
      await _pc?.close();
    } catch (_) {}
  }

  Future<void> startLocalMedia({bool video = true, bool audio = true}) async {
    final Map<String, dynamic> constraints = {
      'audio': audio,
      'video': video
          ? {
              'facingMode': 'user',
              'width': {'ideal': 1280},
              'height': {'ideal': 720},
              'frameRate': {'ideal': 30},
            }
          : false,
    };
    _localStream = await navigator.mediaDevices.getUserMedia(constraints);
    localRenderer.srcObject = _localStream;
  }

  Future<void> initializePeerConnection() async {
    final config = {
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
      ]
    };
    final constraints = <String, dynamic>{
      'mandatory': {},
      'optional': [
        {'DtlsSrtpKeyAgreement': true},
      ],
    };
    _pc = await createPeerConnection(config, constraints);

    // Local tracks
    final stream = _localStream;
    if (stream != null) {
      for (final track in stream.getTracks()) {
        await _pc!.addTrack(track, stream);
      }
    }

    // Remote track handler
    _pc!.onTrack = (RTCTrackEvent event) {
      if (event.streams.isNotEmpty) {
        remoteRenderer.srcObject = event.streams.first;
      }
    };

    // Incoming data channels (if remote creates)
    _pc!.onDataChannel = (RTCDataChannel channel) {
      if (channel.label == 'analysis') {
        _attachAnalysisChannel(channel);
      }
    };

    // Create our analysis data channel for receiving AI annotations
    _analysisChannel = await _pc!.createDataChannel('analysis', RTCDataChannelInit()..ordered = true);
    _attachAnalysisChannel(_analysisChannel!);
  }

  void _attachAnalysisChannel(RTCDataChannel channel) {
    channel.onMessage = (RTCDataChannelMessage msg) {
      final text = msg.isBinary ? null : msg.text;
      if (text != null && text.trim().isNotEmpty) {
        _analysisTextController.add(text);
      }
    };
  }

  // Optional: send client-side hints/events to AI backend
  Future<void> sendClientEvent(String event, Map<String, dynamic> payload) async {
    final ch = _analysisChannel;
    if (ch == null) return;
    final body = {'event': event, 'data': payload};
    ch.send(RTCDataChannelMessage(body.toString()));
  }

  // TODO: Implement signaling with your backend/AI provider
  Future<RTCSessionDescription> createOffer() async {
    final offer = await _pc!.createOffer({
      'offerToReceiveAudio': true,
      'offerToReceiveVideo': true,
    });
    await _pc!.setLocalDescription(offer);
    return offer;
  }

  Future<void> setRemoteDescription(String sdp, String type) async {
    final desc = RTCSessionDescription(sdp, type);
    await _pc!.setRemoteDescription(desc);
  }

  void addIceCandidate(RTCIceCandidate candidate) {
    _pc?.addCandidate(candidate);
  }
} 