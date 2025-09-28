import 'dart:async';
import 'package:chatsphere/screens/profile_screen.dart';
import 'package:chatsphere/screens/settings_screen.dart';
import 'package:curved_labeled_navigation_bar/curved_navigation_bar.dart';
import 'package:curved_labeled_navigation_bar/curved_navigation_bar_item.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
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
  String? _targetId;
  StreamSubscription? _incomingCallListener;
  StreamSubscription<DatabaseEvent>? statusSub;

  Timer? _callTimer;
  int _seconds = 20;
  bool _showCancelButton = true;

  int _attempts = 0;
  final int _maxAttempts = 3;
  Set<String> _usedUsers = {};

  int _currentIndex = 0;
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [const ProfileScreen(), const SettingsList()];

    _incomingCallListener = dbRef
        .child("users/${widget.myId}/incomingCallId")
        .onValue
        .listen((event) {
          final callIdRaw = event.snapshot.value;
          final callId = callIdRaw != null ? callIdRaw.toString() : null;
          if (callId != null && mounted) {
            if (_isLoading) {
              cancelRandomCall(isIncoming: true);
            }

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
        });
  }

  @override
  void dispose() {
    _incomingCallListener?.cancel();
    statusSub?.cancel();
    _callTimer?.cancel();
    super.dispose();
  }

  Future<void> startRandomCall() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _attempts = 0;
      _showCancelButton = true;
    });

    _usedUsers.clear();
    await _tryNextUser();

    if (!_isLoading) {
      if (_attempts >= _maxAttempts) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("No user wants to talk, please try again"),
          ),
        );
      } else if (_usedUsers.isEmpty && _attempts == 1) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No more user available at the moment")),
        );
      }
    }
  }

  Future<void> _tryNextUser() async {
    if (!_isLoading) {
      return;
    }

    if (_attempts >= _maxAttempts) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    _attempts++;

    final snapshot = await dbRef.child("users").get();
    final List<String> idleUsers = [];

    for (var child in snapshot.children) {
      if (child.key != widget.myId && child.value is Map) {
        final data = Map<String, dynamic>.from(child.value as Map);
        if ((data["callStatus"] ?? "idle") == "idle" &&
            !_usedUsers.contains(child.key)) {
          if (data["incomingCallId"] == null) {
            idleUsers.add(child.key!);
          }
        }
      }
    }

    if (idleUsers.isEmpty) {
      if (mounted) setState(() => _isLoading = false);
      _attempts = _maxAttempts;
      return;
    }

    idleUsers.shuffle();
    final targetId = idleUsers.first;
    _usedUsers.add(targetId);

    final callId = dbRef.child("calls").push().key;
    _activeCallId = callId;
    _targetId = targetId;

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

    bool callPicked = false;
    _seconds = 20;

    _callTimer?.cancel();
    _callTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() => _seconds--);
      }

      if (_seconds <= 0) timer.cancel();
    });

    await statusSub?.cancel();
    statusSub = dbRef.child("calls/$callId/status").onValue.listen((
      event,
    ) async {
      final status = event.snapshot.value?.toString();

      if (status == "accepted") {
        callPicked = true;
        _callTimer?.cancel();
        await statusSub?.cancel();

        await callService.initLocalMedia();
        await callService.createRoomConnection(callId!, isCaller: true);

        if (mounted) {
          setState(() => _isLoading = false);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => CallScreen(
                myId: uid,
                peerId: targetId,
                callService: callService,
                callId: callId,
              ),
            ),
          );
        }
      } else if (status == "rejected") {
        callPicked = false;
        _callTimer?.cancel();
        await statusSub?.cancel();

        await _resetCall();

        _tryNextUser();
      }
    });

    await Future.delayed(const Duration(seconds: 20));

    if (!callPicked && _isLoading && mounted) {
      await statusSub?.cancel();
      _callTimer?.cancel();

      await _resetCall();

      _tryNextUser();
    }
  }

  Future<void> _resetCall() async {
    if (_activeCallId != null && _targetId != null) {
      await dbRef.child("users/$_targetId").update({
        "callStatus": "idle",
        "incomingCallId": null,
      });

      await dbRef.child("users/${widget.myId}").update({"callStatus": "idle"});

      await dbRef.child("calls/$_activeCallId").remove();
    }
    _activeCallId = null;
    _targetId = null;
    _seconds = 20;
  }

  Future<void> cancelRandomCall({bool isIncoming = false}) async {
    if (mounted) {
      setState(() => _isLoading = false);
    }
    _callTimer?.cancel();
    await statusSub?.cancel();
    await _resetCall();

    if (isIncoming) {
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Call search cancelled.")));
    }
  }

  Widget buildUserList() {
    return StreamBuilder(
      stream: dbRef.child("users").onValue,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data?.snapshot.value == null) {
          return _buildDummyTile();
        }

        final rawData = snapshot.data!.snapshot.value;
        if (rawData is! Map) return _buildDummyTile();

        final data = Map<String, dynamic>.from(rawData);

        final users = data.entries.where((e) => e.value is Map).where((e) {
          final u = Map<String, dynamic>.from(e.value as Map);
          return e.key != widget.myId &&
              (u["status"] ?? "offline") == "online" &&
              (u["callStatus"] ?? "idle") == "idle";
        }).toList();

        if (users.isEmpty) return _buildDummyTile();

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
                    radius: 30,
                    backgroundColor: Colors.grey.shade200,
                    backgroundImage:
                        user["hasProfileImage"] == true &&
                            user["imageUrl"] != ""
                        ? NetworkImage(user["imageUrl"])
                        : null,
                    child:
                        (user["hasProfileImage"] != true ||
                            user["imageUrl"] == "")
                        ? Icon(
                            Icons.person,
                            size: 30,
                            color: Colors.grey.shade600,
                          )
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
              color: Colors.grey,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }

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
      const ProfileScreen(),
      const SettingsList(),
    ];

    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: _isLoading
            ? null
            : AppBar(
                automaticallyImplyLeading: false,
                backgroundColor: Colors.grey[100],
                title: Text(
                  _currentIndex == 0
                      ? "Chat Sphere"
                      : _currentIndex == 1
                      ? "Profile"
                      : "Settings",
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                centerTitle: true,
              ),
        body: _isLoading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Lottie.asset("assets/loader.json", width: 150, height: 150),
                    const SizedBox(height: 20),
                    Text(
                      _activeCallId != null
                          ? "Calling attempt $_attempts of $_maxAttempts..."
                          : "Looking for a user...",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Time left: $_seconds seconds",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (_showCancelButton)
                      ElevatedButton(
                        onPressed: cancelRandomCall,
                        child: const Text("Cancel"),
                      ),
                  ],
                ),
              )
            : IndexedStack(index: _currentIndex, children: screens),
        bottomNavigationBar: _isLoading
            ? null
            : CurvedNavigationBar(
                animationCurve: Curves.easeInOut,
                animationDuration: Duration(milliseconds: (kIsWeb) ? 500 : 600),
                backgroundColor: Colors.white,
                color: const Color(0XFF1ea5fe),
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
                    ),
                  ),
                ],
                onTap: (i) => setState(() => _currentIndex = i),
              ),
      ),
    );
  }
}
