import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'login.dart';
import 'package:toastification/toastification.dart';

class SignUp extends StatefulWidget {
  const SignUp({super.key});

  @override
  State<SignUp> createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final nameController = TextEditingController();
  bool isVisible = false;
  final formKey = GlobalKey<FormState>();

  final auth = FirebaseAuth.instance;
  final dbRef = FirebaseDatabase.instance.ref("users");
  bool loading = false;

  String? gender;
  String? selectedCountry;

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
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    nameController.dispose();
    super.dispose();
  }

  Widget _buildSimpleTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required bool obscure,
    required String validator,
    required double shortestSide,
    VoidCallback? toggleVisibility,
    bool? isVisible,
    TextInputType keyboardType = TextInputType.text,
  }) {
    final double fieldRadius = shortestSide * 0.03;

    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: TextStyle(fontSize: shortestSide * 0.04),
      validator: (value) {
        if (value == null || value.isEmpty) return validator;
        return null;
      },
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.grey.shade100,
        hintText: hint,

        hintStyle: TextStyle(
          color: Colors.black,
          fontSize: shortestSide * 0.04,
        ),

        prefixIcon: Icon(icon, color: Colors.black, size: shortestSide * 0.06),
        contentPadding: EdgeInsets.symmetric(vertical: shortestSide * 0.04),

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(fieldRadius),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(fieldRadius),
          borderSide: BorderSide(color: Colors.grey.shade300, width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(fieldRadius),
          borderSide: const BorderSide(color: Color(0XFF1ea5fe), width: 2.0),
        ),
        suffixIcon: toggleVisibility != null
            ? IconButton(
                onPressed: toggleVisibility,
                icon: Icon(
                  isVisible! ? Icons.visibility : Icons.visibility_off,

                  color: Colors.black,
                  size: shortestSide * 0.06,
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildGenderChip(String value, String label, double shortestSide) {
    bool isSelected = gender == value;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: GestureDetector(
          onTap: () => setState(() => gender = value),
          child: Container(
            height: shortestSide * 0.1,
            decoration: BoxDecoration(
              color: isSelected ? const Color(0XFF1ea5fe) : Colors.white,
              borderRadius: BorderRadius.circular(shortestSide * 0.025),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: const Color(0XFF1ea5fe).withOpacity(0.3),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.grey.shade200,
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      ),
                    ],
              border: Border.all(
                color: isSelected
                    ? const Color(0XFF1ea5fe)
                    : Colors.grey.shade300,
                width: 1.5,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: TextStyle(
                fontSize: shortestSide * 0.04,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : Colors.black87,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCountryDropdownModern(double shortestSide) {
    final double fieldRadius = shortestSide * 0.03;
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(fieldRadius),
        border: Border.all(color: Colors.grey.shade300, width: 1.0),
      ),
      child: DropdownButtonFormField<String>(
        value: selectedCountry,
        hint: Text(
          "Select Country",
          style: TextStyle(color: Colors.black, fontSize: shortestSide * 0.04),
        ),
        isExpanded: true,
        style: TextStyle(fontSize: shortestSide * 0.04, color: Colors.black),
        icon: const Icon(
          Icons.keyboard_arrow_down_rounded,
          color: Colors.black,
        ),
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.public_outlined, color: Colors.black),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: shortestSide * 0.03,
            vertical: shortestSide * 0.04,
          ),
        ),
        items: countries.map((country) {
          return DropdownMenuItem(value: country, child: Text(country));
        }).toList(),
        onChanged: (value) {
          setState(() {
            selectedCountry = value;
          });
        },
        validator: (value) =>
            value == null ? "Please select your country" : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final shortestSide = size.shortestSide;
    final screenWidth = size.width;
    final double verticalSpacing = shortestSide * 0.03;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.08,
            vertical: shortestSide * 0.05,
          ),
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Image.asset(
                  "assets/signup.png",
                  width: shortestSide * 0.35,
                  height: shortestSide * 0.35,
                ),
                SizedBox(height: verticalSpacing * 0.5),

                Text(
                  "Get Started",
                  style: TextStyle(
                    fontSize: shortestSide * 0.08,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: verticalSpacing * 0.5),
                Text(
                  "Create your new account in seconds.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: shortestSide * 0.04,
                    color: Colors.grey.shade600,
                  ),
                ),
                SizedBox(height: verticalSpacing * 1.5),

                // 📝 Form Fields
                _buildSimpleTextField(
                  controller: nameController,
                  hint: "Full Name",
                  icon: Icons.person_outline,
                  obscure: false,
                  validator: "Name is required",
                  shortestSide: shortestSide,
                ),
                SizedBox(height: verticalSpacing),

                _buildSimpleTextField(
                  controller: emailController,
                  hint: "Email Address",
                  icon: Icons.email_outlined,
                  obscure: false,
                  validator: "Email is required",
                  shortestSide: shortestSide,
                  keyboardType: TextInputType.emailAddress,
                ),
                SizedBox(height: verticalSpacing),

                _buildSimpleTextField(
                  controller: passwordController,
                  hint: "Password",
                  icon: Icons.lock_outline,
                  obscure: !isVisible,
                  validator: "Password is required",
                  shortestSide: shortestSide,
                  toggleVisibility: () {
                    setState(() => isVisible = !isVisible);
                  },
                  isVisible: isVisible,
                ),
                SizedBox(height: verticalSpacing),

                _buildSimpleTextField(
                  controller: confirmPasswordController,
                  hint: "Confirm Password",
                  icon: Icons.lock_reset,
                  obscure: !isVisible,
                  validator: "Confirm password is required",
                  shortestSide: shortestSide,
                  toggleVisibility: () {
                    setState(() => isVisible = !isVisible);
                  },
                  isVisible: isVisible,
                ),
                SizedBox(height: verticalSpacing),

                Row(
                  children: [
                    _buildGenderChip("Male", "Male", shortestSide),
                    SizedBox(width: verticalSpacing * 0.5),
                    _buildGenderChip("Female", "Female", shortestSide),
                  ],
                ),
                SizedBox(height: verticalSpacing),

                _buildCountryDropdownModern(shortestSide),
                SizedBox(height: verticalSpacing * 1.5),

                SizedBox(
                  width: double.infinity,
                  height: shortestSide * 0.12,
                  child: ElevatedButton(
                    onPressed: () async {
                      // Original logic preserved
                      if (formKey.currentState!.validate()) {
                        if (passwordController.text.trim() !=
                            confirmPasswordController.text.trim()) {
                          toastification.show(
                            context: context,
                            title: const Text("Passwords do not match"),
                            type: ToastificationType.error,
                            alignment: Alignment.topCenter,
                          );
                          return;
                        }
                        if (gender == null) {
                          toastification.show(
                            context: context,
                            title: const Text("Please select gender"),
                            type: ToastificationType.error,
                            alignment: Alignment.topCenter,
                          );
                          return;
                        }

                        try {
                          setState(() => loading = true);
                          UserCredential userCred = await auth
                              .createUserWithEmailAndPassword(
                                email: emailController.text.trim(),
                                password: passwordController.text.trim(),
                              );

                          // Save in Realtime Database
                          await dbRef.child(userCred.user!.uid).set({
                            "name": nameController.text.trim().toUpperCase(),
                            "email": emailController.text.trim(),
                            "gender": gender,
                            "country": selectedCountry ?? "",
                            "imageUrl": "",
                            "hasProfileImage": false,
                            "status": "offline",
                            "callStatus": "idle",
                            "talks": 0,
                            "level": 1,
                            "isAvailableForCall": true,
                            "incomingCallId": null,
                          });

                          setState(() => loading = false);

                          toastification.show(
                            context: context,
                            title: const Text(
                              'SignUp Successful',
                              style: TextStyle(color: Colors.white),
                            ),
                            type: ToastificationType.success,
                            alignment: Alignment.topCenter,
                            showProgressBar: true,
                            primaryColor: Colors.green,
                            backgroundColor: Colors.green[700],
                            style: ToastificationStyle.flatColored,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            autoCloseDuration: const Duration(seconds: 3),
                          );

                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const LoginScreen(),
                            ),
                          );
                        } on FirebaseAuthException catch (e) {
                          setState(() => loading = false);
                          toastification.show(
                            context: context,
                            title: Text(
                              e.message.toString(),
                              style: const TextStyle(color: Colors.white),
                            ),
                            style: ToastificationStyle.flatColored,
                            type: ToastificationType.error,
                            alignment: Alignment.topCenter,
                            showProgressBar: false,
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            autoCloseDuration: const Duration(seconds: 3),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0XFF1ea5fe),
                      elevation: 5,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          shortestSide * 0.03,
                        ),
                      ),
                    ),
                    child: loading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            "SIGN UP",
                            style: TextStyle(
                              fontSize: shortestSide * 0.05,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                            ),
                          ),
                  ),
                ),

                SizedBox(height: verticalSpacing),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Already have an account? ",
                      style: TextStyle(
                        fontSize: shortestSide * 0.038,
                        color: Colors.black87,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LoginScreen(),
                          ),
                        );
                      },
                      child: Text(
                        "Login",
                        style: TextStyle(
                          color: const Color(0XFF1ea5fe),
                          fontWeight: FontWeight.bold,
                          fontSize: shortestSide * 0.04,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: verticalSpacing),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
