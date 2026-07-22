import 'package:flutter/material.dart';


class TrimestreCard extends StatefulWidget {
  final String title;
  final VoidCallback onTap;

  const TrimestreCard({
    super.key,
    required this.title,
    required this.onTap,
  });

  @override
  State<TrimestreCard> createState() => _TrimestreCardState();
}

class _TrimestreCardState extends State<TrimestreCard> {
  // We use this state to animate the 3D press down effect
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        // Push the button down when pressed by adjusting the margins
        margin: EdgeInsets.only(
          top: _isPressed ? 8.0 : 0.0,
          bottom: _isPressed ? 0.0 : 8.0,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          // Subtle top-to-bottom gradient on the button face
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF8FBFF), // Lightest at top
              Color(0xFFE4F0FF), // Slightly darker blue at bottom
            ],
          ),
          border: Border.all(
            color: Colors.white,
            width: 2.5, // Thick white border
          ),
          boxShadow: [
            // Solid 3D lip at the bottom (Offset Y is 8 when not pressed, 0 when pressed)
            BoxShadow(
              color: const Color(0xFF68AEE7), 
              offset: Offset(0, _isPressed ? 0 : 8),
              blurRadius: 0,
            ),
            // Soft glowing shadow underneath for depth
            BoxShadow(
              color: const Color(0xFF68AEE7).withOpacity(0.3),
              offset: const Offset(0, 15),
              blurRadius: 20,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Row(
            children: [
              // White Icon Container
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      offset: const Offset(0, 4),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.calculate, // The calculator icon matches the +-x= graphic perfectly
                    color: Color(0xFF16325B), // Dark navy blue icon
                    size: 32,
                  ),
                ),
              ),
              const SizedBox(width: 24),
              // Title Text
              Expanded(
                child: Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF2C4059), // Dark text color
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              // Right Chevron Arrow
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: Color(0xFF0075D8), // Vibrant blue arrow
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}