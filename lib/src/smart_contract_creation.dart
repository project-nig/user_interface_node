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
import 'package:chaquopy/chaquopy.dart';
import 'package:flutter/services.dart';
import 'parameters.dart';
import 'dart:developer';


part 'smart_contract_creation.g.dart';



@JsonSerializable()
class FormData {
  String? sc_type;
  String? sc_new;
  String? sc_account;
  String? sc_payload;
  String? receiver_public_key_hash;

  FormData({
    this.sc_type,
    this.sc_new,
    this.sc_account,
    this.sc_payload,
    this.receiver_public_key_hash,
  });

  factory FormData.fromJson(Map<String, dynamic> json) =>
      _$FormDataFromJson(json);

  Map<String, dynamic> toJson() => _$FormDataToJson(this);
}

class Form_SC_Creation extends StatefulWidget {
  final http.Client? httpClient;
  final SharedPreferences prefs;

  const Form_SC_Creation({
    this.httpClient,
    required this.prefs,
    super.key,
  });

  @override
  State<Form_SC_Creation> createState() => _Form_SC_CreationState();
}

class _Form_SC_CreationState extends State<Form_SC_Creation> {
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
        title: const Text("Création d'un SmartContract"),
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
                      hintText: 'api ou source (défaut)',
                      labelText: 'Type de transaction',
                    ),
                    onChanged: (value) {
                      formData.sc_type = value;
                    },
                  ),
                  TextFormField(
                    autofocus: true,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      filled: true,
                      hintText: 'true ou false (défaut)',
                      labelText: 'Nouveau SmartContract',
                    ),
                    onChanged: (value) {
                      formData.sc_new = value;
                    },
                  ),
                  TextFormField(
                    autofocus: true,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      filled: true,
                      hintText: 'xxxx...',
                      labelText: 'Numéro du SmartContract',
                    ),
                    onChanged: (value) {
                      formData.sc_account = value;
                    },
                  ),
                  TextFormField(
                    autofocus: true,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      filled: true,
                      hintText: 'Rentrer la Payload...',
                      labelText: 'Payload',
                    ),
                    onChanged: (value) {
                      formData.sc_payload = value;
                    },
                    maxLines: 5,
                  ),
                  TextButton(
                    child: const Text('Créer'),
                    onPressed: () => launch_SC_creation()
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


  Future<String> launch_SC_creation() async {
  var check_timer=await CheckTimer(30000);

  if (check_timer=="ok"){
    var smart_contract_ref = formData.toJson()['sc_account'];
    var smart_contract_payload = formData.toJson()['sc_payload'];
    var sc_type = formData.toJson()['sc_type'];
    var sc_new = formData.toJson()['sc_new'];
    var smart_contract_new=false;
    if(sc_new=='true'){
      smart_contract_new=true;}
    var utxo_json=new Map();
    var smart_contract_transaction_hash='';

    if (smart_contract_ref== null){
      //STEP 1- creation of a new Smart Contract address
      var sc_controller = await rootBundle.loadString('assets/nig_decrypt.py');
      var sc_param = "action_raw="""+json.encode("account_creation")+"""\r"""+
      "account_raw="""+json.encode("")+"""\r"""+
      "pin_encrypted_raw="""+json.encode("")+"""\r"""+
      "account_private_key_raw="""+json.encode("")+"""\r"""+
      "requester_public_key_hex_raw="""+json.encode("")+"""\r"""+
      "mp_details_raw="""+json.encode("")+"""\r""";

      print('====param=====');
      var sc_param1=sc_param.replaceAll('false', "False");
      var sc_param2=sc_param1.replaceAll('null', "None");
      var sc_param3=sc_param2.replaceAll('true', "True");
      print(sc_param3);
      var sc_transaction_data = await Chaquopy.executeCode(sc_param3+sc_controller);
      print('====sc_transaction_data=====');
      debugPrint(sc_transaction_data['textOutputOrError']);

      //var account = transaction_data['textOutputOrError'];
      Map sc_account = jsonDecode(sc_transaction_data['textOutputOrError']);

      print('====result account_creation=====');
      smart_contract_ref=sc_account['public_key_hash'];
      print("smart_contract_ref");
      print(smart_contract_ref);
      _showDialog('SmartContract account: $smart_contract_ref');
    }
    else{
      var utxo_url=nig_hostname+'/utxo/'+smart_contract_ref;
      var utxo_response = await http.get(Uri.parse(utxo_url));
      if (utxo_response.statusCode == 503 || utxo_response.statusCode == 302) {
          //the server is in maintenance
          //let's restart the application
          Restart.restartApp();
        }
      utxo_json=jsonDecode(utxo_response.body);
      print('====utxo_json=====');
      print(utxo_json);
      try{
        smart_contract_transaction_hash=utxo_json['utxos'][0]['smart_contract_transaction_hash'];}
      catch(e) {
      }
    }

    //Step 2 - creation of the SmartContract
    var public_key_data = await ActiveAccount();
    var account_public_key_hash=public_key_data["public_key_hash"];
    var private_key=public_key_data["private_key_str"];
    var marketplace_utxo_url='';
    var body= new Map();
    if (smart_contract_transaction_hash==''){
      body = {
        'smart_contract_public_key_hash': smart_contract_ref,
        'sender_public_key_hash': account_public_key_hash,
        'payload':smart_contract_payload,
      };
      marketplace_utxo_url=nig_hostname+'/smart_contract_creation';
    }
    else{
      body = {
        'smart_contract_public_key_hash': smart_contract_ref,
        'sender_public_key_hash': account_public_key_hash,
        'payload':smart_contract_payload,
        'smart_contract_transaction_hash': smart_contract_transaction_hash,
        'smart_contract_previous_transaction': smart_contract_transaction_hash,
        'smart_contract_type':'source',
        'smart_contract_new':smart_contract_new,
      };
      marketplace_utxo_url=nig_hostname+'/smart_contract';
      print('====>smart_contract_transaction_hash');
      print(smart_contract_transaction_hash);

    }
    var jsonString = json.encode(body);
    print("====>body");
    print(body);

    var marketplace_utxo_response = await http.post(Uri.parse(marketplace_utxo_url),headers: {"Content-Type": "application/json"}, body: jsonString);
    if (marketplace_utxo_response.statusCode == 503 || marketplace_utxo_response.statusCode == 302) {
      //the server is in maintenance
      //let's restart the application
      Restart.restartApp();
    }

    var marketplace_utxo_json=jsonDecode(marketplace_utxo_response.body);
    var smart_contract_error_flag=marketplace_utxo_json['smart_contract_error_flag'];

    print("===smart_contract_error_flag");
    print(smart_contract_error_flag);

    if (smart_contract_error_flag==true){
      //there is an error when processing the SmartContract
      var error=marketplace_utxo_json['smart_contract_error_code'];
      _showDialog('Erreur lors de la création: $error');
    }
    else{
      if (sc_type=="api"){
        //normal processing of the SmartContract
        var smart_contract_result=jsonDecode(marketplace_utxo_response.body)['smart_contract_result'];
        _showDialog('Résultat: $smart_contract_result');
      }
      else{
        //normal processing of the SmartContract
        print("*******smart_contract_new");
        print(marketplace_utxo_json['smart_contract_new']);
        print("*******marketplace_utxo_json");

        print(marketplace_utxo_json);
        var smart_contract_account=marketplace_utxo_json['smart_contract_account'];
        var smart_contract_sender=marketplace_utxo_json['smart_contract_sender'];
        var smart_contract_new=marketplace_utxo_json['smart_contract_new'];
        var smart_contract_flag=marketplace_utxo_json['smart_contract_flag'];;
        var smart_contract_gas=marketplace_utxo_json['smart_contract_gas'];
        var smart_contract_memory=marketplace_utxo_json['smart_contract_memory'];
        var smart_contract_memory_size=marketplace_utxo_json['smart_contract_memory_size'];
        var smart_contract_type=marketplace_utxo_json['smart_contract_type'];
        var smart_contract_payload=marketplace_utxo_json['smart_contract_payload'];
        var smart_contract_result=marketplace_utxo_json['smart_contract_result'];
        var smart_contract_previous_transaction=marketplace_utxo_json['smart_contract_previous_transaction'];
        var smart_contract_transaction_hash=marketplace_utxo_json['smart_contract_transaction_hash'];

        //construction of the transaction
        var controller = await rootBundle.loadString('assets/nig_script.py');
        var action="smart_contract_creation";
        if (smart_contract_new==false){action="smart_contract_update";}
        
        var account_temp_input=false;
        var account_temp_output=true;
        var interface_public_key_hash ="1f8da1bae39c78bf4d8f9f3b8727e50001eed5ae";
        utxo_json['amount']=10;
        
        var param = "action_raw="""+json.encode(action)+"""\r"""+
        "transaction_amount_raw="""+json.encode(0)+"""\r"""+
        "account_temp_input_raw="""+json.encode(account_temp_input)+"""\r"""+
        "account_temp_output_raw="""+json.encode(account_temp_output)+"""\r"""+
        "marketplace_step_raw="""+json.encode("")+"""\r"""+
        "interface_public_key_hash_raw="""+json.encode(interface_public_key_hash)+"""\r"""+
        "receiver_public_key_hash_raw="""+json.encode("")+"""\r"""+
        "requester_public_key_hash_raw="""+json.encode("")+"""\r"""+
        "requester_public_key_hex_raw="""+json.encode("")+"""\r"""+
        "requested_deposit_raw="""+json.encode("")+"""\r"""+

        
        "requested_amount_raw="""+json.encode(0)+"""\r"""+
        "timestamp_nig_raw="""+json.encode("")+"""\r"""+
        "payment_ref_raw="""+json.encode("")+"""\r"""+
        "requested_nig_raw="""+json.encode("")+"""\r"""+
        "requested_currency_raw="""+json.encode("")+"""\r"""+
        "private_key_raw="""+json.encode(private_key)+"""\r"""+
        "utxo_json_raw="""+json.encode(utxo_json['utxos'])+"""\r"""+
        "utxo_json_marketplace_raw="""+json.encode("")+"""\r"""+


        "smart_contract_account_raw="""+json.encode(smart_contract_account)+"""\r"""+
        "smart_contract_sender_raw="""+json.encode(smart_contract_sender)+"""\r"""+
        "smart_contract_new_raw="""+json.encode(smart_contract_new)+"""\r"""+
        "smart_contract_flag_raw="""+json.encode(smart_contract_flag)+"""\r"""+
        "smart_contract_gas_raw="""+json.encode(smart_contract_gas)+"""\r"""+
        "smart_contract_memory_raw="""+json.encode(smart_contract_memory)+"""\r"""+
        "smart_contract_memory_size_raw="""+json.encode(smart_contract_memory_size)+"""\r"""+
        "smart_contract_type_raw="""+json.encode(smart_contract_type)+"""\r"""+
        "smart_contract_payload_raw="""+json.encode(smart_contract_payload)+"""\r"""+
        "smart_contract_result_raw="""+json.encode(smart_contract_result)+"""\r"""+
        "smart_contract_previous_transaction_raw="""+json.encode(smart_contract_previous_transaction)+"""\r"""+
        "smart_contract_transaction_hash_raw="""+json.encode(smart_contract_transaction_hash)+"""\r"""+
        "seller_public_key_hash_raw="""+json.encode("")+"""\r"""+
        "smart_contract_ref_raw="""+json.encode(smart_contract_ref)+"""\r"""+

        "NUMBER_OF_LEADING_ZEROS_raw="""+json.encode(NUMBER_OF_LEADING_ZEROS)+"""\r"""+
        "BLOCK_REWARD_raw="""+json.encode(BLOCK_REWARD)+"""\r"""+
        "NETWORK_DEFAULT_raw="""+json.encode(NETWORK_DEFAULT)+"""\r"""+
        "ROUND_VALUE_DIGIT_raw="""+json.encode(ROUND_VALUE_DIGIT)+"""\r"""+
        "DEFAULT_TRANSACTION_FEE_PERCENTAGE_raw="""+json.encode(DEFAULT_TRANSACTION_FEE_PERCENTAGE)+"""\r"""+
        "INTERFACE_TRANSACTION_FEE_SHARE_raw="""+json.encode(INTERFACE_TRANSACTION_FEE_SHARE)+"""\r"""+
        "NODE_TRANSACTION_FEE_SHARE_raw="""+json.encode(NODE_TRANSACTION_FEE_SHARE)+"""\r"""+
        "MINER_TRANSACTION_FEE_SHARE_raw="""+json.encode(MINER_TRANSACTION_FEE_SHARE)+"""\r"""+
        "INTERFACE_BLOCK_REWARD_PERCENTAGE_raw="""+json.encode(INTERFACE_BLOCK_REWARD_PERCENTAGE)+"""\r"""+
        "NODE_BLOCK_REWARD_PERCENTAGE_raw="""+json.encode(NODE_BLOCK_REWARD_PERCENTAGE)+"""\r"""+
        "MINER_BLOCK_REWARD_PERCENTAGE_raw="""+json.encode(MINER_BLOCK_REWARD_PERCENTAGE)+"""\r"""+
        "EUR_NIG_VALUE_START_TIMESTAMP_raw="""+json.encode(EUR_NIG_VALUE_START_TIMESTAMP)+"""\r"""+
        "EUR_NIG_VALUE_START_CONVERSION_RATE_raw="""+json.encode(EUR_NIG_VALUE_START_CONVERSION_RATE)+"""\r"""+
        "EUR_NIG_VALUE_START_INCREASE_DAILY_PERCENTAGE_raw="""+json.encode(EUR_NIG_VALUE_START_INCREASE_DAILY_PERCENTAGE)+"""\r"""+
        "EUR_NIG_VALUE_START_INCREASE_HALVING_DAYS_raw="""+json.encode(EUR_NIG_VALUE_START_INCREASE_HALVING_DAYS)+"""\r"""+

        "INTERFACE_PUBLIC_KEY_HASH_raw="""+json.encode(INTERFACE_PUBLIC_KEY_HASH)+"""\r"""+
        "NODE_PUBLIC_KEY_HASH_raw="""+json.encode(NODE_PUBLIC_KEY_HASH)+"""\r""";

        var param1=param.replaceAll('false', "False");
        var param2=param1.replaceAll('null', "None");
        var param3=param2.replaceAll('true', "True");

        print("===param");
        log(param3);
        
        var transaction_data = await Chaquopy.executeCode(param3+controller);

        print('====transaction_data=====');
        log(transaction_data['textOutputOrError']);
        Map data = jsonDecode(transaction_data['textOutputOrError']);
        
        //test to POST a transaction
        var url =nig_hostname+'/transactions';
        //encode Map to JSON
        data.removeWhere((key, value) => key == "transaction_amount");
        print("===transaction details===");
        print(data['transaction']['timestamp']);
        try {data['transaction']['inputs'][0]['output_index'];}
        catch(e) {print(e);};
        try {data['transaction']['inputs'][0]['network'];}
        catch(e) {print(e);};
        
        print("=========data['transaction']['inputs']");
        print(data['transaction']['inputs']);
        print("=========data['transaction']['outputs']");
        print(data['transaction']['outputs']);
        print("=========data['transaction']['transaction_hash']");
        print(data['transaction']['transaction_hash']);


        var body = json.encode(data);
        //var body = data;
        print('====body1=====');
        log(body);

        var response_post = await http.post(Uri.parse(url),
          headers: {"Content-Type": "application/json"},
          body: body
        );
        if (response_post.statusCode == 503 || response_post.statusCode == 302) {
          //the server is in maintenance
          //let's restart the application
          Restart.restartApp();
        }
        else if (response_post.statusCode == 200) {
          _showDialog('Le Smart Contrat a été créé');
        }
        
      }
      }

  }
  else{
    _showDialog('Merci de patienter: $check_timer (sec)');
  }
  return "";
}


}


