// Copyright 2020, the Flutter project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:json_annotation/json_annotation.dart';
import 'nig_engine.dart';
import 'account_file.dart';
import 'account_getactive.dart';
import 'timer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:restart_app/restart_app.dart';
import 'purchase.dart';

part 'purchase_intro.g.dart';


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

class PurchaseIntro extends StatefulWidget {
  final http.Client? httpClient;
  final SharedPreferences prefs;

  const PurchaseIntro({
    this.httpClient,
    required this.prefs,
    super.key,
  });

  @override
  State<PurchaseIntro> createState() => _PurchaseIntroState();
}

class _PurchaseIntroState extends State<PurchaseIntro> {
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
        title: const Text('Achat de NIG'),
      ),
      body: Form(
        child: Scrollbar(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                ...[
                  const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                  Icon(
                    Icons.arrow_circle_right_outlined,
                    color: Colors.green,
                    size: 30.0,
                  ),
                  Expanded(child: Text("Merci de préciser le montant en Euro que vous souhaitez acheter afin d'accéder à la liste des demandes de vente correspondantes. L'achat sera réalisé à la prochaine étape.")),]),
                  TextFormField(
                    autofocus: true,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      filled: true,
                      hintText: 'Montant en Euro de NIG à acheter',
                      labelText: 'Montant',
                    ),
                    onChanged: (value) {
                      formData.amount = value;
                    },
                  ),
                  TextButton(
                    child: const Text("Lister les demandes de vente"),
                    onPressed: () async {
                      await UpdateSellAmount(double.parse(formData.toJson()['amount']));
                      Navigator.of(context).push(MaterialPageRoute(builder: (context) => PurchaseHome(prefs: widget.prefs, amount:5)));
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
