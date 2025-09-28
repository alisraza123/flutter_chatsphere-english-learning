import 'package:flutter/material.dart';

// Convert StatelessWidget to StatefulWidget to manage the expansion state of tiles
class SettingsList extends StatefulWidget {
  const SettingsList({super.key});

  @override
  State<SettingsList> createState() => _SettingsListState();
}

class _SettingsListState extends State<SettingsList> {
  // State variables to manage which tile is currently expanded
  String _expandedTile = ''; // Stores the title of the currently open tile

  // Dummy beautiful information for each section
  static const Map<String, String> _infoData = {
    "Privacy":
        "We prioritize your security. All calls are end-to-end encrypted, ensuring your conversations remain private. Your data is never sold or shared with third parties. We strictly follow GDPR and CCPA compliance to give you complete control over your information.",
    "Notifications":
        "Control how you are alerted. You can customize sounds, vibration patterns, and pop-up styles for incoming calls and new messages. Toggle the 'Do Not Disturb' mode for silent periods, or enable 'Heads-up' for quick previews.",
    "Help & Support":
        "Need assistance? Visit our dedicated knowledge base for guides and troubleshooting tips. For direct help, use the 'Contact Us' form. Our 24/7 support team is committed to resolving your queries within 4 hours.",
  };

  // --- Helper Widget: Divider ---
  Widget _divider() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        child: Divider(height: 1, color: Colors.grey.shade200),
      );

  // --- Helper Widget: Expandable Subtitle ---
  Widget _buildExpandableSubtitle(String title) {
    if (_expandedTile == title) {
      // Show the beautiful info if this tile is the expanded one
      return Padding(
        padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
        child: Text(
          _infoData[title]!,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 14,
            height: 1.5, // Better readability
          ),
        ),
      );
    }
    return const SizedBox.shrink(); // Hide the subtitle if not expanded
  }

  // --- Helper Widget: Main Tile Structure ---
  Widget _buildTile({
    required IconData icon,
    required String title,
    String? subtitle,
    VoidCallback? onTap, // onTap is now optional, used for non-expandable tiles
  }) {
    // If subtitle is not provided, this is a fixed tile (like App Version).
    // If subtitle is provided, this is an expandable tile.
    final isExpandable = _infoData.containsKey(title);

    return Column(
      children: [
        ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
          leading: Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: const Color(0xFF1ea5fe).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: const Color(0xFF1ea5fe), size: 22),
          ),
          title: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: Colors.grey.shade800,
            ),
          ),
          subtitle: subtitle != null
              ? Text(
                  subtitle,
                  style:
                      TextStyle(color: Colors.grey.shade600, fontSize: 14),
                )
              : null,
          trailing: isExpandable
              ? Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    // Change icon based on expansion state
                    _expandedTile == title
                        ? Icons.keyboard_arrow_down
                        : Icons.arrow_forward_ios,
                    size: 14,
                    color: Colors.grey.shade600,
                  ),
                )
              : (onTap != null
                  ? Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.arrow_forward_ios,
                        size: 14,
                        color: Colors.grey.shade600,
                      ),
                    )
                  : null), // Handle App Version/Developers tile which has a subtitle but no onTap

          // Toggle expansion on tap
          onTap: isExpandable
              ? () {
                  setState(() {
                    if (_expandedTile == title) {
                      _expandedTile = ''; // Collapse if already open
                    } else {
                      _expandedTile = title; // Expand the clicked tile
                    }
                  });
                }
              : onTap, // Use provided onTap for non-expandable tiles
        ),
        
        // **********************************
        // Insert the expandable subtitle area
        // **********************************
        if (isExpandable)
          Padding(
            padding: const EdgeInsets.only(left: 15, right: 15, bottom: 15),
            child: _buildExpandableSubtitle(title),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey.shade50,
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // ----------------------------------------------------
                // FIRST SECTION (Expandable Tiles)
                // ----------------------------------------------------
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // 1. Privacy Tile (Now Expandable)
                      _buildTile(
                        icon: Icons.lock_outline,
                        title: "Privacy",
                        // onTap is handled internally for expansion
                      ),
                      _divider(),

                      // 2. Notifications Tile (Now Expandable)
                      _buildTile(
                        icon: Icons.notifications_none,
                        title: "Notifications",
                        // onTap is handled internally for expansion
                      ),
                      _divider(),

                      // 3. Help & Support Tile (Now Expandable)
                      _buildTile(
                        icon: Icons.help_outline,
                        title: "Help & Support",
                        // onTap is handled internally for expansion
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 25),

                // ----------------------------------------------------
                // ABOUT HEADER
                // ----------------------------------------------------
                Padding(
                  padding: const EdgeInsets.only(left: 15, bottom: 10),
                  child: Text(
                    "ABOUT",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),

                // ----------------------------------------------------
                // SECOND SECTION (Fixed Tiles)
                // ----------------------------------------------------
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildTile(
                        icon: Icons.info_outline,
                        title: "App Version",
                        subtitle: "v1.0.0",
                      ),
                      _divider(),
                      _buildTile(
                        icon: Icons.people_outline,
                        title: "Developers",
                        subtitle: "Hassan Raza, Team XYZ",
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ],
      ),
    );
  }
}