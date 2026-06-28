import 'package:flutter/material.dart';

class AppointmentCard extends StatelessWidget {
  final String tutorName;
  final String subject;
  final String duration;
  final String date;
  final String state;
  final String time;
  final Color scolor;
  final VoidCallback? onTap;

  const AppointmentCard({
    super.key,
    required this.tutorName,
    required this.subject,
    required this.duration,
    required this.date,
    required this.time,
    required this.state,
    required this.scolor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Container(
        height: 110,
        margin: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: const Color(0xffEAF3FF),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xffC7DFFF)),
          boxShadow: [
            BoxShadow(
              color: scolor,
              offset: const Offset(0, 8),
              blurRadius: 0,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.person,
                  color: Color(0xff123B60),
                  size: 28,
                ),
              ),

              const SizedBox(width: 16),

              // Middle content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      tutorName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xff334155),
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      "$subject : $duration",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xff334155),
                      ),
                    ),

                    const SizedBox(height: 6),

                    // SAFE: no overflow anymore
                    Wrap(
                      spacing: 10,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.calendar_today,
                                size: 16, color: Color(0xff64748B)),
                            const SizedBox(width: 6),
                            Text(
                              date,
                              style: const TextStyle(
                                fontSize: 10,
                                color: Color(0xff64748B),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.access_time,
                                size: 16, color: Color(0xff64748B)),
                            const SizedBox(width: 6),
                            Text(
                              time,
                              style: const TextStyle(
                                fontSize: 10,
                                color: Color(0xff64748B),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 10),

              // State badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: scolor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  state,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}