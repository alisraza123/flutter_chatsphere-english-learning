import 'package:flutter/material.dart';

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  // --- Local State for Pricing Selection ---
  bool _isAnnualSelected = true; // Default to Annual
  // ----------------------------------------

  final primaryColor = const Color(0XFF1ea5fe); // App's primary blue color
  final highlightGreen = Colors.green.shade400; // For "Save" badges

  @override
  Widget build(BuildContext context) {
    // Determine screen orientation for responsiveness
    final isPortrait = MediaQuery.of(context).orientation == Orientation.portrait;
    
    return Scaffold(
      backgroundColor: Colors.white, // Clean white background
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight( // Ensures content takes full height
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // --- Top Section: Close Button & Features ---
                      _buildTopSection(context, primaryColor),
        
                      // --- Pricing Options ---
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: isPortrait
                            ? Column(
                                children: [
                                 
                                  _buildPricingCard(
                                    context,
                                    isAnnual: false,
                                    isSelected: !_isAnnualSelected,
                                    title: "Monthly",
                                    currentPrice: "\$3.99",
                                    perDuration: "per month after 7 days trial",
                                    onTap: () {
                                      setState(() {
                                        _isAnnualSelected = false;
                                      });
                                    },
                                    primaryColor: primaryColor,
                                    highlightGreen: highlightGreen,
                                  ),
                                ],
                              )
                            : Row( // Landscape layout for pricing
                                children: [
                                  Expanded(
                                    child: _buildPricingCard(
                                      context,
                                      isAnnual: true,
                                      isSelected: _isAnnualSelected,
                                      title: "Annual",
                                      originalPrice: "\$59.99",
                                      currentPrice: "\$29.99",
                                      perDuration: "per year after 7 days trial",
                                      saveText: "Save 50%",
                                      onTap: () {
                                        setState(() {
                                          _isAnnualSelected = true;
                                        });
                                      },
                                      primaryColor: primaryColor,
                                      highlightGreen: highlightGreen,
                                    ),
                                  ),
                                  const SizedBox(width: 15),
                                  Expanded(
                                    child: _buildPricingCard(
                                      context,
                                      isAnnual: false,
                                      isSelected: !_isAnnualSelected,
                                      title: "Monthly",
                                      currentPrice: "\$3.99",
                                      perDuration: "per month after 7 days trial",
                                      onTap: () {
                                        setState(() {
                                          _isAnnualSelected = false;
                                        });
                                      },
                                      primaryColor: primaryColor,
                                      highlightGreen: highlightGreen,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                      const Spacer(), // Pushes content to top, and footer to bottom
                      const SizedBox(height: 30),
        
                      // --- Call to Action Button ---
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: ElevatedButton(
                          onPressed: () {
                            // TODO: Implement actual subscription logic based on _isAnnualSelected
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  _isAnnualSelected
                                      ? "Starting Annual Premium Trial!"
                                      : "Starting Monthly Premium Trial!",
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor, // Use primary blue for button
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            elevation: 5,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Text(
                                "Start Using Premium",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(width: 10),
                              Icon(Icons.flash_on, size: 24), // Lightning icon
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
        
                      // --- Footer Links (Terms, Privacy, Restore) ---
                      _buildFooterLinks(primaryColor),
                      const SizedBox(height: 20), // Padding at the very bottom
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // --- WIDGETS ---

  Widget _buildTopSection(BuildContext context, Color primaryColor) {
    return SafeArea(
      bottom: false, // Don't add padding at the bottom of the safe area
      child: Padding(
        padding: const EdgeInsets.only(left: 10.0, top: 10.0, right: 20.0, bottom: 30.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              alignment: Alignment.topLeft,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.black54, size: 28),
                onPressed: () => Navigator.of(context).pop(), // Close screen
              ),
            ),
            const SizedBox(height: 15),
            Padding(
              padding: const EdgeInsets.only(left: 10.0), // Indent for text
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Unlock all Features",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900, // Extra bold
                      color: Colors.grey.shade900,
                    ),
                  ),
                  const SizedBox(height: 25),
                  _buildFeatureItem("Extended Call Duration", primaryColor),
                  _buildFeatureItem("Extra Profile Features", primaryColor),
                  _buildFeatureItem("Change Country Feature", primaryColor),
                  _buildFeatureItem("Connect to Last Caller", primaryColor),
                  _buildFeatureItem("Ad-Free Experience", primaryColor),
                  _buildFeatureItem("Premium User Assistance", primaryColor),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(String text, Color primaryColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: primaryColor, size: 24),
          const SizedBox(width: 15),
          Text(
            text,
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade800,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPricingCard(
    BuildContext context, {
    required bool isAnnual,
    required bool isSelected,
    required String title,
    String? originalPrice,
    required String currentPrice,
    required String perDuration,
    String? saveText,
    required VoidCallback onTap,
    required Color primaryColor,
    required Color highlightGreen,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isSelected ? primaryColor : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? primaryColor : Colors.black87,
                  ),
                ),
                if (saveText != null && isAnnual)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: highlightGreen,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      saveText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                if (originalPrice != null && isAnnual)
                  Text(
                    originalPrice,
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey.shade500,
                      decoration: TextDecoration.lineThrough,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                if (originalPrice != null && isAnnual) const SizedBox(width: 8),
                Text(
                  currentPrice,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: isSelected ? primaryColor : Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              perDuration,
              style: TextStyle(
                fontSize: 13,
                color: isSelected ? primaryColor.withOpacity(0.8) : Colors.grey.shade600,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooterLinks(Color primaryColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildFooterTextButton("Terms of Use", () {
          // TODO: Navigate to Terms of Use
        }),
        Text(
          " • ",
          style: TextStyle(color: Colors.grey.shade500),
        ),
        _buildFooterTextButton("Privacy Policy", () {
          // TODO: Navigate to Privacy Policy
        }),
        Text(
          " • ",
          style: TextStyle(color: Colors.grey.shade500),
        ),
        _buildFooterTextButton("Restore", () {
          // TODO: Implement Restore Purchases logic
        }),
      ],
    );
  }

  Widget _buildFooterTextButton(String text, VoidCallback onPressed) {
    return TextButton(
      onPressed: onPressed,
      child: Text(
        text,
        style: TextStyle(
          color: Colors.grey.shade600,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}