// Copyright 2020, the Flutter project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:json_annotation/json_annotation.dart';
import 'nig_engine.dart';
import 'timer.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'transfer.g.dart';



@JsonSerializable()
class FormData {
  String? amount;
  String? receiver_public_key_hash;

  FormData({
    this.amount,
    this.receiver_public_key_hash,
  });

  factory FormData.fromJson(Map<String, dynamic> json) =>
      _$FormDataFromJson(json);

  Map<String, dynamic> toJson() => _$FormDataToJson(this);
}

class TransferHome extends StatefulWidget {
  final SharedPreferences prefs;
  final http.Client? httpClient;

  const TransferHome({
    this.httpClient,
    required this.prefs,
    super.key,
  });

  @override
  State<TransferHome> createState() => _TransferHomeState();
}

class _TransferHomeState extends State<TransferHome> {
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
        title: const Text('Transfert de NIG'),
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
                      hintText: 'Montant en NIG à transférer',
                      labelText: 'Montant',
                    ),
                    onChanged: (value) {
                      formData.amount = value;
                    },
                  ),
                  TextFormField(
                    autofocus: true,
                    decoration: const InputDecoration(
                      filled: true,
                      hintText: 'Adresse du destinataire',
                      labelText: 'Adresse',
                    ),
                    onChanged: (value) {
                      formData.receiver_public_key_hash = value;
                    },
                  ),
                  TextButton(
                    child: const Text('Transférer'),
                    onPressed: () async {
                      var check_timer=await CheckTimer(30000);
                      if (check_timer=="ok"){
                        var transaction_amount =double.parse(formData.toJson()['amount']);
                        var requester_public_key_hash =formData.toJson()['receiver_public_key_hash'];
                        print('====launchNigEngine=====');
                        print(transaction_amount);
                        print(requester_public_key_hash);

                        //launchNigEngine(transaction_amount,requester_public_key_hash);

                        final result = await launchNigEngine(transaction_amount,"",requester_public_key_hash,"transfer",0,0,0,"","","","","");
                        print('====result=====');
                        print(result.status);

                        if (result.status == true) {
                          _showDialog('Transaction réussie');
                        } else {
                          _showDialog('La Transaction a échoué');
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
