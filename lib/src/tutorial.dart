// Copyright 2020, the Flutter project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/gestures.dart';

class TutorialHome extends StatefulWidget {
  const TutorialHome({super.key});

  @override
  State<TutorialHome> createState() => _TutorialHomeState();
}

class _TutorialHomeState extends State<TutorialHome> {
  final _formKey = GlobalKey<FormState>();
  String? adjective;
  String? noun;
  bool? agreedToTerms = false;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("📖 Mode d'emploi de NIG"),
      ),
      body: Form(
        key: _formKey,
        child: Scrollbar(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                ...[

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                  Icon(
                    Icons.build,
                    color: Colors.red,
                    size: 30.0,
                  ),
                  Expanded(child: RichText(
                    text: TextSpan(
                      children: <TextSpan>[
                        const TextSpan(
                          text: "##_Les objectifs du ",
                          style: TextStyle(color: Colors.black87),
                        ),
                        TextSpan(
                          text: "beta testing du projet NIG",
                          style: const TextStyle(
                            color: Colors.blue,
                            decoration: TextDecoration.underline,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () => _launchUrl('https://docs.google.com/document/d/e/2PACX-1vTDYxgd6Wze1iCtoaFQQDik-OR8uN5SBRn3ZDmpWQCZjeUeS9j8SpjJttDBv_DrKQo50jct-uMnLz75/pub'),
                        ),
                      ],
                    ),
                  )),
                  ]),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                  Icon(
                    Icons.lightbulb_outline,
                    color: Colors.green,
                    size: 30.0,
                  ),
                  Expanded(child: RichText(
                    text: TextSpan(
                      children: <TextSpan>[
                        const TextSpan(
                          text: "00_Découvrir ",
                          style: TextStyle(color: Colors.black87),
                        ),
                        TextSpan(
                          text: "le projet NIG",
                          style: const TextStyle(
                            color: Colors.blue,
                            decoration: TextDecoration.underline,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () => _launchUrl('https://docs.google.com/document/d/e/2PACX-1vQxiyzQCp9qEkBbHT5wjt_YTXvRXycus77Z4M8pxd5Lp6JpI3ZjSq5bJMlRCUAx-3pRjr6kkByBG4HN/pub'),
                        ),
                      ],
                    ),
                  )),
                  ]),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                  Icon(
                    Icons.mobile_friendly,
                    color: Colors.green,
                    size: 30.0,
                  ),
                  Expanded(child: RichText(
                    text: TextSpan(
                      children: <TextSpan>[
                        const TextSpan(
                          text: "10_Installer et configurer ",
                          style: TextStyle(color: Colors.black87),
                        ),
                        TextSpan(
                          text: "l'application mobile",
                          style: const TextStyle(
                            color: Colors.blue,
                            decoration: TextDecoration.underline,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () => _launchUrl('https://docs.google.com/document/d/e/2PACX-1vTiTjJ-3cgXgEJ2h0CANcJLoOn-x6s0wUh_2wnXvkOPFclSSeVRW8-_Z0YfgRwF1CsGZLdAo-i4ehCp/pub'),
                        ),
                      ],
                    ),
                  )),
                  ]),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                  Icon(
                    Icons.add_shopping_cart,
                    color: Colors.green,
                    size: 30.0,
                  ),
                  Expanded(child: RichText(
                    text: TextSpan(
                      children: <TextSpan>[
                        const TextSpan(
                          text: "20_",
                          style: TextStyle(color: Colors.black87),
                        ),
                        TextSpan(
                          text: "Acheter",
                          style: const TextStyle(
                            color: Colors.blue,
                            decoration: TextDecoration.underline,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () => _launchUrl('https://docs.google.com/document/d/e/2PACX-1vTNNZOj2I4hT-AAVFxDJOCDqXtyv4m7Dq07H7J2NOPYMKqDJbn0PNPKvQG36N_H7hWqT9MYU8qeSMCz/pub'),
                        ),
                        const TextSpan(
                          text: " des NIG",
                          style: TextStyle(color: Colors.black87),
                        ),
                      ],
                    ),
                  )),
                  ]),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                  Icon(
                    Icons.account_balance_outlined,
                    color: Colors.green,
                    size: 30.0,
                  ),
                  Expanded(child: RichText(
                    text: TextSpan(
                      children: <TextSpan>[
                        const TextSpan(
                          text: "30_Consulter votre ",
                          style: TextStyle(color: Colors.black87),
                        ),
                        TextSpan(
                          text: "Balance",
                          style: const TextStyle(
                            color: Colors.blue,
                            decoration: TextDecoration.underline,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () => _launchUrl('https://docs.google.com/document/d/e/2PACX-1vQhRCq7PS28spqcImzRr5JZb8Nh9cSUa8SeM54BOiwxPSsS0pkxt2bUzTm8gaTODBFdVtRM4ZCugMq0/pub'),
                        ),
                      ],
                    ),
                  )),
                  ]),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                  Icon(
                    Icons.sell_outlined,
                    color: Colors.green,
                    size: 30.0,
                  ),
                  Expanded(child: RichText(
                    text: TextSpan(
                      children: <TextSpan>[
                        const TextSpan(
                          text: "40_",
                          style: TextStyle(color: Colors.black87),
                        ),
                        TextSpan(
                          text: "Vendre",
                          style: const TextStyle(
                            color: Colors.blue,
                            decoration: TextDecoration.underline,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () => _launchUrl('https://docs.google.com/document/d/e/2PACX-1vR1oOdIPj1NPvS8YhhoNOMsDCwP7lQZHqK6R59166Gn6EH4rT1_zPA1Mm7QaGqt2iOyBFfiJ8KSIac0/pub'),
                        ),
                        const TextSpan(
                          text: " des NIG",
                          style: TextStyle(color: Colors.black87),
                        ),
                      ],
                    ),
                  )),
                  ]),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                  Icon(
                    Icons.local_police_outlined,
                    color: Colors.green,
                    size: 30.0,
                  ),
                  Expanded(child: RichText(
                    text: TextSpan(
                      children: <TextSpan>[
                        const TextSpan(
                          text: "50_Participer au ",
                          style: TextStyle(color: Colors.black87),
                        ),
                        TextSpan(
                          text: "concours",
                          style: const TextStyle(
                            color: Colors.blue,
                            decoration: TextDecoration.underline,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () => _launchUrl('https://docs.google.com/document/d/e/2PACX-1vTlfXGyW5z-JsEiQHD-TLtbUhDH_t0XaatvxEwFpuJVi3Oz2amHNFonxrs00rPiIwWQjsYc3l5VIUT0/pub'),
                        ),
                        const TextSpan(
                          text: " afin de rendre votre expérience plus ludique",
                          style: TextStyle(color: Colors.black87),
                        ),
                      ],
                    ),
                  )),
                  ]),


                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                  Icon(
                    Icons.explore_outlined,
                    color: Colors.green,
                    size: 30.0,
                  ),
                  Expanded(child: RichText(
                    text: TextSpan(
                      children: <TextSpan>[
                        const TextSpan(
                          text: "60_Comprendre les mécanismes de ",
                          style: TextStyle(color: Colors.black87),
                        ),
                        TextSpan(
                          text: "régulation",
                          style: const TextStyle(
                            color: Colors.blue,
                            decoration: TextDecoration.underline,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () => _launchUrl('https://docs.google.com/document/d/e/2PACX-1vQ4AT3kz4EacAMMq7Mg4SZiBbgXR77M9iFx-WDmnnj7--h6Ht2CacOvYwuwinK9Y2-oI26HdPyk2MKX/pub'),
                        ),
                        const TextSpan(
                          text: " qui permettent d'assurer l'achat et la vente de NIG en toute confiance",
                          style: TextStyle(color: Colors.black87),
                        ),
                      ],
                    ),
                  )),
                  ]),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                  Icon(
                    Icons.engineering_outlined,
                    color: Colors.green,
                    size: 30.0,
                  ),
                  Expanded(child: RichText(
                    text: TextSpan(
                      children: <TextSpan>[
                        const TextSpan(
                          text: "70_Comprendre les aspects ",
                          style: TextStyle(color: Colors.black87),
                        ),
                        TextSpan(
                          text: "techniques",
                          style: const TextStyle(
                            color: Colors.blue,
                            decoration: TextDecoration.underline,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () => _launchUrl('https://docs.google.com/document/d/e/2PACX-1vTO0nKIogxFLGWkN0QpaMsGsg9Cp-Aqfv31sc6p_HQnb7tShmqymOM05o3_7YCFkBY7GIipWSNO756d/pub'),
                        ),
                        const TextSpan(
                          text: " qui permettent le bon fonctionnement du réseau NIG",
                          style: TextStyle(color: Colors.black87),
                        ),
                      ],
                    ),
                  )),
                  ]),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                  Icon(
                    Icons.question_answer_outlined,
                    color: Colors.green,
                    size: 30.0,
                  ),
                  Expanded(child: RichText(
                    text: TextSpan(
                      children: <TextSpan>[
                        const TextSpan(
                          text: "80_Foire aux ",
                          style: TextStyle(color: Colors.black87),
                        ),
                        TextSpan(
                          text: "questions",
                          style: const TextStyle(
                            color: Colors.blue,
                            decoration: TextDecoration.underline,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () => _launchUrl('https://docs.google.com/document/d/e/2PACX-1vQScRMPrz4TgB8YvshZiJBUEP3CCEmLT6u9RMwbpledLlaH3VLG-d7JMKgmOe8U8tZVgEq5W4dm41bq/pub'),
                        ),
                      ],
                    ),
                  )),
                  ]),









                  ].expand(
                  (widget) => [
                    widget,
                    const SizedBox(
                      height: 24,
                    )
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
  Future<void> _launchUrl(url) async {
  if (!await launchUrl(Uri.parse(url))) {
    throw Exception('Could not launch $url');
  }
}
}


