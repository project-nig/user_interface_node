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

part 'sell_request.g.dart';


@JsonSerializable()
class FormData {
  String? amount;
  String? gap;
  String? receiver_public_key_hash;

  FormData({
    this.amount,
    this.gap,
    this.receiver_public_key_hash,
  });

  factory FormData.fromJson(Map<String, dynamic> json) =>
      _$FormDataFromJson(json);

  Map<String, dynamic> toJson() => _$FormDataToJson(this);
}

class SellRequest extends StatefulWidget {
  final http.Client? httpClient;
  final SharedPreferences prefs;

  const SellRequest({
    this.httpClient,
    required this.prefs,
    super.key,
  });

  @override
  State<SellRequest> createState() => _PurchaseState();
}

class _PurchaseState extends State<SellRequest> {
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
        title: const Text('Vente de NIG'),
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
                  Expanded(child: Text("Merci de préciser le montant en Euro de NIG que vous souhaitez vendre.")),]),
                
                  TextFormField(
                    autofocus: true,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      filled: true,
                      hintText: 'Montant en Euro de NIG à vendre',
                      labelText: 'Montant',
                    ),
                    onChanged: (value) {
                      formData.amount = value;
                    },
                  ),
                  TextFormField(
                    autofocus: true,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      filled: true,
                      hintText: "% d'écart en moins au prix de référence",
                      labelText: 'Décote (défault 0)',
                    ),
                    onChanged: (value) {
                      formData.gap = value;
                    },
                  ),
                  TextButton(
                    child: const Text('Vendre'),
                    onPressed: () async {
                      var check_timer=await CheckTimer(30000);
                      if (check_timer=="ok"){
                        var requested_amount =double.parse(formData.toJson()['amount']);
                        var requested_gap=0.0;
                        try {
                          requested_gap = -double.parse(formData.toJson()['gap']);
                        }
                        catch(e){
                          requested_gap=0.0;
                        };
                        print('====launchNigEngine=====');
                        print(requested_amount);
                        var public_key_data = await ActiveAccount();
                        var requester_public_key_hash=public_key_data["public_key_hash"];
                        var requester_public_key_hex=public_key_data["public_key_hex"];
                        try{
                          var result_step1 = await launchNigEngine(0,requester_public_key_hash,"fake receiver_public_key_hash","purchase_step1_sell",requested_amount,requested_gap,0,"",requester_public_key_hex,"","","");
                          print('====result purchase_step1_sell=====');
                          print(result_step1.status);

                          if (result_step1.status == true) {
                            _showDialog("Demande de vente réussie");
                          } 
                          else {
                            _showDialog("La Demande de vente a échoué");
                            _showDialog(result_step1.statusCode);
                          };
                        }
                        catch(e) {
                          _showDialog(e.toString());
                          _showDialog("La Demande de vente a échoué");
                        };
                    }
                    else{
                      _showDialog('Merci de patienter: $check_timer (sec)');
                    }
                    },
                  ),
                  const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                  Icon(
                    Icons.info_outline,
                    color: Colors.green,
                    size: 30.0,
                  ),
                  Expanded(child: Text("Une fois créée, vous pouvez suivre votre demande dans le menu 55_Suivi des Ventes de NIG.")),]),
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
