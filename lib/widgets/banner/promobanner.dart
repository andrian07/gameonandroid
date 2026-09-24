import 'package:flutter/material.dart';

import '../header/top_up_modal.dart';

class PromoBanner extends StatelessWidget {
  const PromoBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => showTopUpModal(context),
          child: Container(
            height: 176,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xff3A1B6B), Color(0xff17102E)],
              ),
              border: Border.all(color: const Color(0xff9D4DFF).withOpacity(.35)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xff7B2EFF).withOpacity(.25),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -18,
                  bottom: -18,
                  child: Image.asset(
                    "assets/images/icons/png/ic_chest_reward.png",
                    width: 190,
                    fit: BoxFit.contain,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 16, 14, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xffFF4FD8), Color(0xff8B5CF6)],
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                "SPECIAL OFFER",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: .8,
                                ),
                              ),
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                "LEVEL UP",
                                style: TextStyle(
                                  color: const Color(0xff5CE1E6).withOpacity(.9),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: .5,
                                  height: 1,
                                ),
                              ),
                              Text(
                                "YOUR GAME",
                                style: TextStyle(
                                  color: const Color(0xff5CE1E6).withOpacity(.9),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: .5,
                                  height: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      RichText(
                        text: const TextSpan(
                          style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
                          children: [
                            TextSpan(text: "TOP UP ", style: TextStyle(color: Colors.white)),
                            TextSpan(text: "BONUS!", style: TextStyle(color: Color(0xffE84DFF))),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      SizedBox(
                        width: 190,
                        child: Text(
                          "Dapatkan bonus point setiap top up saldo",
                          style: TextStyle(
                            color: Colors.white.withOpacity(.75),
                            fontSize: 11.5,
                            height: 1.35,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xffE84DFF), Color(0xff46A8FF)],
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "TOP UP SEKARANG",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                letterSpacing: .3,
                              ),
                            ),
                            SizedBox(width: 6),
                            Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 13),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
