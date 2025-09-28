import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../services/call_service.dart';
import 'package:firebase_database_platform_interface/firebase_database_platform_interface.dart';

const String homeRoute = '/homepage';

class CallScreen extends StatefulWidget {
 final String callId;
 final String myId;
 final String peerId;
 final CallService callService;

 const CallScreen({
  super.key,
  required this.callId,
  required this.myId,
  required this.peerId,
  required this.callService,
 });

 @override
 State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
 final dbRef = FirebaseDatabase.instance.ref();
 Stopwatch _stopwatch = Stopwatch();
 int _seconds = 0;
 StreamSubscription? _statusSub;
 bool _isNavigating = false;

 @override
 void initState() {
  super.initState();
  _startTimer();

  final userRef = dbRef.child("users/${widget.myId}");
  userRef.onDisconnect().update({
   "status": "offline",
   "callStatus": "idle",
   "incomingCallId": null,
  });

  _statusSub = dbRef.child("calls/${widget.callId}/status").onValue.listen((
   event,
  ) async {
   final status = event.snapshot.value;
   if (status == "ended" && !_isNavigating) {
    
    await _performCleanupAndNavigate(context, isLocalEnder: false); 
   }
  });
 }

 void _startTimer() {
  _stopwatch.start();
  Future.doWhile(() async {
   await Future.delayed(const Duration(seconds: 1));
   if (mounted) setState(() => _seconds = _stopwatch.elapsed.inSeconds);
   return mounted;
  });
 }

 
 
 
 Future<void> _handleTalksIncrement() async {
  const int requiredDuration = 30;

  if (_seconds >= requiredDuration) {
   try {
    
    final Map<String, dynamic> updates = {
     "users/${widget.myId}/talks": ServerValue.increment(1),
     "users/${widget.peerId}/talks": ServerValue.increment(1),
    };
    await dbRef.update(updates);
    debugPrint("Talks successfully incremented for both users.");
   } catch (e) {
    debugPrint("Failed to increment talks: $e");
   }
  }
 }
 

 Future<void> _performCleanupAndNavigate(
  BuildContext context, {
  required bool isLocalEnder, 
 }) async {
  if (_isNavigating) return;
  _isNavigating = true;

  
  try {
   await widget.callService.safeDispose();
   await dbRef.child("users/${widget.myId}").update({
    "callStatus": "idle",
    "incomingCallId": null,
   });
  } catch (e) {
   debugPrint("Local Cleanup Failed: $e");
  }

  
  try {
   if (isLocalEnder) {
    
    Future.delayed(const Duration(seconds: 2), () {
     dbRef.child("calls/${widget.callId}").remove();
    });
   } else {
    
    dbRef.child("calls/${widget.callId}").remove();
   }
  } catch (e) {
   debugPrint("Room cleanup failed: $e");
  }

  
  final userRef = dbRef.child("users/${widget.myId}/incomingCallId");
  userRef.onValue.listen((event) {
   if (event.snapshot.value == null) {
    userRef.onDisconnect(); 

    if (mounted) {
     Navigator.pushNamedAndRemoveUntil(
      context,
      homeRoute,
      (route) => false,
     );
    }
   }
  });
 }

 Future<void> _endCallByLocalUser() async {
  if (_isNavigating) return;

  
  await _handleTalksIncrement(); 
  
  
  try {
   await dbRef.child("calls/${widget.callId}/status").set("ended");
  } catch (e) {
   debugPrint(" Status Update Error: $e");
  }

  
  try {
   await dbRef.child("users/${widget.myId}").onDisconnect().cancel();
   await dbRef.child("users/${widget.myId}").update({
    "status": "online",
    "callStatus": "idle",
    "incomingCallId": null,
   });
  } catch (e) {
   debugPrint(" Failed to cancel onDisconnect / update status: $e");
  }

  
  await _performCleanupAndNavigate(context, isLocalEnder: true); 
 }

 @override
 void dispose() {
  _stopwatch.stop();
  _statusSub?.cancel();
  super.dispose();
 }

 String _formatDuration(int seconds) {
  final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
  final secs = (seconds % 60).toString().padLeft(2, '0');
  return "$minutes:$secs";
 }

 @override
 Widget build(BuildContext context) {
    
    final size = MediaQuery.of(context).size;
    final isLandscape = size.width > size.height;
    final shortestSide = size.shortestSide;


    
    final buttonSize = shortestSide * (isLandscape ? 0.10 : 0.15); 
    final endCallButtonSize = shortestSide * (isLandscape ? 0.12 : 0.18); 
    final avatarRadius = shortestSide * (isLandscape ? 0.15 : 0.20); 

  return Scaffold(
   backgroundColor: Colors.black,
   body: SafeArea(
        child: isLandscape
            ? Column( 
                children: [
                    Expanded(
                        flex: 1,
                        child: _buildCallInfo(context, avatarRadius), 
                    ),
                    _buildControls(buttonSize, endCallButtonSize), 
                ],
            )
            : Column( 
                children: [
                    Expanded(
                        flex: 2,
                        child: _buildCallInfo(context, avatarRadius),
                    ),
                    Expanded(
                        flex: 1,
                        child: _buildControls(buttonSize, endCallButtonSize),
                    ),
                ],
            ),
   ),
  );
 }

    
    Widget _buildCallInfo(BuildContext context, double avatarRadius) {
        return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
                const SizedBox(height: 20),
                CircleAvatar(
                    radius: avatarRadius,
                    backgroundImage: const AssetImage("assets/profile2.png"),
                ),
                
                const SizedBox(height: 8),
                const Text(
                    "On Call...",
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 16),
                Text(
                    _formatDuration(_seconds),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                    ),
                ),
            ],
        );
    }

    
    Widget _buildControls(double buttonSize, double endCallButtonSize) {
        final isMicOn = widget.callService.isMicOn;
        final isSpeakerOn = widget.callService.isSpeakerOn;
        
        return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
                Padding(
                    padding: const EdgeInsets.only(bottom: 40),
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                            
                            _buildControlColumn(
                                buttonSize: buttonSize,
                                icon: isMicOn ? Icons.mic : Icons.mic_off,
                                iconColor: isMicOn ? Colors.white : Colors.red,
                                bgColor: isMicOn
                                    ? Colors.grey.withOpacity(0.2)
                                    : Colors.red.withOpacity(0.3),
                                label: isMicOn ? "Mute" : "Unmute",
                                onPressed: () async {
                                    await widget.callService.toggleMic();
                                    setState(() {}); 
                                },
                            ),

                            
                            _buildControlColumn(
                                buttonSize: endCallButtonSize,
                                icon: Icons.call_end,
                                iconColor: Colors.white,
                                bgColor: Colors.red,
                                label: "End",
                                onPressed: _endCallByLocalUser,
                                iconSize: 30,
                            ),

                            
                            _buildControlColumn(
                                buttonSize: buttonSize,
                                icon: isSpeakerOn ? Icons.volume_up : Icons.hearing,
                                iconColor: isSpeakerOn ? Colors.green : Colors.white,
                                bgColor: isSpeakerOn
                                    ? Colors.green.withOpacity(0.3)
                                    : Colors.grey.withOpacity(0.2),
                                label: "Speaker",
                                onPressed: () async {
                                    await widget.callService.toggleSpeaker();
                                    setState(() {}); 
                                },
                            ),
                        ],
                    ),
                ),
            ],
        );
    }

    
    Widget _buildControlColumn({
        required double buttonSize,
        required IconData icon,
        required Color iconColor,
        required Color bgColor,
        required String label,
        required VoidCallback onPressed,
        double iconSize = 24,
    }) {
        return Column(
            children: [
                Container(
                    width: buttonSize,
                    height: buttonSize,
                    decoration: BoxDecoration(
                        color: bgColor,
                        shape: BoxShape.circle,
                    ),
                    child: IconButton(
                        onPressed: onPressed,
                        icon: Icon(
                            icon,
                            color: iconColor,
                            size: iconSize,
                        ),
                    ),
                ),
                const SizedBox(height: 8),
                Text(
                    label,
                    style: const TextStyle(color: Colors.white70),
                ),
            ],
        );
    }
}