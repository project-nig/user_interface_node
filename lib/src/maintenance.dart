// Copyright 2020, the Flutter project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';
import 'package:flutter/material.dart';
import 'account_file.dart';
import 'package:restart_app/restart_app.dart';

class MaintenanceHome extends StatefulWidget {
  const MaintenanceHome({super.key});

  @override
  State<MaintenanceHome> createState() => _MaintenanceHomeState();
}

class _MaintenanceHomeState extends State<MaintenanceHome> {
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
        title: const Text("Maintenance du réseau NIG"),
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
                            const Text('Le réseau NIG est actuellement en cours de maintenance.'),
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


