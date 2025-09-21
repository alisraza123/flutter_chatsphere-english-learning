import 'package:chatsphere/auth/login.dart';
import 'package:chatsphere/onboardingScreens/intro_component.dart';
import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class IntroductionScreen extends StatefulWidget {
 final VoidCallback? onFinish; // optional callback

  const IntroductionScreen({Key? key, this.onFinish}) : super(key: key);
  @override
  _IntroductionScreenState createState() => _IntroductionScreenState();
}

final PageController _pageController = PageController();
int _currentIndex = 0;

final List<Widget> _pages = [
  IntroComponent(
    title: "Welcome to Chat Sphere",
    description: "Connect, Speak, Enjoy. Learn English With Real Humans.",
    imagePath: "assets/img_1.png",
  ),
  IntroComponent(
    title: "Meet New People Instantly",
    description:
        "Start a random call and practice English with learners worldwide.",
    imagePath: "assets/img_2.png",
  ),
  IntroComponent(
    title: "Learn While You Chat",
    description:
        "Get real-time corrections, suggestions, and new words while talking.",
    imagePath: "assets/img_3.png",
  ),
  IntroComponent(
    title: "Join the Global Community",
    description: "Practice, share, and improve with learners around the world.",
    imagePath: "assets/img_4.png",
  ),
];

class _IntroductionScreenState extends State<IntroductionScreen> {
  void _skip() {
    _pageController.animateToPage(
      _pages.length - 1,
      duration: Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }
void _onFinish() {
  if (widget.onFinish != null) {
    widget.onFinish!();
  } else {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
    );
  }
}

  void _onNext() {
    if (_currentIndex < _pages.length - 1) {
      _pageController.nextPage(
        duration: Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                itemBuilder: (context, index) {
                  return Center(
                    child: SingleChildScrollView(child: _pages[index]),
                  );
                },
              ),
            ),
            // Bottom Row: Skip, Indicator, Next/Finish
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.04,
                vertical: screenHeight * 0.02,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Skip Button
                  _currentIndex == _pages.length - 1
                      ? SizedBox(width: screenWidth * 0.2)
                      : TextButton(
                          onPressed: _skip,
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                              horizontal: screenWidth * 0.05,
                              vertical: screenHeight * 0.015,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            "Skip",
                            style: TextStyle(
                              fontSize: screenHeight * 0.022,
                              color: Colors.red,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                  // Page Indicator
                  Expanded(
                    child: Center(
                      child: SmoothPageIndicator(
                        controller: _pageController,
                        count: _pages.length,
                        effect: WormEffect(
                          dotHeight: screenHeight * 0.015,
                          dotWidth: screenHeight * 0.015,
                          activeDotColor: Colors.blue,
                          dotColor: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                  // Next / Finish Button
                  TextButton(
                    onPressed: _currentIndex == _pages.length - 1
                        ? _onFinish
                        : _onNext,
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.05,
                        vertical: screenHeight * 0.015,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      _currentIndex == _pages.length - 1 ? "Finish" : "Next",
                      style: TextStyle(
                        fontSize: screenHeight * 0.022,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
