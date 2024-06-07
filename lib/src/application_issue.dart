// Copyright 2020, the Flutter project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';
import 'package:flutter/material.dart';
import 'account_file.dart';
import 'package:restart_app/restart_app.dart';

class ApplicationIssueHome extends StatefulWidget {
  const ApplicationIssueHome({super.key});

  @override
  State<ApplicationIssueHome> createState() => _ApplicationIssueHomeState();
}

class _ApplicationIssueHomeState extends State<ApplicationIssueHome> {
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
        title: const Text("Problème avec l'application"),
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
                            const Text("L'appplication rencontre un problème technique."),
                            const Text("Merci de redémarrer l'application dans une heure."),
                            const Text('Désolé pour le désagréement.'),
                            ElevatedButton(
                              child: const Text("Redémarrer l'application"),
                              onPressed: () {
                                  Restart.restartApp();
                                },
                                                    
                              ),
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


