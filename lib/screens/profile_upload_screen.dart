import 'dart:convert';
import 'dart:typed_data';
import 'dart:io' as io;
import 'package:chatsphere/appToast/appToast.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_database/firebase_database.dart';
import 'package:chatsphere/screens/home_screen.dart';
import 'dart:ui';

const Color kLightBackground = Color(0xFFEFEFF4);
const Color kCardSurface = Color.fromARGB(255, 255, 255, 255);

const Color kPrimaryColor = Color(0xFF1ea5fe);
const Color kAccentColor = Color(0xFF16d7f8);
const Color kPrimaryText = Color(0xFF333333);

class ProfileUploadScreen extends StatefulWidget {
  final String uid;
  const ProfileUploadScreen({super.key, required this.uid});

  @override
  State<ProfileUploadScreen> createState() => _ProfileUploadScreenState();
}

class _ProfileUploadScreenState extends State<ProfileUploadScreen> {
  Uint8List? webImage;
  io.File? fileImage;
  bool loading = false;
  final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
  final picker = ImagePicker();
  final dbRef = FirebaseDatabase.instance.ref("users");

  final String cloudName = "dixilrnkq";
  final String uploadPreset = "chatsphere";

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
     AppToast.showError( "Upload failed: $e");

      return null;
    }
  }

  Future<void> saveProfile({String? imageUrl, bool skip = false}) async {
    try {
      setState(() => loading = true);

      final snap = await dbRef.child(widget.uid).get();
      final currentData = Map<String, dynamic>.from(snap.value as Map);

      final updatedImageUrl = (imageUrl != null && imageUrl.isNotEmpty)
          ? imageUrl
          : (currentData["imageUrl"] ?? "");

      await dbRef.child(widget.uid).update({
        "imageUrl": updatedImageUrl,
        "hasProfileImage": true,
      });
      ;

      AppToast.showSuccess(skip ? "Skipped profile upload" : "Profile updated");
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => HomeScreen(myId: uid)),
      );
    } catch (e) {
     AppToast.showError(e.toString());
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final shortestSide = size.shortestSide;
    final isPortrait = size.width < size.height;

    final double responsivePadding = shortestSide * 0.06;
    final double avatarSize = shortestSide * (isPortrait ? 0.35 : 0.28);
    final double maxContentWidth = isPortrait ? 380 : 550;
    final double buttonHeight = shortestSide * 0.11;

    return Scaffold(
      backgroundColor: kLightBackground,

      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: responsivePadding,
            vertical: isPortrait ? responsivePadding * 2 : shortestSide * 0.08,
          ),

          child: Container(
            constraints: BoxConstraints(maxWidth: maxContentWidth),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  "Upload Profile",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: shortestSide * 0.08,
                    fontWeight: FontWeight.w900,
                    color: kPrimaryText,
                  ),
                ),
                SizedBox(height: shortestSide * 0.01),
                Text(
                  "Choose a beautiful avatar and join the chat.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: shortestSide * 0.035,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: responsivePadding * 2),

                Center(
                  child: Stack(
                    children: [
                      Container(
                        width: avatarSize,
                        height: avatarSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: kCardSurface,
                          border: Border.all(
                            color: Colors.grey.withOpacity(0.2),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: kPrimaryColor.withOpacity(0.1),
                              offset: const Offset(0, 8),
                              blurRadius: 20,
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
                                Icons.person_outline_rounded,
                                size: avatarSize * 0.45,
                                color: Colors.grey[400],
                              ),
                        ),
                      ),

                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: pickImage,
                          child: Container(
                            height: shortestSide * 0.10,
                            width: shortestSide * 0.10,
                            decoration: BoxDecoration(
                              color: kAccentColor,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: kLightBackground,
                                width: 4,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: kAccentColor.withOpacity(0.5),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.edit_rounded,
                              color: Colors.white,
                              size: shortestSide * 0.045,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: responsivePadding * 2),

                ElevatedButton(
                  onPressed: () async {
                    if (webImage == null && fileImage == null) {
                      AppToast.showError("Please select an image first");

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
                      borderRadius: BorderRadius.circular(shortestSide * 0.02),
                    ),
                    elevation: 10,
                    shadowColor: kPrimaryColor.withOpacity(0.5),
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
                            fontSize: shortestSide * 0.042,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),

                SizedBox(height: shortestSide * 0.03),

                TextButton(
                  onPressed: () => saveProfile(skip: true),
                  child: Text(
                    "Skip for now",
                    style: TextStyle(
                      color: kPrimaryColor,
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
    );
  }
}
