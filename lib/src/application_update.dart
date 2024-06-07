// Copyright 2020, the Flutter project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';
import 'package:flutter/material.dart';
import 'account_file.dart';
import 'package:url_launcher/url_launcher.dart';


class ApplicationUpdateHome extends StatefulWidget {
  final String application_url;

  const ApplicationUpdateHome({
    required this.application_url,
    super.key});

  @override
  State<ApplicationUpdateHome> createState() => _ApplicationUpdateHomeState();
}

class _ApplicationUpdateHomeState extends State<ApplicationUpdateHome> {
  late Future<AccountList> futurereadAccountList;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    futurereadAccountList = readAccountList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Mise à jour de l'application"),
      ),
      body: FutureBuilder<AccountList>(
            future: futurereadAccountList,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return Form(
                key: _formKey,
                child: Scrollbar(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: AutofillGroup(
                      child: Column(
                        children: [
                          ...[
                            const Text('Votre application est malheureusement obsolète et doit être mise à jour.'),
                            const Text('La mise à jour est très simple et prend quelques minutes seulement.'),
                            const Text('Cliquez sur le lien ci-dessous pour télécharger la dernière version.'),
                            const Text("Une fois le fichier téléchargé, double clicuez sur le fichier pour Installez la nouvelle version de l'application."),
                            const Text("N.B. aucune information ne sera perdue lors de cette opération."),
                            ElevatedButton(
                            child: const Text('Télécharger la dernière version'),
                              onPressed: () =>_launchUrl(widget.application_url))
            
                          ].expand(
                            (widget) => [
                              widget,
                              const SizedBox(
                                height: 24,
                              )
                            ],
                          ),

                





                        ],
                      ),
                    ),
                  ),
                ),
              );
              } else if (snapshot.hasError) {
                return Text('${snapshot.error}');
              }
              return const CircularProgressIndicator();
            }  
      ),
      
    );
  }

  void _showDialog(String message) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(message),
        actions: [
          TextButton(
            child: const Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

}

Future<String> _launchUrl(application_url) async {
  final Uri _url = Uri.parse(application_url);
  if (!await launchUrl(_url)) {
    throw Exception('Could not launch $_url');
  }
  return "";
}

