import 'package:flutter/material.dart';




class SettingsList extends StatefulWidget {
  final bool isAvailableForCall;
  final Function(bool) onAvailabilityChanged;

  const SettingsList({
    super.key,
    required this.isAvailableForCall,
    required this.onAvailabilityChanged,
  });

  @override
  State<SettingsList> createState() => _SettingsListState();
}

class _SettingsListState extends State<SettingsList> {
  
  String _expandedTile = ''; 

  
  static const Map<String, String> _infoData = {
    "Privacy":
        "We prioritize your security. All calls are end-to-end encrypted, ensuring your conversations remain private. Your data is never sold or shared with third parties. We strictly follow GDPR and CCPA compliance to give you complete control over your information.",
    "Notifications":
        "Control how you are alerted. You can customize sounds, vibration patterns, and pop-up styles for incoming calls and new messages. Toggle the 'Do Not Disturb' mode for silent periods, or enable 'Heads-up' for quick previews.",
    "Help & Support":
        "Need assistance? Visit our dedicated knowledge base for guides and troubleshooting tips. For direct help, use the 'Contact Us' form. Our 24/7 support team is committed to resolving your queries within 4 hours.",
  };

  
  Widget _divider() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        child: Divider(height: 1, color: Colors.grey.shade200),
      );

  
  Widget _buildExpandableSubtitle(String title) {
    if (_expandedTile == title) {
      
      return Padding(
        padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
        child: Text(
          _infoData[title]!,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 14,
            height: 1.5, 
          ),
        ),
      );
    }
    return const SizedBox.shrink(); 
  }

  
  Widget _buildTile({
    required IconData icon,
    required String title,
    String? subtitle,
    VoidCallback? onTap, 
    Widget? trailingWidget,
  }) {
    
    
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
          trailing: trailingWidget ?? 
                    (isExpandable
                    ? Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          
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
                        : null)), 

          
          onTap: isExpandable
              ? () {
                  setState(() {
                    if (_expandedTile == title) {
                      _expandedTile = ''; 
                    } else {
                      _expandedTile = title; 
                    }
                  });
                }
              : onTap, 
        ),
        
        
        
        
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
                        icon: Icons.phone_callback_outlined,
                        title: "Incoming Calls",
                        subtitle: widget.isAvailableForCall 
                            ? "Accepting incoming calls" 
                            : "Ignoring incoming calls",
                        trailingWidget: Transform.scale(
                          scale: 0.8,
                          child: Switch(
                            value: widget.isAvailableForCall,
                            onChanged: widget.onAvailabilityChanged,
                            activeColor: Colors.white,
                            activeTrackColor: const Color(0XFF1ea5fe),
                            inactiveThumbColor: Colors.grey.shade300,
                            inactiveTrackColor: Colors.grey.shade400,
                          ),
                        ),
                      ),
                      _divider(),
                      

                      
                      _buildTile(
                        icon: Icons.lock_outline,
                        title: "Privacy",
                        
                      ),
                      _divider(),

                      
                      _buildTile(
                        icon: Icons.notifications_none,
                        title: "Notifications",
                        
                      ),
                      _divider(),

                      
                      _buildTile(
                        icon: Icons.help_outline,
                        title: "Help & Support",
                        
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 25),

                
                
                Padding(
                  padding: const EdgeInsets.only(left: 15, bottom: 10),
                  child: Text(
                    "ACCOUNT & GENERAL",
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                
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
                        icon: Icons.storage_outlined,
                        title: "Data and Storage",
                        subtitle: "Manage media download settings",
                        onTap: () {
                           
                        },
                      ),
                      _divider(),
                    
                      _buildTile(
                        icon: Icons.language_outlined,
                        title: "Language",
                        subtitle: "English (Default)",
                        onTap: () {
                          
                        },
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