// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:form_app/src/api/item.dart';
import 'package:json_annotation/json_annotation.dart';
import 'api/purchase_followup_item.dart';
import 'nig_engine.dart';
import 'package:chaquopy/chaquopy.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'account_file.dart';
import 'parameters.dart';
import 'package:http/http.dart' as http;
import 'account_getactive.dart';
import 'timer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:restart_app/restart_app.dart';
import 'package:intl/intl.dart';


Future<Account> fetchAccount(var item) async {
  print('==fetchAccount');
  var account_private_key = await GetAccountPrivateKey();
  var controller = await rootBundle.loadString('assets/nig_decrypt.py');
  var param = "account_raw="""+json.encode(item.account)+"""\r"""+
  "action_raw="""+json.encode('account')+"""\r"""+
  "pin_encrypted_raw="""+json.encode('')+"""\r"""+
  "account_private_key_raw="""+json.encode(account_private_key)+"""\r"""+
  "requester_public_key_hex_raw="""+json.encode('')+"""\r"""+
  "mp_details_raw="""+json.encode('')+"""\r""";
  print('====param=====');
  print(param);
  var transaction_data = await Chaquopy.executeCode(param+controller);
  print('====transaction_data=====');
  debugPrint(transaction_data['textOutputOrError']);
  Map data = jsonDecode(transaction_data['textOutputOrError']);
  var decrypt = data['decrypted_account'];
  return Account(name: decrypt['name'],iban: decrypt['iban'],bic: decrypt['bic'],email: decrypt['email'],phone: decrypt['phone'],country: decrypt['country'],pin: decrypt['pin'],requested_amount:item.requested_amount,requested_nig:item.requested_nig,requested_currency:item.requested_currency,requester_public_key_hash:item.requester_public_key_hash,receiver_public_key_hash:decrypt['public_key_hash'],account:item.account,timestamp:item.timestamp,payment_ref:item.payment_ref,smart_contract_ref:item.smart_contract_ref);
}

class Account {
  String name;
  String iban;
  String bic;
  String email;
  String phone;
  String country;
  int pin;
  double requested_amount;
  double requested_nig;
  String requested_currency;
  String requester_public_key_hash;
  String receiver_public_key_hash;
  String account;
  double timestamp;
  String payment_ref;
  String smart_contract_ref;

  Account({
    required this.name,
    required this.iban,
    required this.bic,
    required this.email,
    required this.phone,
    required this.country,
    required this.pin,
    required this.requested_amount,
    required this.requested_nig,
    required this.requested_currency,
    required this.requester_public_key_hash,
    required this.receiver_public_key_hash,
    required this.account,
    required this.timestamp,
    required this.payment_ref,
    required this.smart_contract_ref,
  });

  factory Account.fromJson(Map<String, dynamic> json) {
    return Account(
      name: json['name'],
      iban: json['iban'],
      bic: json['bic'],
      email: json['email'],
      phone: json['phone'],
      country: json['country'],
      pin: json['pin'],
      requested_amount: json['requested_amount'],
      requested_nig: json['requested_nig'],
      requested_currency: json['requested_currency'],
      requester_public_key_hash: json['requester_public_key_hash'],
      receiver_public_key_hash: json['receiver_public_key_hash'],
      account: json['account'],
      timestamp: json['timestamp'],
      payment_ref: json['payment_ref'],
      smart_contract_ref: json['smart_contract_ref'],

    );
  }
}



/// This is the widget responsible for building the item in the list,
/// once we have the actual data [item].
class ItemTile extends StatelessWidget {
  final SharedPreferences prefs;
  final Marketplace2Item item;

  const ItemTile({
    required this.item,
    required this.prefs,
    super.key});

  action(){
    if (this.item.readonly_flag == false) {
      return const Text('Payer');
      }
    else{
      if (this.item.step == 1) {
        return const Text('Annuler');
      }
      else{
        return const Text('En Cours');
      }
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
            onPressed:  CheckIfReadOnly(item) ? null : () => TriggerPurchaseFollowUp(item,context,prefs),
        ),
        ),
        title: Text(item.requester_public_key_hash, style: Theme.of(context).textTheme.titleLarge),
        trailing: Text('\€ ${(item.requested_amount / 1).toStringAsFixed(2)}'),

      ),
    );
  }
}

CheckIfReadOnly(item){
  if (item.readonly_flag == false) {
    return false;
    }
  else{
    if ( item.step<=2){
      return false;
    }
    else{
      return true;
    }
    }
}
  

Future<String> TriggerPurchaseFollowUp(item,context,prefs) async {
  if (item.readonly_flag == false && item.step==2) {
    var account = await fetchAccount(item);
    Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => SecondPage(
        data: account,
        prefs: prefs,
      )));
  }
  else{
    Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => CancelPage(
        data: item,
        prefs: prefs,
      )));
  }
  
  
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

  const SecondPage({
    super.key,
    required this.prefs, 
    required this.data});
  

  @override
  State<SecondPage> createState() => _SecondPageState();
}

class _SecondPageState extends State<SecondPage> {

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
        title: Text("Détail du virement"),
      ),
      body: Container(
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
            Container(
              height: 54.0,
              padding: EdgeInsets.all(12.0),
              child: Text("Détail du virement bancaire à effectuer:",
               style: TextStyle(fontWeight: FontWeight.w700))),

               DataTable(
              columns: <DataColumn>[
                DataColumn(
                  label: Expanded(
                    child: Text(
                      'Vendeur',
                      style: TextStyle(fontStyle: FontStyle.italic),
                    ),
                  ),
                ),
              ],
              rows: <DataRow>[
                DataRow(
                  cells: <DataCell>[
                    DataCell(Text('${widget.data.requester_public_key_hash}')),
                  ],
                ),
              ],
            ),

            DataTable(
              columns:  <DataColumn>[
                DataColumn(
                  label: Expanded(
                    child: Text(
                      'RIB',
                      style: TextStyle(fontStyle: FontStyle.italic),
                    ),
                  ),
                ),
                DataColumn(
                  label: Expanded(
                    child: Text(
                      '${widget.data.name}',
                      style: TextStyle(fontStyle: FontStyle.italic),
                    ),
                  ),
                ),
              ],
              rows:  <DataRow>[
                DataRow(
                  cells: <DataCell>[
                    DataCell(Text('iban')),
                    DataCell(Text('${widget.data.iban}')),
                  ],
                ),
                DataRow(
                  cells: <DataCell>[
                    DataCell(Text('bic')),
                    DataCell(Text('${widget.data.bic}')),
                  ],
                ),
                DataRow(
                  cells: <DataCell>[
                    DataCell(Text('email')),
                    DataCell(Text('${widget.data.email}')),
                  ],
                ),
                DataRow(
                  cells: <DataCell>[
                    DataCell(Text('téléphone')),
                    DataCell(Text('${widget.data.phone}')),
                  ],
                ),
              ],
            ),


             DataTable(
              columns:  <DataColumn>[
                DataColumn(
                  label: Expanded(
                    child: Text(
                      'Montant à virer',
                      style: TextStyle(fontStyle: FontStyle.italic),
                    ),
                  ),
                ),
                DataColumn(
                  label: Expanded(
                    child: Text(
                      '${widget.data.requested_amount} ${widget.data.requested_currency}',
                      style: TextStyle(fontStyle: FontStyle.italic),
                    ),
                  ),
                ),
              ],
              rows:  <DataRow>[
                DataRow(
                  cells: <DataCell>[
                    DataCell(Text('PIN à indiquer dans le virement')),
                    DataCell(Text('${widget.data.pin}')),
                  ],
                ),
              ],
            ),




                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Retour'),
                  
                ),
            TextButton(
                    child: const Text('Confirmer le virement'),
                    onPressed: () async {
                      var check_timer=await CheckTimer(30000);
                      if (check_timer=="ok"){
                        //var result_step3 = await launchNigEngine("widget.data.requested_nig","widget.data.receiver_public_key_hash","purchase_step3","widget.data.requested_amount","widget.data.timestamp","widget.data.payment_ref","","widget.data.requested_nig","widget.data.requested_currency");
                        var result_step3 = await launchNigEngine(widget.data.requested_nig,widget.data.requester_public_key_hash,widget.data.receiver_public_key_hash,"purchase_step3",widget.data.requested_amount,widget.data.timestamp,widget.data.payment_ref,"",widget.data.requested_nig,widget.data.requested_currency,widget.data.smart_contract_ref);
                        print('====result purchase_step3=====');
                        print(result_step3.status);

                        if (result_step3.status == true) {
                            _showDialog("Virement pris en compte");
                          } else {
                            _showDialog(result_step3.statusCode);
                            _showDialog("ERREUR: virement non pris en compte");
                          };
                      }
                      else{
                        _showDialog('Merci de patienter: $check_timer (sec)');
                      }

                    },
                  ),
            TextButton(
                  child: const Text("Annuler l'achat",
                  style: TextStyle(color : Colors.red)),
                  onPressed: () async {
                    var check_timer=await CheckTimer(40000);
                    if (check_timer=="ok"){
                      try{
                        print("*******smart_contract_cancellation ");

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
mp_request_step2_done.step=99
mp_request_step2_done.get_mp_details(99)
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
                        print('====transaction_data=====');
                        debugPrint(transaction_data2['textOutputOrError']);
                        Map account2 = jsonDecode(transaction_data2['textOutputOrError']);
                        var mp_request_signature=account2['mp_request_signature'];
                        
                        //STEP 3 - Launch of the request
                        var buyer_public_key_hash=public_key_data["public_key_hash"];
                        var marketplace_script2="""\r
memory_obj_2_load=['mp_request_step2_done']
mp_request_step2_done.cancel("$buyer_public_key_hash","$mp_request_signature")
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
                                _showDialog("L'achat est annulé");
                              } else {
                                _showDialog(smart_contract_error_code);
                                _showDialog("L'annulation a échoué");
                              };

                        }
                      catch(e) {
                            _showDialog(e.toString());
                            _showDialog("L'annulation a échoué");
                      };
                    }
                    else{
                        _showDialog('Merci de patienter: $check_timer (sec)');
                      }
  
                    },
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

class CancelPage extends StatefulWidget {
  final SharedPreferences prefs;
  final Marketplace2Item data;

  const CancelPage({
    super.key,
    required this.prefs, 
    required this.data});
  

  @override
  State<CancelPage> createState() => _CancelPageState();
}

class _CancelPageState extends State<CancelPage> {

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
        title: Text("Annulation de la Demande d'achat"),
      ),
      body: Container(
        padding: EdgeInsets.all(12.0),
        alignment: Alignment.center,
        child: Column(
          children: <Widget>[
            Container(
              height: 54.0,
              padding: EdgeInsets.all(12.0),
              child: Text("Détail de la demande d'achat",
               style: TextStyle(fontWeight: FontWeight.w700))),
               

            DataTable(
              columns:  <DataColumn>[
                DataColumn(
                  label: Expanded(
                    child: Text(
                      'Montant',
                      style: TextStyle(fontStyle: FontStyle.italic),
                    ),
                  ),
                ),
                DataColumn(
                  label: Expanded(
                    child: Text(
                      '${widget.data.requested_amount} €',
                      style: TextStyle(fontStyle: FontStyle.italic),
                    ),
                  ),
                ),
              ],
              rows:  <DataRow>[
                DataRow(
                  cells: <DataCell>[
                    DataCell(Text('Montant')),
                    DataCell(Text('${widget.data.requested_nig} NIG')),
                  ],
                ),
                DataRow(
                  cells: <DataCell>[
                    DataCell(Text('Horaire (GMT)')),
                    DataCell(Text('${DateFormat('dd/MM/yyyy, H:mm:s').format(DateTime.fromMillisecondsSinceEpoch((widget.data.timestamp*1000).round()))}')),
                  ],
                ),
              ],
            ),

            DataTable(
              columns: <DataColumn>[
                DataColumn(
                  label: Expanded(
                    child: Text(
                      'SmartContract',
                      style: TextStyle(fontStyle: FontStyle.italic),
                    ),
                  ),
                ),
              ],
              rows: <DataRow>[
                DataRow(
                  cells: <DataCell>[
                    DataCell(Text('${widget.data.smart_contract_ref}')),
                  ],
                ),
              ],
            ),




                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Retour'),
                  
                ),
            
            TextButton(
                  child: const Text("Annuler l'achat",
                  style: TextStyle(color : Colors.red)),
                  onPressed: () async {
                    var check_timer=await CheckTimer(40000);
                    if (check_timer=="ok"){
                      try{
                        print("*******smart_contract_cancellation ");
                        print("widget.data.smart_contract_ref");
                        print(widget.data.smart_contract_ref);

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
mp_request_step2_done.step=99
mp_request_step2_done.get_mp_details(99)
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
                        print('====transaction_data=====');
                        debugPrint(transaction_data2['textOutputOrError']);
                        Map account2 = jsonDecode(transaction_data2['textOutputOrError']);
                        var mp_request_signature=account2['mp_request_signature'];
                        
                        //STEP 3 - Launch of the request
                        var buyer_public_key_hash=public_key_data["public_key_hash"];
                        var marketplace_script2="""\r
memory_obj_2_load=['mp_request_step2_done']
mp_request_step2_done.cancel("$buyer_public_key_hash","$mp_request_signature")
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
                                _showDialog("L'achat est annulé");
                              } else {
                                _showDialog(smart_contract_error_code);
                                _showDialog("L'annulation a échoué");
                              };

                        }
                      catch(e) {
                            _showDialog(e.toString());
                            _showDialog("L'annulation a échoué");
                      };
                    }
                    else{
                        _showDialog('Merci de patienter: $check_timer (sec)');
                      }
  
},
                ),
          ],
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