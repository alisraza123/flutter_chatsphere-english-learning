import 'package:flutter/material.dart';

class SettingsList extends StatelessWidget {
  const SettingsList({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey.shade50,
      child: Column(
        children: [
          // Header
         

          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Settings Card
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildTile(
                        icon: Icons.lock_outline,
                        title: "Privacy",
                        onTap: () {},
                      ),
                      _divider(),
                      _buildTile(
                        icon: Icons.notifications_none,
                        title: "Notifications",
                        onTap: () {},
                      ),
                      _divider(),
                      _buildTile(
                        icon: Icons.help_outline,
                        title: "Help & Support",
                        onTap: () {},
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 25),

                // Section Header
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

                // About Card
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: Offset(0, 4),
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

                SizedBox(height: 30),

                // Logout Button
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() => Padding(
    padding: EdgeInsets.symmetric(horizontal: 15),
    child: Divider(height: 1, color: Colors.grey.shade200),
  );

  Widget _buildTile({
    required IconData icon,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      leading: Container(
        width: 45,
        height: 45,
        decoration: BoxDecoration(
          color: Color(0xFF1ea5fe).withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Color(0xFF1ea5fe), size: 22),
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
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            )
          : null,
      trailing: onTap != null
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
          : null,
      onTap: onTap,
    );
  }
}
