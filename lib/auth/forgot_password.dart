import 'package:flutter/material.dart';
import 'login.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final emailController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final shortestSide = size.shortestSide;
    final screenWidth = size.width;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.lock_open,
                    color: Colors.deepPurple,
                    size: shortestSide * 0.2,
                  ),
                  SizedBox(height: shortestSide * 0.03),
                  Text(
                    "Forgot Password",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: shortestSide * 0.07,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
                  SizedBox(height: shortestSide * 0.02),
                  Text(
                    "Enter your email address below to receive password reset instructions.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: shortestSide * 0.035, color: Colors.black54),
                  ),
                  SizedBox(height: shortestSide * 0.03),
                  
                  _buildTextField(
                    controller: emailController,
                    hint: "Email Address",
                    icon: Icons.email,
                    obscure: false,
                    validator: "Email is required",
                    shortestSide: shortestSide,
                  ),
                  SizedBox(height: shortestSide * 0.04),
                  
                  SizedBox(
                    width: double.infinity,
                    height: shortestSide * 0.12,
                    child: ElevatedButton(
                      onPressed: () {
                        if (formKey.currentState!.validate()) {
                          
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    "Password reset link has been sent!")),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(shortestSide * 0.02),
                        ),
                      ),
                      child: Text(
                        "SEND RESET LINK",
                        style: TextStyle(
                            fontSize: shortestSide * 0.045,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                    ),
                  ),
                  SizedBox(height: shortestSide * 0.03),
                  
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const LoginScreen()));
                    },
                    child: Text(
                      "Back to Login",
                      style: TextStyle(
                          fontSize: shortestSide * 0.04,
                          color: Colors.deepPurple,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
      {required TextEditingController controller,
      required String hint,
      required IconData icon,
      required bool obscure,
      required String validator,
      required double shortestSide}) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: shortestSide * 0.03, vertical: shortestSide * 0.02),
      decoration: BoxDecoration(
          color: Colors.deepPurple.withOpacity(0.2),
          borderRadius: BorderRadius.circular(shortestSide * 0.02)),
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
          icon: Icon(icon, size: shortestSide * 0.06),
        ),
      ),
    );
  }
}
