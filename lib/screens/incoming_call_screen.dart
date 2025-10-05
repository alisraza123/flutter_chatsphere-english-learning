import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:lottie/lottie.dart';
import '../services/call_service.dart';
import 'call_screen.dart';

const String homeRoute = '/homepage';

class IncomingCallScreen extends StatefulWidget {
  final String callId;
  final String myId;
  final CallService callService;

  const IncomingCallScreen({
    super.key,
    required this.callId,
    required this.myId,
    required this.callService,
  });

  @override
  State<IncomingCallScreen> createState() => _IncomingCallScreenState();
}

class _IncomingCallScreenState extends State<IncomingCallScreen> {
  final dbRef = FirebaseDatabase.instance.ref();

  @override
  void initState() {
    super.initState();

    
    dbRef.child("calls/${widget.callId}").onValue.listen((event) {
      if (!event.snapshot.exists) {
        _navigateToHome();
      }
    });
  }

  void _navigateToHome() {
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        homeRoute,
        (route) => false,
      );
    }
  }

  Future<void> rejectCall() async {
    
    final snap = await dbRef.child("calls/${widget.callId}/callerId").get();
    final callerId = snap.value?.toString();

    
    await dbRef.child("calls/${widget.callId}").remove();

    
    await dbRef.child("users/${widget.myId}").update({
      "callStatus": "idle",
      "incomingCallId": null,
    });

    
    if (callerId != null) {
      await dbRef.child("users/$callerId").update({
        "callStatus": "idle",
        "incomingCallId": null,
      });
    }

    _navigateToHome();
  }

  Future<void> acceptCall() async {
    final snap = await dbRef.child("calls/${widget.callId}").get();
    final data = snap.value as Map<dynamic, dynamic>?;

    if (data == null || !data.containsKey("callerId")) {
      _navigateToHome();
      return;
    }

    final remoteId = data["callerId"] as String;

    // Mark status in DB
    await dbRef.child("calls/${widget.callId}/status").set("accepted");
    await dbRef.child("users/${widget.myId}").update({"callStatus": "on_call"});

    // ✅ Init mic+camera before moving to CallScreen
    await widget.callService.initLocalMedia();

    // ✅ Create Answer in Firebase
    await widget.callService.createRoomConnection(
      widget.callId,
      isCaller: false,
    );

    // ✅ Only after offer/answer is set → move to call screen
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => CallScreen(
            callService: widget.callService,
            callId: widget.callId,
            myId: widget.myId,
            peerId: remoteId,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        // --- 1. Background Color Change ---
        backgroundColor: Colors.white, 
        // ----------------------------------
        body: Padding(
          padding: const EdgeInsets.only(bottom: 40.0), // Padding to lift the buttons up
          child: Column(
            // --- Content Alignment Change ---
            mainAxisAlignment: MainAxisAlignment.end, 
            // --------------------------------
            children: [
              
              // Top Content (Pushed up by MainAxisAlignment.end and Spacer)
              const Spacer(flex: 1), 
              
              Lottie.asset('assets/calling.json', width: 200, height: 200),
              const SizedBox(height: 20),
              const Text(
                "Incoming Call",
                style: TextStyle(
                  // --- Text Color Change for White BG ---
                  color: Colors.black87, 
                  // -------------------------------------
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "You have a new call...",
                style: TextStyle(
                  // --- Text Color Change for White BG ---
                  color: Colors.grey, 
                  // -------------------------------------
                  fontSize: 16
                ),
              ),
              
              const Spacer(flex: 1), // Spacer to push the buttons down slightly less
              
              // Buttons Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Reject Button
                  Column(
                    children: [
                      FloatingActionButton(
                        heroTag: "reject",
                        backgroundColor: Colors.red.shade700,
                        onPressed: rejectCall,
                        child: const Icon(Icons.call_end, size: 32, color: Colors.white),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Reject", 
                        style: TextStyle(
                          color: Colors.black87, // Color adjusted for white BG
                          fontWeight: FontWeight.w600,
                        )
                      ),
                    ],
                  ),
                  
                  // Accept Button
                  Column(
                    children: [
                      FloatingActionButton(
                        heroTag: "accept",
                        backgroundColor: const Color(0xFF1ea5fe),
                        onPressed: acceptCall,
                        child: const Icon(Icons.call, size: 32, color: Colors.white),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Accept", 
                        style: TextStyle(
                          color: Colors.black87, // Color adjusted for white BG
                          fontWeight: FontWeight.w600,
                        )
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}