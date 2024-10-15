// Copyright 2020, the Flutter project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:json_annotation/json_annotation.dart';
import 'package:restart_app/restart_app.dart';
import 'nig_contest.dart';

import 'account_file.dart';
import 'account_getactive.dart';
import 'timer.dart';
import 'package:shared_preferences/shared_preferences.dart';


part 'contest.g.dart';



@JsonSerializable()
class FormData {
  String? name;
  String? receiver_public_key_hash;

  FormData({
    this.name,
    this.receiver_public_key_hash,
  });

  factory FormData.fromJson(Map<String, dynamic> json) =>
      _$FormDataFromJson(json);

  Map<String, dynamic> toJson() => _$FormDataToJson(this);
}

class Contest extends StatefulWidget {
  final http.Client? httpClient;
  final SharedPreferences prefs;

  const Contest({
    this.httpClient,
    required this.prefs,
    super.key,
  });

  @override
  State<Contest> createState() => _ContestState();
}

class _ContestState extends State<Contest> {
  FormData formData = FormData();

  @override
  void initState() {
    startTimer(widget.prefs);
    super.initState();
  }

   @override
  void dispose() async {
    super.dispose();
    await DisposeTimer(widget.prefs);  // Need to call dispose function.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inscription au concours'),
      ),
      body: Form(
        child: Scrollbar(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                ...[
                  TextFormField(
                    autofocus: true,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      filled: true,
                      hintText: 'Nom pour le concours',
                      labelText: 'Pseudo',
                    ),
                    onChanged: (value) {
                      formData.name = value;
                    },
                  ),
                  TextButton(
                    child: const Text('Inscription'),
                    onPressed: () async {
                      var check_timer=await CheckTimer(120000);
                      if (check_timer=="ok"){
                        var requested_name =formData.toJson()['name'];
                        print('====launchNigContest=====');
                        if (requested_name == null) {
                            _showDialog("Merci de renseigner un pseudo !");
                          } 
                        else {
                          var public_key_data = await ActiveAccount();
                          var requester_public_key_hash=public_key_data["public_key_hash"];
                          //var requester_public_key_hex=public_key_data["public_key_hex"];
                          try{
                            var result_step1 = await launchNigContest(requester_public_key_hash,requested_name);
                            print('====result =====');
                            print(result_step1.status);

                            if (result_step1.status == true) {
                              _showDialog("Inscription réussie");
                            } else {
                              if (result_step1.statusCode == "already subscribed") {
                                  _showDialog("Vous êtes déja inscrit !");

                              }
                              else if (result_step1.statusCode == 503 || result_step1.statusCode == 302) {
                                  //the server is in maintenance
                                  //let's restart the application
                                  Restart.restartApp();
                                }
                              else{
                                _showDialog(result_step1.statusCode);
                                _showDialog("L'inscription a échoué");
                              }

                            };
                          }
                          catch(e) {
                                _showDialog(e.toString());
                                _showDialog("L'inscription a échoué");
                          };
                        }
                      }
                      else{
                        _showDialog('Merci de patienter: $check_timer (sec)');
                      }
                    },
                  ),
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
