import 'dart:convert';
import 'dart:typed_data';
import 'dart:io' as io;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_database/firebase_database.dart';
import 'package:chatsphere/screens/home_screen.dart';
import 'package:toastification/toastification.dart';
import 'dart:ui'; // Glassmorphism के लिए

// --- Modern Light Mode Palette ---
const Color kLightBackground = Color(0xFFEFEFF4); // Soft Light Background
const Color kCardSurface = Color.fromARGB(
  255,
  255,
  255,
  255,
); // White Card Surface
const Color kPrimaryColor = Color(0xFF1ea5fe); // Button BG: #1ea5fe (Dark Blue)
const Color kAccentColor = Color(
  0xFF16d7f8,
); // Accent: #16d7f8 (Cyan/Light Blue)
const Color kPrimaryText = Color(0xFF333333); // Dark Text

class ProfileUploadScreen extends StatefulWidget {
  final String uid;
  const ProfileUploadScreen({super.key, required this.uid});

  @override
  State<ProfileUploadScreen> createState() => _ProfileUploadScreenState();
}

class _ProfileUploadScreenState extends State<ProfileUploadScreen> {
  Uint8List? webImage; // for Web
  io.File? fileImage; // for Mobile
  bool loading = false;
  final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
  final picker = ImagePicker();
  final dbRef = FirebaseDatabase.instance.ref("users");

  // 🔹 Cloudinary Credentials (LOGIC UNCHANGED)
  final String cloudName = "dixilrnkq";
  final String uploadPreset = "chatsphere";

  // 💬 Logic: Image Picking (NO CHANGE)
  Future<void> pickImage() async {
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      if (kIsWeb) {
        var f = await picked.readAsBytes();
        setState(() => webImage = f);
      } else {
        setState(() => fileImage = io.File(picked.path));
      }
    }
  }

  // 💬 Logic: Upload to Cloudinary (NO CHANGE)
  Future<String?> uploadToCloudinary() async {
    try {
      String url = "https://api.cloudinary.com/v1_1/$cloudName/image/upload";

      var request = http.MultipartRequest("POST", Uri.parse(url));
      request.fields["upload_preset"] = uploadPreset;

      if (kIsWeb && webImage != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'file',
            webImage!,
            filename: "profile.png",
          ),
        );
      } else if (!kIsWeb && fileImage != null) {
        request.files.add(
          await http.MultipartFile.fromPath('file', fileImage!.path),
        );
      } else {
        return null;
      }

      var response = await request.send();
      var resBody = await response.stream.bytesToString();
      var data = jsonDecode(resBody);

      if (response.statusCode == 200) {
        return data["secure_url"];
      } else {
        throw Exception(data["error"]["message"]);
      }
    } catch (e) {
      toastification.show(
        context: context,
        title: Text(
          "Upload failed: $e",
          style: const TextStyle(color: Colors.black),
        ),
        type: ToastificationType.error,
        alignment: Alignment.topCenter,
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        showProgressBar: false,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        borderRadius: BorderRadius.circular(12),
        autoCloseDuration: const Duration(seconds: 3),
      );

      return null;
    }
  }

  // 💬 Logic: Save Profile (NO CHANGE)
  Future<void> saveProfile({String? imageUrl, bool skip = false}) async {
    try {
      setState(() => loading = true);

      await dbRef.child(widget.uid).update({
        "imageUrl": imageUrl ?? "",
        "hasProfileImage": true,
      });

      toastification.show(
        context: context,
        title: Text(
          skip ? "Skipped profile upload" : "Profile updated",
          style: const TextStyle(color: Colors.black),
        ),
        type: ToastificationType.success,
        alignment: Alignment.topCenter,
        backgroundColor: const Color(0xFF1ea5fe),
        foregroundColor: const Color(0xFF16d7f8),
        showProgressBar: false,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        borderRadius: BorderRadius.circular(12),
        autoCloseDuration: const Duration(seconds: 3),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => HomeScreen(myId: uid)),
      );
    } catch (e) {
      toastification.show(
        context: context,
        title: Text(e.toString(), style: const TextStyle(color: Colors.black)),
        type: ToastificationType.error,
        alignment: Alignment.topCenter,
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        showProgressBar: false,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        borderRadius: BorderRadius.circular(12),
        autoCloseDuration: const Duration(seconds: 3),
      );
    } finally {
      setState(() => loading = false);
    }
  }

  // 🖼️ Helper Widget for Glassmorphism Background
  Widget _buildGlassCard({
    required Widget child,
    required double shortestSide,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(shortestSide * 0.05),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), // The Blur Effect
        child: Container(
          decoration: BoxDecoration(
            color: kCardSurface.withOpacity(0.8), // Semi-transparent white
            borderRadius: BorderRadius.circular(shortestSide * 0.05),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 💡 Responsive Sizing
    final shortestSide = MediaQuery.of(context).size.shortestSide;
    final isPortrait =
        MediaQuery.of(context).orientation == Orientation.portrait;

    // Proportional dimensions
    final double responsivePadding = shortestSide * 0.06;
    final double avatarSize = shortestSide * 0.45; // Bigger avatar
    final double maxContentWidth = isPortrait ? 500 : 700;
    final double buttonHeight = shortestSide * 0.13;

    return Scaffold(
      backgroundColor: kLightBackground,

      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(responsivePadding),
          // Constrain width
          child: Container(
            constraints: BoxConstraints(maxWidth: maxContentWidth),

            // 💎 Glassmorphism Card
            child: _buildGlassCard(
              shortestSide: shortestSide,
              child: Padding(
                padding: EdgeInsets.all(responsivePadding),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 📝 Header Text
                    Text(
                      "Your Profile",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: shortestSide * 0.07,
                        fontWeight: FontWeight.w800,
                        color: kPrimaryText,
                      ),
                    ),
                    SizedBox(height: shortestSide * 0.01),
                    Text(
                      "Upload your avatar and join the community.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: shortestSide * 0.035,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: responsivePadding * 1.5),

                    // 🖼️ Profile Image Area - Soft UI
                    Center(
                      child: Stack(
                        children: [
                          // Image Preview with Soft Shadow
                          Container(
                            width: avatarSize,
                            height: avatarSize,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color:
                                  kLightBackground, // Match background for Soft UI feel
                              boxShadow: [
                                // Inner Shadow (Light)
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  offset: const Offset(0, 5),
                                  blurRadius: 15,
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child:
                                  (kIsWeb
                                      ? (webImage != null
                                            ? Image.memory(
                                                webImage!,
                                                fit: BoxFit.cover,
                                              )
                                            : null)
                                      : (fileImage != null
                                            ? Image.file(
                                                fileImage!,
                                                fit: BoxFit.cover,
                                              )
                                            : null)) ??
                                  Icon(
                                    Icons.person_add_alt_1_rounded,
                                    size: avatarSize * 0.4,
                                    color: Colors.grey[400],
                                  ),
                            ),
                          ),

                          // 📸 Edit/Choose Button - Accent Color
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: pickImage,
                              child: Container(
                                height: shortestSide * 0.1,
                                width: shortestSide * 0.1,
                                decoration: BoxDecoration(
                                  color: kAccentColor,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: kCardSurface,
                                    width: 3,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: kAccentColor.withOpacity(0.5),
                                      blurRadius: 10,
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.camera_alt_rounded,
                                  color: Colors.white,
                                  size: shortestSide * 0.05,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: responsivePadding * 1.5),

                    // 📤 Primary Upload Button (Dark Blue: #1ea5fe)
                    ElevatedButton(
                      onPressed: () async {
                        if (webImage == null && fileImage == null) {
                          toastification.show(
                            context: context,
                            title: const Text(
                              "Please select an image first.",
                              style: TextStyle(color: Colors.black),
                            ),
                            type: ToastificationType.error,
                            alignment: Alignment.topCenter,
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            showProgressBar: false,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            autoCloseDuration: const Duration(seconds: 3),
                          );

                          return;
                        }
                        String? url = await uploadToCloudinary();
                        if (url != null) {
                          await saveProfile(imageUrl: url);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimaryColor,
                        foregroundColor: Colors.white,
                        minimumSize: Size(double.infinity, buttonHeight),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            shortestSide * 0.025,
                          ),
                        ),
                        elevation: 8,
                        shadowColor: kPrimaryColor.withOpacity(0.4),
                      ),
                      child: loading
                          ? SizedBox(
                              width: shortestSide * 0.05,
                              height: shortestSide * 0.05,
                              child: const CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 3,
                              ),
                            )
                          : Text(
                              "Upload & Continue",
                              style: TextStyle(
                                fontSize: shortestSide * 0.045,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),

                    SizedBox(height: shortestSide * 0.02),

                    // ⏭️ Skip Button (Accent Color Text)
                    TextButton(
                      onPressed: () => saveProfile(skip: true),
                      child: Text(
                        "Skip for now",
                        style: TextStyle(
                          color: kAccentColor,
                          fontSize: shortestSide * 0.038,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
