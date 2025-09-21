import 'dart:async';
import 'package:chatsphere/screens/profile_screen.dart';
import 'package:chatsphere/screens/settings_screen.dart';
import 'package:curved_labeled_navigation_bar/curved_navigation_bar.dart';
import 'package:curved_labeled_navigation_bar/curved_navigation_bar_item.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:lottie/lottie.dart';
import '../services/call_service.dart';
import 'incoming_call_screen.dart';
import 'call_screen.dart';

class HomeScreen extends StatefulWidget {
  final String myId;
  const HomeScreen({super.key, required this.myId});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final CallService callService = CallService();
  final dbRef = FirebaseDatabase.instance.ref();
  final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

  bool _isLoading = false;
  String? _activeCallId;
  StreamSubscription? _incomingCallListener;

  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // ---------------- INCOMING CALL LISTENER ----------------
    _incomingCallListener = dbRef
        .child("users/${widget.myId}/incomingCallId")
        .onValue
        .listen((event) {
          final callIdRaw = event.snapshot.value;
          final callId = callIdRaw != null ? callIdRaw.toString() : null;
          if (callId != null && mounted) {
            // ✅ Only push if not already loading or on call
            if (!_isLoading) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => IncomingCallScreen(
                    callId: callId,
                    myId: widget.myId,
                    callService: callService,
                  ),
                ),
              );
            }
          }
        });
  }

  @override
  void dispose() {
    _incomingCallListener?.cancel();
    super.dispose();
  }

  // ---------------- START RANDOM CALL ----------------
  Future<void> startRandomCall() async {
    setState(() => _isLoading = true);

    Future.delayed(const Duration(seconds: 10), () {
      if (mounted && _isLoading) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No user found, please try again")),
        );
      }
    });

    final snapshot = await dbRef.child("users").get();
    String? targetId;

    for (var child in snapshot.children) {
      final value = child.value;
      if (child.key != widget.myId && value is Map) {
        final data = Map<String, dynamic>.from(value);
        if (data["callStatus"] == "idle") {
          targetId = child.key;
          break;
        }
      }
    }

    if (targetId == null) return;

    final callId = dbRef.child("calls").push().key;
    _activeCallId = callId;

    await dbRef.child("calls/$callId").set({
      "callerId": widget.myId,
      "calleeId": targetId,
      "status": "ringing",
    });

    await dbRef.child("users/$targetId").update({
      "incomingCallId": callId,
      "callStatus": "busy",
    });
    await dbRef.child("users/${widget.myId}").update({"callStatus": "busy"});

    dbRef.child("calls/$callId/status").onValue.listen((event) async {
      final status = event.snapshot.value?.toString();
      if (status == "accepted") {
        await callService.initLocalMedia();
        await callService.createRoomConnection(callId!, isCaller: true);

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => CallScreen(
                myId: uid,
                peerId: targetId!,
                callService: callService,
                callId: callId,
              ),
            ),
          );
        }
      } else if (status == "rejected") {
        await dbRef.child("users/${widget.myId}").update({
          "callStatus": "idle",
        });
        if (mounted) setState(() => _isLoading = false);
      }
    });
  }

  // ---------------- USER LIST ----------------
  Widget buildUserList() {
    return StreamBuilder(
      stream: dbRef.child("users").onValue,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data?.snapshot.value == null) {
          // Show dummy tile if no data
          return _buildDummyTile();
        }

        final rawData = snapshot.data!.snapshot.value;
        if (rawData is! Map) return _buildDummyTile();

        final data = Map<String, dynamic>.from(rawData);

        final users = data.entries
            .where((e) {
              final value = e.value;
              return value is Map;
            })
            .where((e) {
              final u = Map<String, dynamic>.from(e.value as Map);
              return e.key != widget.myId &&
                  (u["status"] ?? "offline") == "online";
            })
            .toList();

        if (users.isEmpty) {
          return _buildDummyTile();
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(5),
          itemCount: users.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final user = Map<String, dynamic>.from(users[index].value);

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Card(
                color: Colors.white,
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  leading: CircleAvatar(
                    radius: 28,
                    backgroundImage:
                        user["hasProfileImage"] == true &&
                            user["imageUrl"] != ""
                        ? NetworkImage(user["imageUrl"])
                        : null,
                    child: user["hasProfileImage"] == false
                        ? const Icon(Icons.person, size: 30)
                        : null,
                  ),
                  title: Text(
                    user["name"] ?? "Unknown",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Gender: ${user["gender"] ?? 'N/A'}",
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "Level: ${user["level"] ?? 'N/A'} | Talks: ${user["talks"] ?? '0'}",
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                  trailing: Container(
                    width: 14,
                    height: 14,
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Dummy tile widget
  Widget _buildDummyTile() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Card(
        color: Colors.white,
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 6,
          ),
          leading: CircleAvatar(
            radius: 28,
            backgroundColor: Colors.grey[300],

            child: Icon(Icons.person, size: 30, color: Colors.grey[600]),
          ),
          title: const Text(
            "No friends here",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          subtitle: const Text(
            "Please check back later",
            style: TextStyle(fontSize: 13, color: Colors.grey),
          ),
          trailing: Container(
            width: 14,
            height: 14,
            decoration: const BoxDecoration(
              color: Colors.grey, // Offline grey dot
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }

  // ---------------- MAIN UI ----------------
  @override
  Widget build(BuildContext context) {
    final screens = [
      SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 40),
            GestureDetector(
              onTap: startRandomCall,
              child: Lottie.asset(
                "assets/startCall.json",
                width: 200,
                height: 200,
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: const [
                  Text(
                    "Online Users",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            buildUserList(),
            const SizedBox(height: 20),
          ],
        ),
      ),
      ProfileScreen(),
      SettingsList(),
    ];

    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: _isLoading
            ? null
            : AppBar(
              automaticallyImplyLeading: false,
                backgroundColor: Colors.grey[100],
                // backgroundColor: _currentIndex == 1 || _currentIndex == 2
                //     ? Colors.white
                //     : const Color(0xFF16d7f8),
                title: Text(
                  _currentIndex == 0
                      ? "Chat Sphere"
                      : _currentIndex == 1
                      ? "Profile"
                      : "Settings",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                centerTitle: true,
              ),
        body: _isLoading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Lottie.asset(
                      "assets/loader.json",
                      width: 150,
                      height: 150,
                     
                    ),
      
                    const SizedBox(height: 20),
                    const Text(
                      "Looking for someone to connect...",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              )
            : IndexedStack(index: _currentIndex, children: screens),
        bottomNavigationBar: _isLoading
            ? null
            : CurvedNavigationBar(
                animationCurve: Curves.easeInOut, // Smooth curve
                animationDuration: const Duration(milliseconds: 500),
                backgroundColor: Colors.white, // ya jo color chahiye
                color: const Color(0XFF1ea5fe), // active bar color
                buttonBackgroundColor: const Color(0XFF1ea5fe),
                height: 60,
                index: _currentIndex,
                items: const [
                  CurvedNavigationBarItem(
                    child: Icon(Icons.home_outlined, color: Colors.white),
                    label: 'Home',
                    labelStyle: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  CurvedNavigationBarItem(
                    child: Icon(Icons.person, color: Colors.white),
                    label: 'Profile',
                    labelStyle: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  CurvedNavigationBarItem(
                    child: Icon(Icons.settings, color: Colors.white),
                    label: 'Settings',
                    labelStyle: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ), // label color
                  ),
                ],
                onTap: (i) => setState(() => _currentIndex = i),
              ),
      ),
    );
  }
}
