import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:firebase_database/firebase_database.dart';

class CallService {
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  RTCVideoRenderer? _remoteRenderer; 
  bool _speakerOn = false;
  bool _micOn = true; 

  final dbRef = FirebaseDatabase.instance.ref();

  CallService() {
    _remoteRenderer = RTCVideoRenderer();
    _remoteRenderer?.initialize();
  }

  RTCVideoRenderer? get remoteRenderer => _remoteRenderer;
  bool get isSpeakerOn => _speakerOn;
  bool get isMicOn => _micOn;

  
  Future<void> initLocalMedia() async {
    final mediaConstraints = {"audio": true, "video": false};
    _localStream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
  }

  
  Future<void> toggleMic() async {
    if (_localStream != null) {
      for (var track in _localStream!.getAudioTracks()) {
        track.enabled = !track.enabled;
        _micOn = track.enabled;
      }
    }
  }

  
  Future<void> toggleSpeaker() async {
    _speakerOn = !_speakerOn;
    await Helper.setSpeakerphoneOn(_speakerOn);
  }

  Future<void> safeDispose() async {
    try {
      await dispose();
    } catch (e) {
      debugPrint("❌ dispose error: $e");
    }
  }

  
  Future<void> createRoomConnection(String callId, {required bool isCaller}) async {
    final config = {
      "iceServers": [
        {"urls": "stun:stun.l.google.com:19302"},
      ]
    };

    _peerConnection = await createPeerConnection(config);

    
    if (_localStream != null) {
      for (var track in _localStream!.getTracks()) {
        await _peerConnection!.addTrack(track, _localStream!);
      }
    }

    
    _peerConnection!.onTrack = (event) {
      if (event.streams.isNotEmpty && _remoteRenderer != null) {
        _remoteRenderer?.srcObject = event.streams[0];
      }
    };

    
    _peerConnection!.onIceCandidate = (candidate) {
      if (candidate.candidate != null) {
        dbRef.child("calls/$callId/candidates").push().set({
          "candidate": candidate.candidate,
          "sdpMid": candidate.sdpMid,
          "sdpMLineIndex": candidate.sdpMLineIndex,
        });
      }
    };

    if (isCaller) {
      final offer = await _peerConnection!.createOffer();
      await _peerConnection!.setLocalDescription(offer);

      await dbRef.child("calls/$callId/offer").set({
        "sdp": offer.sdp,
        "type": offer.type,
      });

      dbRef.child("calls/$callId/answer").onValue.listen((event) async {
        if (event.snapshot.value != null) {
          final data = Map<String, dynamic>.from(event.snapshot.value as Map);
          final answer = RTCSessionDescription(data["sdp"], data["type"]);
          await _peerConnection!.setRemoteDescription(answer);
        }
      });
    } else {
      final offerSnapshot = await dbRef.child("calls/$callId/offer").get();
      if (offerSnapshot.value != null) {
        final data = Map<String, dynamic>.from(offerSnapshot.value as Map);
        final offer = RTCSessionDescription(data["sdp"], data["type"]);
        await _peerConnection!.setRemoteDescription(offer);

        final answer = await _peerConnection!.createAnswer();
        await _peerConnection!.setLocalDescription(answer);

        await dbRef.child("calls/$callId/answer").set({
          "sdp": answer.sdp,
          "type": answer.type,
        });
      }
    }

    
    dbRef.child("calls/$callId/candidates").onChildAdded.listen((event) async {
      final data = Map<String, dynamic>.from(event.snapshot.value as Map);
      final candidate = RTCIceCandidate(
        data["candidate"],
        data["sdpMid"],
        data["sdpMLineIndex"],
      );
      await _peerConnection!.addCandidate(candidate);
    });
  }

  
  Future<void> dispose() async {
    try {
      if (_localStream != null) {
        _localStream?.getTracks().forEach((track) => track.stop());
        await _localStream?.dispose();
        _localStream = null;
      }

      if (_peerConnection != null) {
        await _peerConnection?.close();
        _peerConnection = null;
      }

      if (_remoteRenderer != null) {
        if (_remoteRenderer!.textureId != null) {
          await _remoteRenderer!.dispose();
        }
        _remoteRenderer = null;
      }
    } catch (e) {
      debugPrint("❌ Error while disposing CallService: $e");
    }
  }
}
