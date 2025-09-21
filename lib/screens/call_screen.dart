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

    // 🔹 Set onDisconnect to update user status
    final userRef = dbRef.child("users/${widget.myId}");
    userRef.onDisconnect().update({
      "status": "offline",
      "callStatus": "idle",
      "incomingCallId": null,
    });

    // 🔹 Listen for remote end signal
    _statusSub = dbRef.child("calls/${widget.callId}/status").onValue.listen(
      (event) async {
        final status = event.snapshot.value;
        if (status == "ended" && !_isNavigating) {
          await _performCleanupAndNavigate(context, isCaller: false);
        }
      },
    );
  }

  void _startTimer() {
    _stopwatch.start();
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) setState(() => _seconds = _stopwatch.elapsed.inSeconds);
      return mounted;
    });
  }

  Future<void> _performCleanupAndNavigate(
      BuildContext context, {
        required bool isCaller,
      }) async {
    if (_isNavigating) return;
    _isNavigating = true;

    const int requiredDuration = 30;

    // Increment talks only by caller if duration >= 30 sec
    if (isCaller && _seconds >= requiredDuration) {
      try {
        final Map<String, dynamic> updates = {
          "users/${widget.myId}/talks": ServerValue.increment(1),
          "users/${widget.peerId}/talks": ServerValue.increment(1),
        };
        await dbRef.update(updates);
        debugPrint(" Talks incremented for both users");
      } catch (e) {
        debugPrint(" Failed to increment talks: $e");
      }
    }

    // Local cleanup
    try {
      await widget.callService.safeDispose();
      await dbRef.child("users/${widget.myId}").update({
        "callStatus": "idle",
        "incomingCallId": null,
      });
    } catch (e) {
      debugPrint(" Local Cleanup Failed: $e");
    }

    // Room deletion
    if (isCaller) {
      Future.delayed(const Duration(seconds: 2), () {
        dbRef.child("calls/${widget.callId}").remove().catchError((e) {
          debugPrint(" Caller Room Deletion Failed: $e");
        });
      });
    } else {
      dbRef.child("calls/${widget.callId}").remove().catchError((e) {
        debugPrint(" Callee Room Deletion Failed: $e");
      });
    }

    // Navigate to Home
    Future.microtask(() {
      if (mounted) Navigator.pushNamedAndRemoveUntil(context, homeRoute, (route) => false);
    });
  }

  Future<void> _endCallByLocalUser() async {
    if (_isNavigating) return;

    try {
      await dbRef.child("calls/${widget.callId}/status").set("ended");
    } catch (e) {
      debugPrint(" Status Update Error: $e");
    }

    // Cancel onDisconnect & update status manually
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

    await _performCleanupAndNavigate(context, isCaller: true);
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
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Top UI (unchanged)
            Expanded(
              flex: 2,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TweenAnimationBuilder(
                    tween: Tween<double>(begin: 0.9, end: 1.0),
                    duration: const Duration(seconds: 2),
                    curve: Curves.easeInOut,
                    builder: (context, double value, child) {
                      return Transform.scale(
                        scale: value,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.green.withOpacity(0.5), width: 2),
                            boxShadow: [
                              BoxShadow(color: Colors.green.withOpacity(0.3), blurRadius: 15, spreadRadius: 5),
                            ],
                          ),
                          child: CircleAvatar(
                            backgroundColor: Colors.transparent,
                            backgroundImage: const AssetImage("assets/profile.png"),
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [Colors.transparent, Colors.green.withOpacity(0.2)],
                                  stops: const [0.7, 1.0],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  Text(widget.peerId, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TweenAnimationBuilder(
                        tween: Tween<double>(begin: 0.5, end: 1.0),
                        duration: const Duration(milliseconds: 1000),
                        curve: Curves.easeInOut,
                        builder: (context, double value, child) {
                          return Container(
                            width: 10,
                            height: 10,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(value),
                              shape: BoxShape.circle,
                            ),
                          );
                        },
                      ),
                      const Text("On Call...", style: TextStyle(color: Colors.white70, fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(color: Colors.black.withOpacity(0.3), borderRadius: BorderRadius.circular(20)),
                    child: Text(_formatDuration(_seconds), style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500)),
                  ),
                ],
              ),
            ),
            // Bottom UI (unchanged)
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 40),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Mute
                        Column(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(color: Colors.grey.withOpacity(0.2), shape: BoxShape.circle),
                              child: IconButton(onPressed: () {}, icon: const Icon(Icons.mic_off, color: Colors.white)),
                            ),
                            const SizedBox(height: 8),
                            const Text("Mute", style: TextStyle(color: Colors.white70)),
                          ],
                        ),
                        // End
                        Column(
                          children: [
                            Container(
                              width: 70,
                              height: 70,
                              decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                              child: IconButton(onPressed: _endCallByLocalUser, icon: const Icon(Icons.call_end, color: Colors.white, size: 30)),
                            ),
                            const SizedBox(height: 8),
                            const Text("End", style: TextStyle(color: Colors.white70)),
                          ],
                        ),
                        // Speaker
                        Column(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(color: Colors.grey.withOpacity(0.2), shape: BoxShape.circle),
                              child: IconButton(onPressed: () {}, icon: const Icon(Icons.volume_up, color: Colors.white)),
                            ),
                            const SizedBox(height: 8),
                            const Text("Speaker", style: TextStyle(color: Colors.white70)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
