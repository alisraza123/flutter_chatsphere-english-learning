import 'dart:async';
import 'package:chatsphere/appToast/appToast.dart';
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
  StreamSubscription? _availabilityListener;

  Timer? _callTimer;
  int _seconds = 20;
  bool _showCancelButton = true;

  int _attempts = 0;
  final int _maxAttempts = 3;
  Set<String> _usedUsers = {};

  int _currentIndex = 0;
  
  
  bool _isAvailableForCall = false; 
  

  int _userLevel = 1;
  int _userTalks = 0;
  String? _userCountry;
  String? _selectedCountry; 

  final List<String> countries = [
    "Pakistan",
    "India",
    "United States",
    "United Kingdom",
    "Canada",
    "Germany",
    "France",
    "Australia",
    "China",
    "Japan",
    "Saudi Arabia",
    "UAE",
    "Turkey",
    "Afghanistan",
  ];

  @override
  void initState() {
    super.initState();
    _listenToAvailability(); 

    
    dbRef.child("users/${widget.myId}").onValue.listen((event) {
      if (event.snapshot.value != null) {
        final userData = Map<String, dynamic>.from(event.snapshot.value as Map);
        if (mounted) {
          setState(() {
            _userLevel = userData["level"] ?? 1;
            _userTalks = userData["talks"] ?? 0;
            _userCountry = userData["country"]?.toString();
            
            _isAvailableForCall = userData["isAvailableForCall"] ?? false;
            
          });
        }
      }
    });

    
    _incomingCallListener = dbRef
        .child("users/${widget.myId}/incomingCallId")
        .onValue
        .listen((event) {
          final callIdRaw = event.snapshot.value;
          final callId = callIdRaw != null ? callIdRaw.toString() : null;
          if (callId != null && mounted) {
            
            
            if (!_isAvailableForCall) {
              _rejectIncomingCallSilently(callId);
              return; 
            }
            
            
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

    
    final uid = FirebaseAuth.instance.currentUser!.uid;

    FirebaseDatabase.instance.ref("users/$uid").update({
      "status": "online",
      "callStatus": "idle",
      "incomingCallId": null,
      
    });
    
    
    FirebaseDatabase.instance.ref("users/$uid").onDisconnect().update({
      "status": "offline",
      "callStatus": "idle",
      "incomingCallId": null,
      
    });
  }
  
  
  Future<void> _rejectIncomingCallSilently(String callId) async {
    try {
      await dbRef.child("calls/$callId").update({"status": "rejected"});
      await dbRef.child("users/${widget.myId}").update({
        "callStatus": "idle",
        "incomingCallId": null,
      });
    } catch (e) {
      if (kDebugMode) {
        print("Error silently rejecting call: $e");
      }
    }
  }
  

  
  void _listenToAvailability() {
    _availabilityListener = dbRef.child("users/${widget.myId}/isAvailableForCall").onValue.listen((event) {
      final isAvailable = event.snapshot.value as bool? ?? false;
      if (mounted) {
        setState(() {
          _isAvailableForCall = isAvailable;
        });
      }
    });
  }
  

  
  void _updateCallAvailability(bool newValue) {
    if (mounted) {
      setState(() {
        _isAvailableForCall = newValue;
      });
    }
    
    dbRef.child("users/${widget.myId}").update({
      "isAvailableForCall": newValue,
      "callStatus": "idle", 
      "incomingCallId": null,
    });
  }
  

  @override
  void dispose() {
    _incomingCallListener?.cancel();
    statusSub?.cancel();
    _callTimer?.cancel();
    _availabilityListener?.cancel();
    super.dispose();
  }

Future<bool> _showCountrySelectionDialog() async {
  final List<String> options = ["WorldWide", ...countries];
  bool wasCancelled = false;
  final primaryColor = const Color(0XFF1ea5fe); 
  final borderColor = Colors.grey.shade300;
  final hintColor = Colors.grey.shade600;

  await showDialog(
    context: context,
    builder: (BuildContext context) {
      String? tempSelected = _selectedCountry ?? (_userCountry ?? "WorldWide");

      if (!options.contains(tempSelected)) {
        tempSelected = "WorldWide";
      }

      return StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 10,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 25, 20, 15),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  
                  Text(
                    "Select Call Region",
                    style: TextStyle(
                      color: primaryColor,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 25),
                  
                  
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: "Region Filter",
                      labelStyle: TextStyle(color: hintColor, fontWeight: FontWeight.w500),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: borderColor, width: 1),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: borderColor, width: 1),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: primaryColor, width: 2),
                      ),
                    ),
                    value: tempSelected,
                    items: options.map((country) {
                      return DropdownMenuItem<String>(
                        value: country,
                        child: Text(
                          country == "WorldWide" 
                              ? "WorldWide (Global)" 
                              : (country == _userCountry ? "My Country ($country)" : country),
                          style: TextStyle(
                            fontWeight: country == tempSelected ? FontWeight.w600 : FontWeight.normal,
                            color: Colors.black87,
                            fontSize: 15,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (String? value) {
                      setState(() {
                        tempSelected = value;
                      });
                    },
                  ),
                  

                  const SizedBox(height: 30),
                  
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: <Widget>[
                      TextButton(
                        style: TextButton.styleFrom(
                           padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                        ),
                        child: Text(
                          "Cancel", 
                          style: TextStyle(
                            color: hintColor, 
                            fontWeight: FontWeight.w600, 
                            fontSize: 15
                          )
                        ),
                        onPressed: () {
                          wasCancelled = true;
                          _selectedCountry = null; 
                          Navigator.of(context).pop();
                        },
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          elevation: 5,
                        ),
                        child: const Text("Start Call", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        onPressed: tempSelected != null
                            ? () {
                                _selectedCountry = (tempSelected == "WorldWide") ? null : tempSelected;
                                Navigator.of(context).pop();
                              }
                            : null,
                      ),
                    ],
                  ),
                  
                ],
              ),
            ),
          );
        },
      );
    },
  );
  return wasCancelled;
}
  Future<void> startRandomCall() async {
    
    if (_isLoading) return;

    
    if (_userLevel >= 2 && _userTalks > 10) {
      
      if (_attempts == 0) { 
          _selectedCountry = null;
      }

      final bool wasCancelled = await _showCountrySelectionDialog();
      
      if (wasCancelled) {
          _selectedCountry = null; 
          return;
      }
    } else {
      _selectedCountry = null;
    }

    setState(() {
      _isLoading = true;
      _attempts = 0;
      _showCancelButton = true;
    });

    _usedUsers.clear();
    await _tryNextUser();

    if (!_isLoading) {
      
      _selectedCountry = null; 
      
      
      
      String message;
      
      if (_attempts >= _maxAttempts) {
        if (_selectedCountry != null) {
           message = "No users found in $_selectedCountry. Please try Worldwide.";
        } else {
           message = "No user wants to talk, please try again (Worldwide search failed).";
        }
      } else if (_usedUsers.isEmpty && _attempts == 1) {
        message = "No more user available at the moment.";
      } else {
        message = "Call search finished.";
      }
      
      AppToast.showError(message);
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

    if (snapshot.value is! Map) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    final dataMap = Map<String, dynamic>.from(snapshot.value as Map);
    
    for (var entry in dataMap.entries) {
      final key = entry.key;
      final value = entry.value;

      if (key != widget.myId && value is Map) {
        final data = Map<String, dynamic>.from(value as Map);

        final String? userCountry = data["country"]?.toString();
        
        bool countryMatch = true;
        if (_selectedCountry != null) {
          
          countryMatch = (userCountry?.toLowerCase() == _selectedCountry!.toLowerCase());
        }
        
        
        final bool isTargetAvailable = data["isAvailableForCall"] ?? false;
        
        
        if (countryMatch &&
            (data["callStatus"] ?? "idle") == "idle" &&
            !_usedUsers.contains(key) &&
            (data["status"] == "online") &&
            isTargetAvailable) { 
          if (data["incomingCallId"] == null) {
            idleUsers.add(key);
          }
        }
      }
    }

    if (idleUsers.isEmpty) {
      if (_attempts < _maxAttempts) {
        _tryNextUser(); 
        return;
      }
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    idleUsers.shuffle();
    final targetId = idleUsers.first;
    _usedUsers.add(targetId);

    final callId = dbRef.child("calls").push().key;
    if (callId == null) {
       if (mounted) setState(() => _isLoading = false);
       return;
    }
    
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
        await callService.createRoomConnection(callId, isCaller: true);
        
        
        _selectedCountry = null; 

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

        await _resetCallStateOnly(); 

        _tryNextUser();
      }
    });

    await Future.delayed(const Duration(seconds: 20));

    if (!callPicked && _isLoading && mounted) {
      await statusSub?.cancel();
      _callTimer?.cancel();

      await _resetCallStateOnly(); 

      _tryNextUser();
    }
  }
  Future<void> _resetCallStateOnly() async {
    if (_activeCallId != null && _targetId != null) {
      try {
        await dbRef.child("users/$_targetId").update({
          "callStatus": "idle",
          "incomingCallId": null,
          
        });

        await dbRef.child("users/${widget.myId}").update({
          "callStatus": "idle"
          
        });

        await dbRef.child("calls/$_activeCallId").remove();
      } catch (e) {
        if (kDebugMode) {
          print("Error resetting call state: $e");
        }
      }
    }
    _activeCallId = null;
    _targetId = null;
    _seconds = 20;
    
  }
  
  
  Future<void> _resetCall() async {
    await _resetCallStateOnly(); 
    _selectedCountry = null; 
  }
  

  Future<void> cancelRandomCall({bool isIncoming = false}) async {
    if (mounted) {
      setState(() => _isLoading = false);
    }
    _callTimer?.cancel();
    await statusSub?.cancel();
    await _resetCall(); 

    if (!isIncoming) {
      AppToast.showInfo("Call search cancelled");
    }
  }

 Widget buildUserList() {
  return StreamBuilder(
    stream: dbRef.child("users").onValue,
    builder: (context, snapshot) {
      // print(" Stream triggered: ${snapshot.connectionState}");

      if (!snapshot.hasData || snapshot.data?.snapshot.value == null) {
        // print(" No data found in Firebase snapshot");
        return _buildDummyTile();
      }

      final rawData = snapshot.data!.snapshot.value;
      // print(" Raw snapshot data type: ${rawData.runtimeType}");

      if (rawData is! Map) {
        // print(" Snapshot data is not a Map");
        return _buildDummyTile();
      }

      
      final data = Map<String, dynamic>.from(rawData);
      print("👥 Total users in database: ${data.length}");

      
      final users = data.entries.where((e) {
        print("➡️ Checking user: ${e.key}");
        if (e.value is! Map) {
          print("⚠️ Skipping ${e.key} (invalid data type)");
          return false;
        }

        final u = Map<String, dynamic>.from(e.value as Map);

        
        // print("   Name: ${u['name']}");
        // print("   Status: ${u['status']}");
        // print("   CallStatus: ${u['callStatus']}");
        // print("   isAvailableForCall: ${u['isAvailableForCall']}");

        
        final bool isUserAvailable = u["isAvailableForCall"] ?? false;

        
        if (e.key == widget.myId) {
          // print("  🚫 Skipping self user: ${u['name']}");
          return false;
        }

        final bool passesFilter =
            (u["status"] ?? "offline") == "online" &&
            (u["callStatus"] ?? "idle") == "idle" &&
            isUserAvailable;

        // print("   Passes Filter: $passesFilter");

        return passesFilter;
      }).toList();

      // print(" Filtered users count: ${users.length}");

      if (users.isEmpty) {
        // print(" No active users found after filtering");
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

          // print(" Building tile for: ${user['name']} (${users[index].key})");

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
                  child: (user["hasProfileImage"] != true ||
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
            if (_selectedCountry != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  "Region: ${_selectedCountry!} Users Only",
                  style: TextStyle(fontSize: 14, color: Colors.blue.shade700, fontWeight: FontWeight.bold),
                ),
              )
            else if (_userLevel >= 2 && _userTalks > 10)
               Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  "Worldwide Users",
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                ),
              )
            else
              const Padding(
                padding: EdgeInsets.only(top: 8.0),
                child: Text(
                  "Region: Worldwide Users",
                  style: TextStyle(fontSize: 14, color: Colors.black54),
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
      
      SettingsList(
        isAvailableForCall: _isAvailableForCall,
        onAvailabilityChanged: _updateCallAvailability,
      ),
      
    ];
final primaryColor = const Color(0XFF1ea5fe); // #1ea5fe
const whiteColor = Colors.white;
    return Scaffold(
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
    
              actions: [
             Padding(
               padding: const EdgeInsets.only(right: 10),
               child: ElevatedButton(
                   onPressed: () {
                     Navigator.pushNamed(context, '/pro');
                   },
                   style: ElevatedButton.styleFrom(
                     backgroundColor: primaryColor, // Blue background
                     foregroundColor: whiteColor,   // White text color
                     shape: RoundedRectangleBorder(
                       borderRadius: BorderRadius.circular(30), // Slightly rounded corners
                     ),
                     padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 8),
                     elevation: 5, // Subtle shadow
                   ),
                   child: const Text(
                     "Go Pro",
                     style: TextStyle(
                       fontWeight: FontWeight.bold,
                       fontSize: 15,
                     ),
                   ),
                 ),
             ),
              ],
            ),
      body: _isLoading
          ? SafeArea(
            child: Center(
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
                      "$_seconds seconds",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (_showCancelButton)
                      ElevatedButton(
                        onPressed: cancelRandomCall,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade500,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text("Cancel"),
                      ),
                  ],
                ),
              ),
          )
          : IndexedStack(index: _currentIndex, children: screens),
      bottomNavigationBar: _isLoading
          ? null
          : CurvedNavigationBar(
              animationCurve: Curves.easeInOut,
              animationDuration: Duration(milliseconds: (kIsWeb) ? 2000 : 8000),
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
    );
  }
}