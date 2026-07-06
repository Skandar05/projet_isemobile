import 'package:flutter/material.dart';

class ClasseCard extends StatelessWidget {
  final String NomClasse;
  final VoidCallback? onTap;

  const ClasseCard({
    super.key,
    required this.NomClasse,
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
              color: Color.fromARGB(192, 0, 102, 255),
              offset: const Offset(0, 8),
              blurRadius: 0,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      NomClasse,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xff334155),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}