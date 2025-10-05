import 'package:chatsphere/appToast/appToast.dart';
import 'package:chatsphere/auth/forgot_password.dart';
import 'package:chatsphere/screens/home_screen.dart';
import 'package:chatsphere/screens/profile_upload_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'signup.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool isVisible = false;
  final formKey = GlobalKey<FormState>();

  bool loading = false;
  final _auth = FirebaseAuth.instance;
  final dbRef = FirebaseDatabase.instance.ref("users");
  String uid = FirebaseAuth.instance.currentUser?.uid ?? '';
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final shortestSide = size.shortestSide;
    final screenWidth = size.width;

    return Scaffold(
      appBar: AppBar(automaticallyImplyLeading: false),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Lottie.asset("assets/login.json", width: 200, height: 200),
                  SizedBox(height: shortestSide * 0.05),

                  _buildTextField(
                    controller: emailController,
                    hint: "Email",
                    icon: Icons.person,
                    obscure: false,
                    validator: "Email is required",
                    shortestSide: shortestSide,
                  ),
                  SizedBox(height: shortestSide * 0.02),

                  _buildTextField(
                    controller: passwordController,
                    hint: "Password",
                    icon: Icons.lock,
                    obscure: !isVisible,
                    validator: "Password is required",
                    shortestSide: shortestSide,
                    toggleVisibility: () {
                      setState(() => isVisible = !isVisible);
                    },
                    isVisible: isVisible,
                  ),
                  SizedBox(height: shortestSide * 0.02),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ForgotPasswordScreen(),
                            ),
                          );
                        },
                        child: Text(
                          "Forgot Password?",
                          style: TextStyle(
                            fontSize: shortestSide * 0.04,
                            color: Color(0XFF16d7f8),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: shortestSide * 0.03),

                  SizedBox(
                    width: double.infinity,
                    height: shortestSide * 0.12,
                    child: ElevatedButton(
                      onPressed: () async {
                        try {
                          setState(() => loading = true);
                          UserCredential userCred = await _auth
                              .signInWithEmailAndPassword(
                                email: emailController.text.trim(),
                                password: passwordController.text.trim(),
                              );
                          String uid = userCred.user!.uid;

                          
                          FirebaseDatabase.instance.ref("users/$uid").update({
                            "status": "online",
                            "callStatus": "idle",
                            "incomingCallId": null,
                          });

                          
                          FirebaseDatabase.instance
                              .ref(
                                "users/$uid",
                              ) 
                              .onDisconnect()
                              .update({
                                "status": "offline",
                                "callStatus": "idle",
                                "incomingCallId": null,
                              });

                          DatabaseEvent snap = await dbRef.child(uid).once();

                          Map data = snap.snapshot.value as Map;

                          if (data["hasProfileImage"] == false) {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ProfileUploadScreen(uid: uid),
                              ),
                            );
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => HomeScreen(myId: uid),
                              ),
                            );
                          }

                         AppToast.showSuccess("Login Successful");

                          setState(() => loading = false);
                        } on FirebaseAuthException catch (e) {
                          setState(() => loading = false);
                         AppToast.showError( e.message.toString());
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0XFF1ea5fe),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            shortestSide * 0.02,
                          ),
                        ),
                      ),
                      child: loading
                          ? CircularProgressIndicator(color: Colors.white)
                          : Text(
                              "LOGIN",
                              style: TextStyle(
                                fontSize: shortestSide * 0.045,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),

                  SizedBox(height: shortestSide * 0.025),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Don't have an account? "),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const SignUp()),
                          );
                        },
                        child: const Text(
                          "SIGN UP",
                          style: TextStyle(color: Color(0Xff16d7f8)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required bool obscure,
    required String validator,
    required double shortestSide,
    VoidCallback? toggleVisibility,
    bool? isVisible,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: shortestSide * 0.03,
        vertical: shortestSide * 0.01,
      ),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.2),
        borderRadius: BorderRadius.circular(shortestSide * 0.02),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        validator: (value) {
          if (value!.isEmpty) return validator;
          return null;
        },
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          prefixIcon: Icon(icon, size: shortestSide * 0.06),
          suffixIcon: toggleVisibility != null
              ? IconButton(
                  onPressed: toggleVisibility,
                  icon: Icon(
                    isVisible! ? Icons.visibility : Icons.visibility_off,
                    size: shortestSide * 0.06,
                  ),
                )
              : null,
        ),
      ),
    );
  }
}
