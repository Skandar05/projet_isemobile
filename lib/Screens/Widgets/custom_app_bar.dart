import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({
    super.key,
    required this.title,
    required this.interfacePage,
    this.subtitle,
    this.showBackButton = false,
    this.showProfileButton = true,
    this.showTitle = true,
  });

  final String title;
  final Widget interfacePage;
  final String? subtitle;
  final bool showBackButton;
  final bool showProfileButton;
  final bool showTitle;

  @override
  Size get preferredSize {
    double height = showTitle ? 145 : 100;

    if (showTitle && subtitle != null && subtitle!.isNotEmpty) {
      height += 30;
    }

    return Size.fromHeight(height);
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);

    return Material(
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: 0.8),
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(10),
        bottomRight: Radius.circular(10),
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFEFF3FC),
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(10),
            bottomRight: Radius.circular(10),
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: media.size.width * 0.05,
            ).copyWith(
              top: 10,
              bottom: 20,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    if (showBackButton)
                      _buildIconButton(
                        icon: Icons.arrow_back_ios_new_rounded,
                        backgroundColor: Colors.white,
                        onTap: () => Navigator.pop(context),
                      ),

                    const Spacer(),

                    _buildIconButton(
                      icon: Icons.notifications_none_rounded,
                      backgroundColor: Colors.white,
                      onTap: () {},
                    ),

                    const SizedBox(width: 12),

                    if (showProfileButton)
                      InkWell(
                        borderRadius: BorderRadius.circular(35),
                        onTap: () {
                          // Action when profile image is pressed
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => interfacePage,
                            ),
                          );
                        },
                        child: const CircleAvatar(
                          radius: 28,
                          backgroundImage: AssetImage(
                            'lib/images/logoise.png',
                          ),
                        ),
                      ),
                  ],
                ),

                if (showTitle) ...[
                  const SizedBox(height: 24),

                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: media.textScaler.scale(24),
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF25324B),
                    ),
                  ),

                  if (subtitle != null && subtitle!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      subtitle!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: media.textScaler.scale(15),
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIconButton({
  required IconData icon,
  required VoidCallback onTap,
  required Color backgroundColor,
  Color iconColor = const Color(0xFF25324B),
}) {
  return Material(
    color: backgroundColor,
    borderRadius: BorderRadius.circular(18),
    elevation: 3,
    child: InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: SizedBox(
        width: 46,
        height: 46,
        child: Icon(
          icon,
          size: 22,
          color: iconColor,
        ),
      ),
    ),
  );
}
}