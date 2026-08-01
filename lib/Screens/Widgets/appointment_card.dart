import 'package:flutter/material.dart';

class AppointmentCard extends StatelessWidget {
  final String tutorName;
  final String subject;
  final String duration;
  final String date;
  final String state;
  final String time;
  final Color scolor;
  final Color? roleColor;
  final String? fromName;
  final String? toName;
  final String? demandeurRole;
  final bool showPdIcon;
  final VoidCallback? onTap;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;
  final String? pv;

  const AppointmentCard({
    super.key,
    this.tutorName = '',
    required this.subject,
    required this.duration,
    required this.date,
    required this.time,
    required this.state,
    required this.scolor,
    this.roleColor,
    this.fromName,
    this.toName,
    this.demandeurRole,
    this.showPdIcon = false,
    this.onTap,
    this.onAccept,
    this.onReject,
    this.pv,
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
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 14,
          ),
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
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Builder(builder: (context) {
                        final role = (demandeurRole ?? '').toString().toLowerCase();
                        final isPedagogique = showPdIcon ||
                            role.contains('pedagogique') ||
                            role.contains('pd') ||
                            (fromName ?? '').toLowerCase().contains('pedagogique') ||
                            (toName ?? '').toLowerCase().contains('pedagogique');

                        String asset = 'lib/images/pdicon.png';
                        if (!isPedagogique) {
                          if (role.contains('enseignant') || role.contains('teacher')) {
                            asset = 'lib/images/enseignanticon.png';
                          } else if (role.contains('parent')) {
                            asset = 'lib/images/parenticon.png';
                          }
                        }

                        return Image.asset(
                          asset,
                          width: 52,
                          height: 52,
                          fit: BoxFit.cover,
                        );
                      }),
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Informations
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if ((fromName?.isNotEmpty ?? false) ||
                            (toName?.isNotEmpty ?? false)) ...[
                          if (fromName?.isNotEmpty ?? false)
                            Text(
                              "From : ${fromName!}",
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xff334155),
                              ),
                            ),
                          if (toName?.isNotEmpty ?? false) ...[
                            const SizedBox(height: 4),
                            Text(
                              "To : ${toName!}",
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xff334155),
                              ),
                            ),
                          ],
                        ] else ...[
                          Text(
                            subject,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xff123B60),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            duration,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xff64748B),
                            ),
                          ),
                        ],

                        if (pv != null && pv!.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            pv!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xff475569),
                            ),
                          ),
                        ],

                        const SizedBox(height: 10),

                        Wrap(
                          spacing: 12,
                          runSpacing: 8,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.calendar_today,
                                  size: 15,
                                  color: Color(0xff64748B),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  date,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xff64748B),
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.access_time,
                                  size: 15,
                                  color: Color(0xff64748B),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  time,
                                  style: const TextStyle(
                                    fontSize: 11,
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

                  // Badge état
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
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

              if (onAccept != null || onReject != null) ...[
                const SizedBox(height: 18),
                Row(
                  children: [
                    if (onAccept != null)
                      Expanded(
                        child: SizedBox(
                          height: 40,
                          child: OutlinedButton.icon(
                            onPressed: onAccept,
                            icon: const Icon(
                              Icons.check_circle_outline,
                              size: 18,
                            ),
                            label: const Text("Accepter"),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.green,
                              side: const BorderSide(
                                color: Colors.green,
                              ),
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
                          height: 40,
                          child: OutlinedButton.icon(
                            onPressed: onReject,
                            icon: const Icon(
                              Icons.cancel_outlined,
                              size: 18,
                            ),
                            label: const Text("Rejeter"),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(
                                color: Colors.red,
                              ),
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