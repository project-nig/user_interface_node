// Copyright 2020, the Flutter project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';
import 'package:flutter/material.dart';
import 'account_file.dart';

class ConnectivityHome extends StatefulWidget {
  const ConnectivityHome({super.key});

  @override
  State<ConnectivityHome> createState() => _ConnectivityHomeState();
}

class _ConnectivityHomeState extends State<ConnectivityHome> {
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
        title: const Text("Problème de connexion internet"),
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
                            const Text("L'application n'a pas accès à internet"),
                            const Text("Merci de vérifier la connexion de l'appareil à internet"),
                            ElevatedButton(
                              onPressed: () {
                                  Navigator.pop(context);
                                },
                                child: const Text('Retour'),                    
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


