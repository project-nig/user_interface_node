// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:form_app/src/api/item.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:http/http.dart' as http;
import 'api/sell_item.dart';
import 'nig_engine.dart';
import 'parameters.dart';
import 'dart:convert';
import 'account_getactive.dart';
import 'account_file.dart';
import 'package:flutter/services.dart';
import 'package:chaquopy/chaquopy.dart';
import 'package:intl/intl.dart';
import 'timer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:restart_app/restart_app.dart';
import 'package:rate_in_stars/rate_in_stars.dart';



/// This is the widget responsible for building the item in the list,
/// once we have the actual data [item].

class ItemTile extends StatelessWidget {
  final Marketplace1Item item;
  final SharedPreferences prefs;

  const ItemTile({
    required this.item, 
    required this.prefs,
    super.key});

  action(){
    if (this.item.readonly_flag == false) {
      return const Text('Vendre');
      }
    else{
      return const Text('Détails',
      style: TextStyle(color : Colors.yellow));
      }
  }

  

  @override
  Widget build(BuildContext context) {
    //default value for new user
    var star_rating=5.0;
    var star_color=Colors.grey;
    if (item.buyer_reput_trans!=0){
      //this is not a new user
      star_rating=(item.buyer_reput_reliability/100)*5;
      if (star_rating<3){star_rating=3.0;};
      if (item.buyer_reput_reliability>star_rating_level_high){star_color=Colors.green;}
      else if(item.buyer_reput_reliability>=star_rating_level_medium){star_color=Colors.amber;}
      else if(item.buyer_reput_reliability<star_rating_level_medium){star_color=Colors.red;}
    };
    

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ListTile(
        leading: AspectRatio(
          aspectRatio: 1,
          child: ElevatedButton(
            child: action(),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SecondPage(
                    data: item,
                    prefs: prefs,
                  )));
            },
        ),
        ),
        //title: Text(item.buyer_reput_trans.toString(), style: Theme.of(context).textTheme.titleLarge),
        title: RatingStars(
        editable: false,
        rating: star_rating,
        color: star_color,
        iconSize: 32,
      ),
        
        trailing: Text('\€ ${(item.requested_amount / 1).toStringAsFixed(2)}'),

      ),
    );
  }
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

  final Marketplace1Item data;
  final SharedPreferences prefs;

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

  action(){
    if (widget.data.readonly_flag == false) {
      return const Text('');
      }
    else{
      return const Text('Annuler la demande',
                  style: TextStyle(color : Colors.red) ,
                  );
      }

  }

  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text("Détail de la demande d'achat"),
      ),
      body: Container(
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children:<Widget>[
                Container(
                height: 54.0,
                padding: EdgeInsets.all(5.0),),


                DataTable(
                  columns: <DataColumn>[
                    DataColumn(
                      label: Expanded(
                        child: Text(
                          'Acheteur',
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
                    DataRow(
                      cells: <DataCell>[
                        DataCell(Text('Taux de fiabilité:    ${widget.data.buyer_reput_reliability} %')),
                      ],
                    ),
                    DataRow(
                      cells: <DataCell>[
                        DataCell(Text('Nombre de transaction:    ${widget.data.buyer_reput_trans}')),
                      ],
                    ),
                  ],
                ),

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
                      child: const Text('Vendre'),
                      onPressed: CheckIfReadOnly() ? null : () => TriggerSell(widget.prefs),
                    ),

                TextButton(
                      child: action(),
                      onPressed: CheckNotIfReadOnly() ? null : () => TriggerCancel(widget),
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


CheckIfReadOnly(){
  if (widget.data.readonly_flag == false) {return false;}
  else
  {return true;}
}

CheckNotIfReadOnly(){
  if (widget.data.readonly_flag == false) {return true;}
  else
  {return false;}
}
  


Future<String> TriggerSell(prefs) async {
  var check_timer=await CheckTimer(40000);
  if (check_timer=="ok"){
    try{
      final result_step2 = await launchNigEngine(widget.data.requested_nig,widget.data.requester_public_key_hash,widget.data.requester_public_key_hash,"purchase_step2",widget.data.requested_amount,widget.data.timestamp,widget.data.payment_ref,widget.data.requester_public_key_hex,widget.data.requested_nig,"",widget.data.smart_contract_ref);
      print('====result purchase_step2=====');
      print(result_step2.status);

      if (result_step2.status == true) {
              _showDialog("Demande de vente a réussi");
            } else {
              _showDialog("La Demande de vente a échoué");
              _showDialog(result_step2.statusCode);
            };

      }
    catch(e) {
          _showDialog(e.toString());
          _showDialog("La Demande de vente a échoué");
    };
    return "";
  }
  else{
      _showDialog('Merci de patienter: $check_timer (sec)');
    }
  return "";
}

Future<String> TriggerCancel(widget) async {
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
              _showDialog("Demande d'achat annulée");
            } else {
              _showDialog(smart_contract_error_code);
              _showDialog("L'annulation a échoué");
            };

      }
    catch(e) {
          _showDialog(e.toString());
          _showDialog("L'annulation a échoué");
    };
    return "";
  }else{
      _showDialog('Merci de patienter: $check_timer (sec)');
    }
  return "";
  }



  

}