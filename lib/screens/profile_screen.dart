import 'package:chatsphere/screens/profile_upload_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<Map<String, dynamic>?> _fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    final snapshot = await FirebaseDatabase.instance
        .ref("users/${user.uid}")
        .get();

    if (snapshot.exists) {
      return Map<String, dynamic>.from(snapshot.value as Map);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: Colors.white,
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _fetchUserData(),
        builder: (context, snapshot) {
          
          
          
          
          
          
          
          

          if (!snapshot.hasData || snapshot.data == null) {
            return Center(
              child: Text(
                "No user data found",
                style: TextStyle(color: Color(0xFF1ea5fe), fontSize: 16),
              ),
            );
          }

          final userData = snapshot.data!;
          final user = FirebaseAuth.instance.currentUser;

          final imageUrl = userData["hasProfileImage"] == true
              ? userData["imageUrl"] ?? ""
              : "";
          final name = userData["name"] ?? "Unknown";
          final email = user?.email ?? "No Email";
          final gender = userData["gender"] ?? "N/A";
          final level = userData["level"]?.toString() ?? "0";
          final talks = userData["talks"]?.toString() ?? "0";
          final country = userData["country"] ?? "Not Set";

          return LayoutBuilder(
            builder: (context, constraints) {
              final bool isPortrait =
                  constraints.maxHeight > constraints.maxWidth;
          

              return SingleChildScrollView(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.only(
                        top: 40,
                        left: 20,
                        right: 20,
                        bottom: 30,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF1ea5fe), Color(0xFF16d7f8)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(30),
                          bottomRight: Radius.circular(30),
                        ),
                      ),
                      child: Column(
                        children: [
                          
                          LayoutBuilder(
                            builder: (context, constraints) {
                              double avatarSize =
                                  constraints.maxWidth *
                                  0.35; 

                              return Center(
                                child: GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            ProfileUploadScreen(uid: uid),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    width: avatarSize,
                                    height: avatarSize,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                    
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.2),
                                          blurRadius: 12,
                                          offset: const Offset(0, 6),
                                        ),
                                      ],
                                    ),
                                    padding: const EdgeInsets.all(
                                      4,
                                    ), 
                                    child: CircleAvatar(
                                      backgroundColor: Colors.white,
                                      backgroundImage: imageUrl.isNotEmpty
                                          ? NetworkImage(imageUrl)
                                          : const AssetImage(
                                                  "assets/default_avatar.png",
                                                )
                                                as ImageProvider,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          SizedBox(height: 20),

                          
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Flexible(
                                child: Text(
                                  name,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: isPortrait
                                        ? constraints.maxWidth * 0.065
                                        : constraints.maxHeight * 0.055,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              SizedBox(width: 10),
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: IconButton(
                                  icon: Icon(
                                    Icons.edit,
                                    size: 20,
                                    color: Colors.white,
                                  ),
                                  onPressed: () {
                                    _showEditDialog(
                                      context,
                                      "Edit Name",
                                      "Enter new name",
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),

                          
                          Text(
                            email,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: isPortrait
                                  ? constraints.maxWidth * 0.04
                                  : constraints.maxHeight * 0.035,
                              color: Colors.white.withOpacity(0.9),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

                    
                    Transform.translate(
                      offset: Offset(0, -20),
                      child: Container(
                        width: double.infinity,
                        margin: EdgeInsets.symmetric(horizontal: 20),
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 15,
                              offset: Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildStatItem(
                                  "Level",
                                  level,
                                  Icons.star_rate_rounded,
                                ),
                                _buildStatItem(
                                  "Talks",
                                  talks,
                                  Icons.chat_bubble_outline,
                                ),
                              ],
                            ),
                            SizedBox(height: 20),

                            
                            _buildInfoSection(
                              context,
                              gender: gender,
                              country: country,
                            ),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: 20),

                    
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          
                          Container(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                _showEditDialog(
                                  context,
                                  "Change Password",
                                  "Enter new password",
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFF1ea5fe),
                                foregroundColor: Colors.white,
                                minimumSize: Size(double.infinity, 55),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(
                                    color: Color(0xFF1ea5fe),
                                    width: 1.5,
                                  ),
                                ),
                                elevation: 0,
                                padding: EdgeInsets.symmetric(horizontal: 20),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.lock_reset, size: 20),
                                  SizedBox(width: 10),
                                  Text(
                                    "Change Password",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: 15),

                          
                          Container(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () async {
                                final shouldLogout = await showDialog<bool>(
                                  context: context,
                                  builder: (context) {
                                    return AlertDialog(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      title: Row(
                                        children: [
                                          Text(
                                            "Confirm Sign Out",
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                      content: Text(
                                        "Are you sure you want to sign out?",
                                        style: TextStyle(fontSize: 15),
                                      ),
                                      actionsPadding: EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      actions: [
                                        TextButton(
                                          style: TextButton.styleFrom(
                                            foregroundColor:
                                                Colors.grey.shade700,
                                          ),
                                          onPressed: () =>
                                              Navigator.pop(context, false),
                                          child: Text("No"),
                                        ),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.redAccent,
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                          onPressed: () =>
                                              Navigator.pop(context, true),
                                          child: Text("Yes"),
                                        ),
                                      ],
                                    );
                                  },
                                );

                                if (shouldLogout == true) {
                                  final user =
                                      FirebaseAuth.instance.currentUser;
                                  if (user != null) {
                                    final uid = user.uid;
                                    await FirebaseDatabase.instance
                                        .ref("users/$uid")
                                        .update({
                                          "status": "offline",
                                          "callStatus": "idle",
                                          "incomingCallId": null,
                                        });
                                    await FirebaseAuth.instance.signOut();
                                  }
                                  Navigator.pushReplacementNamed(
                                    context,
                                    '/login',
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.redAccent,
                                foregroundColor: Colors.white,
                                minimumSize: Size(double.infinity, 55),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                                padding: EdgeInsets.symmetric(horizontal: 20),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.logout, size: 20),
                                  SizedBox(width: 10),
                                  Text(
                                    "Sign Out",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 30),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildStatItem(String title, String value, IconData icon) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Color(0xFF1ea5fe).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Color(0xFF1ea5fe), size: 24),
        ),
        SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1ea5fe),
          ),
        ),
        Text(
          title,
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  
  Widget _buildInfoSection(
    BuildContext context, {
    required String gender,
    required String country,
  }) {
    return Column(
      children: [
        _infoRow(Icons.person_outline, "Gender", gender),
        Divider(color: Colors.grey.shade200, height: 20),
        _infoRow(Icons.flag_outlined, "Country", country),
      ],
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Color(0xFF1ea5fe).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Color(0xFF1ea5fe), size: 22),
          ),
          SizedBox(width: 15),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Color(0xFF1ea5fe),
            ),
          ),
        ],
      ),
    );
  }

  
  void _showEditDialog(BuildContext context, String title, String hint) {
    final TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Color(0xFF1ea5fe),
                  ),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    hintText: hint,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Color(0xFF1ea5fe)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Color(0xFF1ea5fe),
                        width: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        "Cancel",
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ),
                    SizedBox(width: 10),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF1ea5fe),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        debugPrint("$title: ${controller.text}");
                        Navigator.pop(context);
                      },
                      child: Text("OK"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
