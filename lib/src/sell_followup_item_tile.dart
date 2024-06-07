// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:form_app/src/api/item.dart';
import 'package:json_annotation/json_annotation.dart';
import 'api/sell_followup_item.dart';
import 'nig_engine.dart';
import 'package:chaquopy/chaquopy.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:restart_app/restart_app.dart';

import 'api/purchase_followup_item.dart';
import 'api/purchase_followup_fetch.dart';
import 'account_getactive.dart';
import 'account_file.dart';

import 'parameters.dart';
import 'timer.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'sell_followup_item_tile.g.dart';




@JsonSerializable()
class FormData {
  String? amount;
  String? pin;

  FormData({
    this.amount,
    this.pin,
  });

  factory FormData.fromJson(Map<String, dynamic> json) =>
      _$FormDataFromJson(json);

  Map<String, dynamic> toJson() => _$FormDataToJson(this);
}

Future<Account> fetchAccount(var item) async {
  return Account(requested_amount:item.requested_amount,requested_nig:item.requested_nig,requested_currency:item.requested_currency,requester_public_key_hash:item.requester_public_key_hash,timestamp:item.timestamp,payment_ref:item.payment_ref,smart_contract_ref:item.smart_contract_ref);
}

class Account {
  double requested_amount;
  double requested_nig;
  String requested_currency;
  String requester_public_key_hash;
  double timestamp;
  String payment_ref;
  String smart_contract_ref;

  Account({
    required this.requested_amount,
    required this.requested_nig,
    required this.requested_currency,
    required this.requester_public_key_hash,
    required this.timestamp,
    required this.payment_ref,
    required this.smart_contract_ref,
  });

  factory Account.fromJson(Map<String, dynamic> json) {
    return Account(
      requested_amount: json['requested_amount'],
      requested_nig: json['requested_nig'],
      requested_currency: json['requested_currency'],
      requester_public_key_hash: json['requester_public_key_hash'],
      timestamp: json['timestamp'],
      payment_ref: json['payment_ref'],
      smart_contract_ref: json['smart_contract_ref'],

    );
  }
}

class PinEncrypted {
  var pin_encrypted;
  PinEncrypted({
    required this.pin_encrypted,
  });
  factory PinEncrypted.fromJson(Map<String, dynamic> json) {
    return PinEncrypted(
      pin_encrypted: json['pin_encrypted'],
    );
  }
}



/// This is the widget responsible for building the item in the list,
/// once we have the actual data [item].
class ItemTile extends StatelessWidget {
  final SharedPreferences prefs;
  final Marketplace3Item item;

  const ItemTile({
    required this.item, 
    required this.prefs,
    super.key});

  action(){
    if (this.item.readonly_flag == false) {
      return const Text('Confirmer');
      }
    else{
      return const Text('En Attente');
      }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ListTile(
        leading: AspectRatio(
          aspectRatio: 1,
          child: ElevatedButton(
            child: action(),
            onPressed: CheckIfReadOnly(item) ? null : () => TriggerFollowUp(item,context,prefs),
        ),
        ),
        title: Text(item.requester_public_key_hash, style: Theme.of(context).textTheme.titleLarge),
        trailing: Text('\€ ${(item.requested_amount / 1).toStringAsFixed(2)}'),

      ),
    );
  }
}

CheckIfReadOnly(item){
  if (item.readonly_flag == false) {return false;}
  else
  {return true;}
}

Future<String> TriggerFollowUp(item,context,prefs) async {
              var account = await fetchAccount(item);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SecondPage(
                    data: account,
                    prefs : prefs,
                  )));
                  return "";
            }

/// This is the widget responsible for building the "still loading" item
/// in the list (represented with "..." and a crossed square).
class LoadingItemTile extends StatelessWidget {
  const LoadingItemTile({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ListTile(
        leading: const AspectRatio(
          aspectRatio: 1,
          child: Placeholder(),
        ),
        title: Text('...', style: Theme.of(context).textTheme.titleLarge),
        trailing: const Text('\$ ...'),
      ),
    );
  }
}



class SecondPage extends StatefulWidget {
  final SharedPreferences prefs;

  final Account data;

  SecondPage({
    super.key, 
    required this.prefs,
    required this.data});
  
  @override
  State<SecondPage> createState() => _SecondPageState();
}

class _SecondPageState extends State<SecondPage> {
  
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
        title: Text("Validation du virement"),
      ),
      body: Container(
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Container(
                  height: 64.0,
                  padding: EdgeInsets.all(8.0),
                  child: Text("CAS 1: le montant du virement correspond à 100% du montant convenu. La transaction s'est bien passée.",
                  style: TextStyle(height: 1,),)),
                Icon(
                  Icons.shop,
                  color: Colors.green,
                  size: 30.0,
                  ),
                TextButton(
                  child: const Text('Confirmer le virement'),
                  onPressed: () async {
                    var check_timer=await CheckTimer(30000);
                    if (check_timer=="ok"){
                      //Step 1 retrieval of the crypted pin
                      //final String public_key_response = await rootBundle.loadString('assets/nig_data.json');
                      //final public_key_data = await json.decode(public_key_response);
                      var public_key_data = await ActiveAccount();
                      var public_key=public_key_data["public_key_hash"];
                      print("public_key_hash");
                      print(public_key);
                      var decrypted_pin =null;
                      var response = await http.get(Uri.parse(nig_hostname+'/sell_followup_step4_pin/'+public_key+'/'+widget.data.payment_ref));
                      if (response.statusCode == 503 || response.statusCode == 302) {
                        //the server is in maintenance
                        //let's restart the application
                        Restart.restartApp();
                      }
                      if (response.statusCode == 200) {
                        // If the server did return a 200 OK response,
                        // then parse the JSON.
                        var pin_encrypted = PinEncrypted.fromJson(jsonDecode(response.body));
                        if (pin_encrypted.pin_encrypted!="not found"){
                            //step 2 validation of crypted pin
                          var account_private_key = await GetAccountPrivateKey();
                          var controller = await rootBundle.loadString('assets/nig_decrypt.py');
                          var param = "pin_encrypted_raw="""+json.encode(pin_encrypted.pin_encrypted)+"""\r"""+
                          "action_raw="""+json.encode('pin')+"""\r"""+
                          "account_raw="""+json.encode('')+"""\r"""+
                          "account_private_key_raw="""+json.encode(account_private_key)+"""\r"""+
                          "requester_public_key_hex_raw="""+json.encode('')+"""\r"""+
                          "mp_details_raw="""+json.encode('')+"""\r""";

                          print('====param=====');
                          print(param);
                          var transaction_data = await Chaquopy.executeCode(param+controller);
                          print('====transaction_data1=====');
                          debugPrint(transaction_data['textOutputOrError']);
                          Map data = jsonDecode(transaction_data['textOutputOrError']);
                          decrypted_pin = data['decrypted_pin'];
                          print('====result pin=====');
                          print(decrypted_pin);
                          print(formData.pin);
                          print(decrypted_pin == formData.pin);
                        };
                        
                        print('====result amount=====');
                        print(widget.data.requested_amount);
                        print(formData.amount);
                        print(widget.data.requested_amount==formData.amount);
                        
                        //if (decrypted_pin == formData.pin && widget.data.requested_amount.toString() == formData.amount) {
                        if (1==1) {
                          //_showDialog("Le Pin et le montant sont validés");
                          try{
                            var result_step4 = await launchNigEngine(widget.data.requested_nig,widget.data.requester_public_key_hash,widget.data.requester_public_key_hash,"purchase_step4",widget.data.requested_amount,widget.data.timestamp,widget.data.payment_ref,"",widget.data.requested_nig,widget.data.requested_currency,widget.data.smart_contract_ref);
                            print('====result purchase_step4=====');
                            print(result_step4.status);

                            if (result_step4.status == true) {
                                _showDialog("Virement confirmé");
                              } else {
                                _showDialog(result_step4.statusCode);
                                _showDialog("ERREUR: virement non confirmé");
                              };
                              }

                          catch(e) {
                          _showDialog(e.toString());
                          _showDialog("ERREUR: virement non confirmé");
                          };

                          }
                          else{
                            if (decrypted_pin != formData.pin && widget.data.requested_amount.toString() == formData.amount) {
                              _showDialog("Le Pin est erroné");
                            };
                            if (decrypted_pin == formData.pin && widget.data.requested_amount.toString() != formData.amount) {
                              _showDialog("Le montant est erroné");
                            };
                            if (decrypted_pin != formData.pin && widget.data.requested_nig.toString() != formData.amount) {
                              _showDialog("Le pin et le montant sont erronés");
                            };
                          };                        

                        } 
                        else if (response.statusCode == 503 || response.statusCode == 302) {
                            //the server is in maintenance
                            //let's restart the application
                            Restart.restartApp();
                          }
                        else {
                          // If the server did not return a 200 OK response,
                          // then throw an exception.
                          throw Exception('Failed to load Account');
                        };
                  }
                  else{
                      _showDialog('Merci de patienter: $check_timer (sec)');
                    }

                  },
                ),
                Container(
                  height: 100.0,
                  padding: EdgeInsets.all(12.0),
                  child: Text("CAS 2: le montant du virement ne correspond pas à 100% du montant convenu. Dans ce cas, la réputation de l'acheteur sera degradée mais pas la votre. Le paiement sera effectué et vous récupérez votre caution.",
                  style: TextStyle(height: 1,),)),
                Icon(
                    Icons.security_update_warning,
                    color: Colors.orange,
                    size: 30.0,
                  ),
                TextButton(
                  child: const Text("Confirmer un paiement partiel",
                  style: TextStyle(color : Colors.orange)),
                  onPressed: () async {
                    var check_timer=await CheckTimer(40000);
                    if (check_timer=="ok"){
                      try{
                        var result_step45 = await launchNigEngine(widget.data.requested_nig,widget.data.requester_public_key_hash,widget.data.requester_public_key_hash,"purchase_step45",widget.data.requested_amount,widget.data.timestamp,widget.data.payment_ref,"",widget.data.requested_nig,widget.data.requested_currency,widget.data.smart_contract_ref);
                        print('====result purchase_step45=====');
                        print(result_step45.status);

                        if (result_step45.status == true) {
                            _showDialog("Virement partiel confirmé");
                          } else {
                            _showDialog(result_step45.statusCode);
                            _showDialog("ERREUR: virement non confirmé");
                          };
                          }

                      catch(e) {
                      _showDialog(e.toString());
                      _showDialog("ERREUR: virement non confirmé");
                      }
                    }
                    else{
                        _showDialog('Merci de patienter: $check_timer (sec)');
                      }
                      },
                ),

                Container(
                  height: 120.0,
                  padding: EdgeInsets.all(12.0),
                  child: Text("CAS 3: le montant du virement n'est pas acceptable. Dans ce cas, la réputation de l'acheteur sera sévèrement degradée mais pas la votre. Aucun paiement ne sera effectué à l'acheteur. Attention, vous perdez votre caution. Le montant de la transaction est remboursé.",
                  style: TextStyle(height: 1,),)),
                Icon(
                    Icons.warning,
                    color: Colors.red,
                    size: 30.0,
                  ),
                TextButton(
                  child: const Text("SIGNALER un défaut de paiement",
                  style: TextStyle(color : Colors.red)),
                  onPressed: () async {
                    var check_timer=await CheckTimer(40000);
                    if (check_timer=="ok"){
                      try{
                        print("*******smart_contract defaut payment");

                        //STEP 1 - retrieval of request information to make signature
                        var public_key_data = await ActiveAccount();
                        var account_public_key_hex=public_key_data["public_key_hex"];
                        var account_public_key_hash=public_key_data["public_key_hash"];
                        var marketplace_api_utxo_url=null;
                        marketplace_api_utxo_url=nig_hostname+'/smart_contract_api/'+widget.data.smart_contract_ref;
                        var marketplace_api_utxo_response = await http.get(Uri.parse(marketplace_api_utxo_url));
                        if (marketplace_api_utxo_response.statusCode == 503 || marketplace_api_utxo_response.statusCode == 302) {
                          //the server is in maintenance
                          //let's restart the application
                          Restart.restartApp();
                        }
                        var marketplace_api_utxo_json=jsonDecode(marketplace_api_utxo_response.body);
                        var smart_contract_previous_transaction=marketplace_api_utxo_json['smart_contract_previous_transaction'];
                        var smart_contract_transaction_hash=marketplace_api_utxo_json['smart_contract_transaction_hash'];
                        var smart_contract_total=marketplace_api_utxo_json['total'];

                      
                        var marketplace_script1="""\r
memory_obj_2_load=['mp_request_step2_done']
mp_request_step2_done.step=66
mp_request_step2_done.get_mp_details(66)
""";
                        print('====marketplace_script1=====');
                        print(marketplace_script1);
                        var body = {
                          'smart_contract_type': 'source',
                          'smart_contract_public_key_hash': widget.data.smart_contract_ref,
                          'sender_public_key_hash': account_public_key_hex,
                          'smart_contract_transaction_hash': smart_contract_transaction_hash,
                          'smart_contract_previous_transaction': smart_contract_transaction_hash,
                          'payload':marketplace_script1,
                        };
                        var jsonString = json.encode(body);
                        var payload=marketplace_script1;
                        var marketplace_utxo_url=nig_hostname+'/smart_contract';
                        var marketplace_utxo_response = await http.post(Uri.parse(marketplace_utxo_url), headers: {"Content-Type": "application/json"}, body: jsonString);
                        if (marketplace_utxo_response.statusCode == 503 || marketplace_utxo_response.statusCode == 302) {
                          //the server is in maintenance
                          //let's restart the application
                          Restart.restartApp();
                        }
                        var mp_details=jsonDecode(marketplace_utxo_response.body)['smart_contract_result'];
                        
                        //STEP 2 - signature generation
                        print('====mp_details=====');
                        print(json.encode(mp_details));

                        var controller2 = await rootBundle.loadString('assets/nig_decrypt.py');
                        var account_private_key = await GetAccountPrivateKey();
                        var parame = "action_raw="""+json.encode("signature_generation")+"""\r"""+
                        "account_raw="""+json.encode("")+"""\r"""+
                        "pin_encrypted_raw="""+json.encode("")+"""\r"""+
                        "account_private_key_raw="""+json.encode(account_private_key)+"""\r"""+
                        "requester_public_key_hex_raw="""+json.encode("")+"""\r"""+
                        "mp_details_raw="""+json.encode(mp_details)+"""\r""";
                        print('====param=====');
                        var parame1=parame.replaceAll('false', "False");
                        var parame2=parame1.replaceAll('null', "None");
                        var parame3=parame2.replaceAll('true', "True");
                        print(parame3);
                        var transaction_data2 = await Chaquopy.executeCode(parame3+controller2);
                        print('====transaction_data2=====');
                        debugPrint(transaction_data2['textOutputOrError']);
                        Map account2 = jsonDecode(transaction_data2['textOutputOrError']);
                        var mp_request_signature=account2['mp_request_signature'];
                        
                        //STEP 3 - Launch of the request
                        var buyer_public_key_hash=public_key_data["public_key_hash"];
                        var marketplace_script2="""\r
memory_obj_2_load=['mp_request_step2_done']
mp_request_step2_done.payment_default("$buyer_public_key_hash","$mp_request_signature")
memory_list.add([mp_request_step2_done,mp_request_step2_done.mp_request_name,['account','step','timestamp','requested_amount',
  'requested_currency','requested_deposit','buyer_public_key_hash','timestamp_step1','timestamp_step2','timestamp_step3','timestamp_step4',
  'buyer_public_key_hex','requested_nig','timestamp_nig','seller_public_key_hex','seller_public_key_hash','encrypted_account','buyer_reput_trans','buyer_reput_reliability',
  'mp_request_signature','mp_request_id','previous_mp_request_name','mp_request_name','seller_safety_coef','smart_contract_ref','new_user_flag','reputation_buyer','reputation_seller']])
123456
""";
                        print('====marketplace_script2=====');
                        print(marketplace_script2);
                        payload=marketplace_script2;
                        body = {
                          'smart_contract_type': 'source',
                          'smart_contract_public_key_hash': widget.data.smart_contract_ref,
                          'sender_public_key_hash': widget.data.requester_public_key_hash,
                          'smart_contract_transaction_hash': smart_contract_transaction_hash,
                          'smart_contract_previous_transaction': smart_contract_transaction_hash,
                          'payload':payload,
                        };
                        jsonString = json.encode(body);
                        
                        marketplace_utxo_url=nig_hostname+'/smart_contract';

                        var result_cancel = await http.post(Uri.parse(marketplace_utxo_url),headers: {"Content-Type": "application/json"}, body: jsonString);
                        if (result_cancel.statusCode == 503 || result_cancel.statusCode == 302) {
                          //the server is in maintenance
                          //let's restart the application
                          Restart.restartApp();
                        }
                        var result_cancel_json=jsonDecode(result_cancel.body);
                        var smart_contract_error_flag=result_cancel_json['smart_contract_error_flag'];
                        var smart_contract_error_code=result_cancel_json['smart_contract_error_code'];
                        if (smart_contract_error_flag == false) {
                                _showDialog("La vente a été signalée comme frauduleuse");
                              } else {
                                _showDialog(smart_contract_error_code);
                                _showDialog("Le signalement a échoué");
                              };

                        }
                      catch(e) {
                            _showDialog(e.toString());
                            _showDialog("Le signalement a échoué");
                      };
                    }
                    else{
                        _showDialog('Merci de patienter: $check_timer (sec)');
                      }
                      },
                ),

                ElevatedButton(
                    onPressed: () {
                    Navigator.pop(context);
                    },
                    child: const Text('Retour'),
                    
                  ),








            ],
          ),
        ),
        )
      )
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