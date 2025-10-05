import 'package:chatsphere/onboardingScreens/introduction_screen.dart';
import 'package:chatsphere/proFeatures/pro_features_screen.dart';
import 'package:chatsphere/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:toastification/toastification.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'auth/login.dart';
import 'auth/signup.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    if (!e.toString().contains('already exists')) {
      rethrow;
    }
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // Check karenge ke user ne intro screen dekhi hai ya nahi
  Future<bool> checkIntroSeen() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool('intro_seen') ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return ToastificationWrapper(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'ChatSphere',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        ),
        routes: {
          '/homepage': (context) => HomeScreen(myId: uid),
          '/login': (context) => LoginScreen(),
          '/signup': (context) => SignUp(),
           '/pro': (context) => PremiumScreen(),
        },
        home: FutureBuilder<bool>(
          future: checkIntroSeen(),
          builder: (context, introSnapshot) {
            if (!introSnapshot.hasData) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            bool introSeen = introSnapshot.data!;

            // Agar intro screen pehli baar nahi dekhi to show karo
            if (!introSeen) {
              return IntroductionScreen(
                onFinish: () async {
                  // Intro screen complete hone ke baad flag set karo
                  SharedPreferences prefs =
                      await SharedPreferences.getInstance();
                  await prefs.setBool('intro_seen', true);

                  // Firebase auth check
                  final user = FirebaseAuth.instance.currentUser;
                  if (user != null) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => HomeScreen(myId: user.uid),
                      ),
                    );
                  } else {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => LoginScreen()),
                    );
                  }
                },
              );
            }

            // Agar intro already dekhi hai, directly auth check karo
            return StreamBuilder<User?>(
              stream: FirebaseAuth.instance.authStateChanges(),
              builder: (context, authSnapshot) {
                if (authSnapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }

                if (authSnapshot.hasData) {
                  return HomeScreen(myId: uid);
                } else {
                  return LoginScreen();
                }
              },
            );
          },
        ),
      ),
    );
  }
}
