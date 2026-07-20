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
  final VoidCallback? onAccept;
  final VoidCallback? onReject;
  final String? pv; // Added pv field
  

  const AppointmentCard({
    super.key,
    this.tutorName = '',
    required this.subject,
    required this.duration,
    required this.date,
    required this.time,
    required this.state,
    required this.scolor,
    this.onTap,
    this.onAccept,
    this.onReject,
    this.pv, // Initialize pv
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Container(
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                tutorName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xff334155),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 5,
                              ),
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
                ],
              ),
              if (onAccept != null || onReject != null) ...[
                const SizedBox(height: 14),
                Row(
                  children: [
                    if (onAccept != null)
                      Expanded(
                        child: SizedBox(
                          height: 38,
                          child: OutlinedButton.icon(
                            onPressed: onAccept,
                            icon: const Icon(Icons.check_circle_outline, size: 18),
                            label: const Text('Accepter'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.green,
                              side: const BorderSide(color: Colors.green),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                      ),
                    if (onAccept != null && onReject != null)
                      const SizedBox(width: 10),
                    if (onReject != null)
                      Expanded(
                        child: SizedBox(
                          height: 38,
                          child: OutlinedButton.icon(
                            onPressed: onReject,
                            icon: const Icon(Icons.cancel_outlined, size: 18),
                            label: const Text('Rejeter'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Colors.red),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}