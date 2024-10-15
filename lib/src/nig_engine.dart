import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'package:chaquopy/chaquopy.dart';
import 'account_getactive.dart';

import 'dart:developer';
import 'parameters.dart';
import 'account_file.dart';

import 'package:restart_app/restart_app.dart';
import 'extract_marketplace_request_code.dart';
import 'nig_reputation.dart';



Future <Result> launchNigEngine(var transaction_amount,var requester_public_key_hash,var receiver_public_key_hash,var action, var requested_amount, var requested_gap, var timestamp_nig, var payment_ref, var requester_public_key_hex, var requested_nig, var requested_currency, var smart_contract_ref) async  {
  print('====launchNigEngine=====');
  print(transaction_amount);
  print(requester_public_key_hash);

  // Extraction of the public key
  //final String public_key_response = await rootBundle.loadString('assets/nig_data.json');
  //final public_key_data = await json.decode(public_key_response);
  var public_key_data = await ActiveAccount();
  var sender_public_key_hash=public_key_data["public_key_hash"];
  var sender_public_key_hex=public_key_data["public_key_hex"];
  var private_key=public_key_data["private_key_str"];
  print("check private_key");
  print(private_key);

  // Parameters
  dynamic result_statusCode='200';
  var account_temp_input=null;
  var account_temp_output=null;
  var marketplace_step=0;
  var interface_public_key_hash ="1f8da1bae39c78bf4d8f9f3b8727e50001eed5ae";
  var result_status=true;
  var marketplace_utxo_url=null;
  var smart_contract_previous_transaction=null;
  var smart_contract_transaction_hash=null;
  var marketplace_public_key_hash = "31f2ac8088005412c7b031a6e342b17a65a48d01";
  var payload=null;
  var seller_public_key_hash=null;
  // request management
  var request_type="get";
  var jsonString=null;
  var body=null;
  //specific for Marketplace Step2
  var step1_sell_error=false;
  var step1_buy_error=false;
  var step2_error=null;
  var transaction_data_step2=null;
  var step2_data_init=null;
  var step2_data_counter=0;
  var data_step2=null;
  var step2_data_last=false;
  var step2_transaction_amount=0.0;
  var step2_requested_deposit=0.0;
  var step4_requested_deposit=0.0;
  


  //transfer
  if (action=="transfer"){
    print("*******transfer");
    account_temp_input=false;
    account_temp_output=false;
    marketplace_step=0;
    
  };

   //purchase step1 sell
  if (action=="purchase_step1_sell"){
    print("*******marketplace_step -1");
    account_temp_input=false;
    account_temp_output=true;
    marketplace_step=-1;
    var reputation = await GetReputation();
    //STEP 1-0 Check the amount of NIG in the Wallet
    final public_key_data = await ActiveAccount();
    var public_key=public_key_data["public_key_hash"];
    var response_total = await http.get(Uri.parse(nig_hostname+'/utxo/'+public_key));
    var step1_total= jsonDecode(response_total.body)['total'];
    print("=====step1_total=====");
    print(step1_total);
    
    //STEP 1-2 Check that there is enough NIG in the Wallet
    var marketplace_script1_2="""\r
CONVERT_2_NIG($requested_amount*GET_SELLER_SAFETY_COEF()*(1-$requested_gap/100),datetime.timestamp(datetime.utcnow()),'EUR')
""";
    marketplace_utxo_url=nig_hostname+'/smart_contract_creation';

    body = {
      'smart_contract_public_key_hash': 'dummy_smart_contract_ref_for_step1',
      'sender_public_key_hash': 'dummy_account_public_key_hash_for_step1',
      'payload':marketplace_script1_2,
    };
    jsonString = json.encode(body);
    var marketplace_utxo_response = await http.post(Uri.parse(marketplace_utxo_url), headers: {"Content-Type": "application/json"}, body: jsonString);
    if (marketplace_utxo_response.statusCode == 503 || marketplace_utxo_response.statusCode == 302) {
      //the server is in maintenance
      //let's restart the application
      Restart.restartApp();
    }
    print("*********jsonDecode(marketplace_utxo_response.body)['smart_contract_result']");
    print(jsonDecode(marketplace_utxo_response.body)['smart_contract_result']);
    if (jsonDecode(marketplace_utxo_response.body)['smart_contract_result']!=null){
      var step1_balance=jsonDecode(marketplace_utxo_response.body)['smart_contract_result'].toDouble();
      print('====step1_balance=====');
      print(step1_balance);
      if (step1_balance>step1_total){
        //There is not enough NIG for the seller which is an issue.
        step1_sell_error=true;
      }
    }
    else{
      //The account is not exiting.There is not enough NIG for the seller which is an issue.
      step1_sell_error=true;
    }
  
    if (step1_sell_error==false){
      requester_public_key_hash=sender_public_key_hash;
      receiver_public_key_hash=sender_public_key_hash;

      //STEP 1-2 - creation of a new Smart Contract address
      var response_total_create_smart_contract_account = await http.get(Uri.parse(nig_hostname+'/create_smart_contract_account'));
      smart_contract_ref=jsonDecode(response_total_create_smart_contract_account.body);
      print("smart_contract_ref");
      print(smart_contract_ref);

      //STEP 1-3 - creation of a new Smart Contract
      var marketplace_script1_3=await extract_marketplace_request_code('marketplace_script1_3');
      print("====marketplace_script1_3");
      print(marketplace_script1_3);

      //var response_marketplace_script_code = await http.get(Uri.parse(nig_hostname+'/smart_contract_api/'+MARKETPLACE_CODE_PUBLIC_KEY_HASH));
      //var marketplace_script1_3=jsonDecode(response_marketplace_script_code.body)['smart_contract_payload'];
      
      var seller_reput_reliability=reputation[1];
      if (seller_reput_reliability==0){seller_reput_reliability=0.0;};

      var marketplace_script1_4="""\r
mp_request_step2_done=MarketplaceRequest()
mp_request_step2_done.step1_sell("mp_request_step2_done","$requester_public_key_hash","$requester_public_key_hex",$requested_amount,$requested_gap,"$smart_contract_ref",$reputation[0],$seller_reput_reliability)
memory_list.add([mp_request_step2_done,mp_request_step2_done.mp_request_name,['account','step','timestamp','requested_amount',
  'requested_currency','requested_deposit','buyer_public_key_hash','timestamp_step1_sell','timestamp_step1_buy','timestamp_step15','timestamp_step2','timestamp_step3','timestamp_step4','requested_gap',
  'buyer_public_key_hex','requested_nig','timestamp_nig','recurrency_flag','recurrency_duration','seller_public_key_hex','seller_public_key_hash','encrypted_account','buyer_reput_trans','buyer_reput_reliability','seller_reput_trans','seller_reput_reliability',
  'mp_request_signature','mp_request_id','previous_mp_request_name','mp_request_name','seller_safety_coef','smart_contract_ref','new_user_flag','reputation_buyer','reputation_seller']])
mp_request_step2_done.get_requested_deposit()
""";

      var public_key_data = await ActiveAccount();
      var account_public_key_hex=public_key_data["public_key_hex"];
      var account_public_key_hash=public_key_data["public_key_hash"];

      payload=marketplace_script1_3+marketplace_script1_4;
      marketplace_utxo_url=nig_hostname+'/smart_contract_creation';

      body = {
        'smart_contract_public_key_hash': smart_contract_ref,
        'sender_public_key_hash': account_public_key_hash,
        'payload':payload,
      };
      jsonString = json.encode(body);
      request_type="post";
    }
  };
  
  
   //purchase step1 buy
  if (action=="purchase_step1_buy"){
    print("*******marketplace_step 1");
    account_temp_input=false;
    account_temp_output=true;
    var reputation = await GetReputation();
    print("==>reputation");
    print(reputation);
    var new_user_flag=false;
    if (reputation[0]==0){
      //this account has no Reputation
      //it's a new User
      new_user_flag=true;
      }
    print("==>new_user_flag");
    print(new_user_flag);
    if (new_user_flag == true){
      marketplace_step=0;
      }
    else {
      marketplace_step=1;
      //STEP 1-0 Check the amount of NIG in the Wallet
      final public_key_data = await ActiveAccount();
      var public_key=public_key_data["public_key_hash"];
      var response_total = await http.get(Uri.parse(nig_hostname+'/utxo/'+public_key));
      var step1_total= jsonDecode(response_total.body)['total'];
      print("=====step1_total=====");
      print(step1_total);
      
      //STEP 1-2 Check that there is enough NIG in the Wallet
      var marketplace_script1_2="""\r
CONVERT_2_NIG($requested_amount*GET_BUYER_SAFETY_COEF()*(1-$requested_gap/100),datetime.timestamp(datetime.utcnow()),'EUR')
""";
      marketplace_utxo_url=nig_hostname+'/smart_contract_creation';

      body = {
        'smart_contract_public_key_hash': 'dummy_smart_contract_ref_for_step1',
        'sender_public_key_hash': 'dummy_account_public_key_hash_for_step1',
        'payload':marketplace_script1_2,
      };
      jsonString = json.encode(body);
      var marketplace_utxo_response = await http.post(Uri.parse(marketplace_utxo_url), headers: {"Content-Type": "application/json"}, body: jsonString);
      if (marketplace_utxo_response.statusCode == 503 || marketplace_utxo_response.statusCode == 302) {
        //the server is in maintenance
        //let's restart the application
        Restart.restartApp();
      }
      var step1_requested_deposit=jsonDecode(marketplace_utxo_response.body)['smart_contract_result'].toDouble();
      print('====step1_requested_deposit=====');
      print(step1_requested_deposit);
      if (step1_requested_deposit>step1_total){
        //There is not enough NIG for the deposit of the Buyer which is an issue
        step1_buy_error=true;
      }
    }
    requester_public_key_hash=sender_public_key_hash;
    receiver_public_key_hash=sender_public_key_hash;

    //STEP 1-2 - creation of a new Smart Contract address
    var response_total_create_smart_contract_account = await http.get(Uri.parse(nig_hostname+'/create_smart_contract_account'));
    smart_contract_ref=jsonDecode(response_total_create_smart_contract_account.body);
    print("smart_contract_ref");
    print(smart_contract_ref);

    //STEP 1-3 - creation of a new Smart Contract
    var marketplace_script1_3=await extract_marketplace_request_code('marketplace_script1_3');
    print("====marketplace_script1_3");
    print(marketplace_script1_3);

    //var response_marketplace_script_code = await http.get(Uri.parse(nig_hostname+'/smart_contract_api/'+MARKETPLACE_CODE_PUBLIC_KEY_HASH));
    //var marketplace_script1_3=jsonDecode(response_marketplace_script_code.body)['smart_contract_payload'];

    var marketplace_script1_4="""\r
mp_request_step2_done=MarketplaceRequest()
mp_request_step2_done.step1_buy("mp_request_step2_done","$requester_public_key_hash","$requester_public_key_hex",$requested_amount,$requested_gap,"$smart_contract_ref","$new_user_flag",$reputation[0],$reputation[1])
mp_request_step2_done.account=sender
memory_list.add([mp_request_step2_done,mp_request_step2_done.mp_request_name,['account','step','timestamp','requested_amount',
  'requested_currency','requested_deposit','buyer_public_key_hash','timestamp_step1_sell','timestamp_step1_buy','timestamp_step15','timestamp_step2','timestamp_step3','timestamp_step4','requested_gap',
  'buyer_public_key_hex','requested_nig','timestamp_nig','recurrency_flag','recurrency_duration','seller_public_key_hex','seller_public_key_hash','encrypted_account','buyer_reput_trans','buyer_reput_reliability','seller_reput_trans','seller_reput_reliability',
  'mp_request_signature','mp_request_id','previous_mp_request_name','mp_request_name','seller_safety_coef','smart_contract_ref','new_user_flag','reputation_buyer','reputation_seller']])
mp_request_step2_done.get_requested_deposit()
""";

    var public_key_data = await ActiveAccount();
    var account_public_key_hex=public_key_data["public_key_hex"];
    var account_public_key_hash=public_key_data["public_key_hash"];

    payload=marketplace_script1_3+marketplace_script1_4;
    marketplace_utxo_url=nig_hostname+'/smart_contract_creation';

    body = {
      'smart_contract_public_key_hash': smart_contract_ref,
      'sender_public_key_hash': account_public_key_hash,
      'payload':payload,
    };
    jsonString = json.encode(body);
    request_type="post";

  };
  //purchase step15 
  if (action=="purchase_step15"){
    print("*******marketplace_step 15");
    account_temp_input=false;
    account_temp_output=true;
    var reputation = await GetReputation();
    print("==>reputation");
    print(reputation);
    var new_user_flag=false;
    if (reputation[0]==0){
      //this account has no Reputation
      //it's a new User
      new_user_flag=true;
      transaction_amount=0;
      }
    print("==>new_user_flag");
    print(new_user_flag);
    if (new_user_flag == true){
      marketplace_step=150;
      }
    else {
      marketplace_step=15;
      //STEP 1-0 Check the amount of NIG in the Wallet
      final public_key_data = await ActiveAccount();
      var public_key=public_key_data["public_key_hash"];
      var response_total = await http.get(Uri.parse(nig_hostname+'/utxo/'+public_key));
      var step1_total= jsonDecode(response_total.body)['total'];
      print("=====step1_total=====");
      print(step1_total);
      
      //STEP 1-2 Check that there is enough NIG in the Wallet
      var marketplace_script1_2="""\r
CONVERT_2_NIG($requested_amount*GET_BUYER_SAFETY_COEF()*(1-$requested_gap/100),datetime.timestamp(datetime.utcnow()),'EUR')
""";
      marketplace_utxo_url=nig_hostname+'/smart_contract_creation';

      body = {
        'smart_contract_public_key_hash': 'dummy_smart_contract_ref_for_step1',
        'sender_public_key_hash': 'dummy_account_public_key_hash_for_step1',
        'payload':marketplace_script1_2,
      };
      jsonString = json.encode(body);
      var marketplace_utxo_response = await http.post(Uri.parse(marketplace_utxo_url), headers: {"Content-Type": "application/json"}, body: jsonString);
      if (marketplace_utxo_response.statusCode == 503 || marketplace_utxo_response.statusCode == 302) {
        //the server is in maintenance
        //let's restart the application
        Restart.restartApp();
      }
      var step1_requested_deposit=jsonDecode(marketplace_utxo_response.body)['smart_contract_result'].toDouble();
      print('====step1_requested_deposit=====');
      print(step1_requested_deposit);
      if (step1_requested_deposit>step1_total){
        //There is not enough NIG for the deposit of the Buyer which is an issue
        step1_buy_error=true;
      }
    }
    requester_public_key_hash=sender_public_key_hash;
    requester_public_key_hex=sender_public_key_hex;
    
    // Extraction of Smart Contract details
    //STEP 1-3 - retrieval of request information to make signature
    var marketplace_api_utxo_url=null;
    marketplace_api_utxo_url=nig_hostname+'/smart_contract_api/'+smart_contract_ref;
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
    
    var buyer_reput_reliability=reputation[1];
    if (buyer_reput_reliability==0){buyer_reput_reliability=0.0;};

    var marketplace_script1_4="""\r
memory_obj_2_load=['mp_request_step2_done']
mp_request_step2_done.step15("$requester_public_key_hash","$requester_public_key_hex",$requested_amount,$requested_gap,"$smart_contract_ref","$new_user_flag",$reputation[0],$buyer_reput_reliability)
mp_request_step2_done.account=sender
memory_list.add([mp_request_step2_done,mp_request_step2_done.mp_request_name,['account','step','timestamp','requested_amount',
  'requested_currency','requested_deposit','buyer_public_key_hash','timestamp_step1_sell','timestamp_step1_buy','timestamp_step15','timestamp_step2','timestamp_step3','timestamp_step4','requested_gap',
  'buyer_public_key_hex','requested_nig','timestamp_nig','recurrency_flag','recurrency_duration','seller_public_key_hex','seller_public_key_hash','encrypted_account','buyer_reput_trans','buyer_reput_reliability','seller_reput_trans','seller_reput_reliability',
  'mp_request_signature','mp_request_id','previous_mp_request_name','mp_request_name','seller_safety_coef','smart_contract_ref','new_user_flag','reputation_buyer','reputation_seller']])
mp_request_step2_done.get_requested_deposit()
""";

    payload=marketplace_script1_4;
    body = {
      'smart_contract_type': 'source',
      'smart_contract_public_key_hash': smart_contract_ref,
      'sender_public_key_hash': requester_public_key_hash,
      'smart_contract_transaction_hash': smart_contract_transaction_hash,
      'smart_contract_previous_transaction': smart_contract_transaction_hash,
      'payload':payload,
    };
    jsonString = json.encode(body);
    request_type="post";
    marketplace_utxo_url=nig_hostname+'/smart_contract';

  };


   //purchase step2
  if (action=="purchase_step2"){
    print("*******marketplace_step 2");
    account_temp_input=false;
    account_temp_output=true;
    marketplace_step=2;
    //requester_public_key_hash=sender_public_key_hash;


    // Extraction of Smart Contract details
    //STEP 2-1 - retrieval of request information to make signature
    var marketplace_api_utxo_url=null;
    marketplace_api_utxo_url=nig_hostname+'/smart_contract_api/'+smart_contract_ref;
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

  if (smart_contract_total!="null"){
    var marketplace_script2_0="""\r
memory_obj_2_load=['mp_request_step2_done']
mp_request_step2_done.get_requested_deposit()
""";
    print('====marketplace_script2_0=====');
    body = {
      'smart_contract_type': 'source',
      'smart_contract_public_key_hash': smart_contract_ref,
      'sender_public_key_hash': requester_public_key_hash,
      'smart_contract_transaction_hash': smart_contract_transaction_hash,
      'smart_contract_previous_transaction': smart_contract_transaction_hash,
      'payload':marketplace_script2_0,
    };
    jsonString = json.encode(body);
    marketplace_utxo_url=nig_hostname+'/smart_contract';
    var marketplace_utxo_response = await http.post(Uri.parse(marketplace_utxo_url), headers: {"Content-Type": "application/json"}, body: jsonString);
    if (marketplace_utxo_response.statusCode == 503 || marketplace_utxo_response.statusCode == 302) {
      //the server is in maintenance
      //let's restart the application
      Restart.restartApp();
    }
    step2_requested_deposit=jsonDecode(marketplace_utxo_response.body)['smart_contract_result'].toDouble();
    print('====requested_deposit=====');
    print(step2_requested_deposit);

    var marketplace_script2_1="""\r
memory_obj_2_load=['mp_request_step2_done']
mp_request_step2_done.get_mp_details(2)
""";
    print('====marketplace_script2_1=====');
    print(marketplace_script2_1);
    body = {
      'smart_contract_type': 'source',
      'smart_contract_public_key_hash': smart_contract_ref,
      'sender_public_key_hash': requester_public_key_hash,
      'smart_contract_transaction_hash': smart_contract_transaction_hash,
      'smart_contract_previous_transaction': smart_contract_transaction_hash,
      'payload':marketplace_script2_1,
    };
    jsonString = json.encode(body);
    var payload=marketplace_script2_1;
    marketplace_utxo_url=nig_hostname+'/smart_contract';
    marketplace_utxo_response = await http.post(Uri.parse(marketplace_utxo_url), headers: {"Content-Type": "application/json"}, body: jsonString);
    if (marketplace_utxo_response.statusCode == 503 || marketplace_utxo_response.statusCode == 302) {
      //the server is in maintenance
      //let's restart the application
      Restart.restartApp();
    }
    
    var mp_details=jsonDecode(marketplace_utxo_response.body)['smart_contract_result'];
    //seller_safety_coef management
    //transaction_amount=mp_details[5]*mp_details[6];
    transaction_amount=transaction_amount*mp_details[6];
    step2_transaction_amount=transaction_amount;
    
    //STEP 2-2 - encryption of account
    var controller = await rootBundle.loadString('assets/nig_decrypt.py');
    var account_private_key = await GetAccountPrivateKey();
    var param = "action_raw="""+json.encode("account_encryption")+"""\r"""+
    "account_raw="""+json.encode("")+"""\r"""+
    "pin_encrypted_raw="""+json.encode("")+"""\r"""+
    "account_private_key_raw="""+json.encode(account_private_key)+"""\r"""+
    "requester_public_key_hex_raw="""+json.encode(requester_public_key_hex)+"""\r"""+
    "mp_details_raw="""+json.encode("")+"""\r""";

   
    print('====param=====');
    var param1=param.replaceAll('false', "False");
    var param2=param1.replaceAll('null', "None");
    var param3=param2.replaceAll('true', "True");
    print(param3);
    var transaction_data = await Chaquopy.executeCode(param3+controller);
    print('====transaction_data=====');
    debugPrint(transaction_data['textOutputOrError']);
    Map account = jsonDecode(transaction_data['textOutputOrError']);
    var encrypted_account=account['encrypted_account'];

    //STEP 2-3 - signature generation
    var public_key_data = await ActiveAccount();
    var account_public_key_hex=public_key_data["public_key_hex"];
    var account_public_key_hash=public_key_data["public_key_hash"];
    mp_details.add(account_public_key_hex);
    mp_details.add(account_public_key_hash);
    print('====requested_deposit2=====');
    print(step2_requested_deposit);
    if (step2_requested_deposit==0){
      log("===>test1");
      print(step2_requested_deposit);
      mp_details.add(0);
    }
    else{
      log("===>test2");
      mp_details.add(step2_requested_deposit);
    }
    
    
    print('====mp_details=====');
    print(json.encode(mp_details));

    var controller2 = await rootBundle.loadString('assets/nig_decrypt.py');
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
    //var requested_nig=account2['mp_details'][2];
    print('====mp_request_signature=====');
    print(mp_request_signature);
    print('====mp_details2=====');
    log(account2['mp_details']);


    print('====requested_nig=====');
    print(requested_nig);


    
    var data0=mp_details[0];
    var data1=mp_details[1];
    var data2=mp_details[2];
    var data3=mp_details[3];
    var data4=mp_details[4];
    var data5=mp_details[5];
    var data6=mp_details[6];
    var marketplace_script2_3="""\r
memory_obj_2_load=['mp_request_step2_done']
mp_request_step2_done.step2("$account_public_key_hash","$account_public_key_hex","$encrypted_account","$mp_request_signature")
mp_request_step2_done.validate_step()
memory_list.add([mp_request_step2_done,mp_request_step2_done.mp_request_name,['account','step','timestamp','requested_amount',
  'requested_currency','requested_deposit','buyer_public_key_hash','timestamp_step1_sell','timestamp_step1_buy','timestamp_step15','timestamp_step2','timestamp_step3','timestamp_step4','requested_gap',
  'buyer_public_key_hex','requested_nig','timestamp_nig','recurrency_flag','recurrency_duration','seller_public_key_hex','seller_public_key_hash','encrypted_account','buyer_reput_trans','buyer_reput_reliability','seller_reput_trans','seller_reput_reliability',
  'mp_request_signature','mp_request_id','previous_mp_request_name','mp_request_name','seller_safety_coef','smart_contract_ref','new_user_flag','reputation_buyer','reputation_seller']])
123456
""";

    payload=marketplace_script2_3;
    body = {
      'smart_contract_type': 'source',
      'smart_contract_public_key_hash': smart_contract_ref,
      'sender_public_key_hash': requester_public_key_hash,
      'smart_contract_transaction_hash': smart_contract_transaction_hash,
      'smart_contract_previous_transaction': smart_contract_transaction_hash,
      'payload':payload,
    };
    jsonString = json.encode(body);
    request_type="post";
    marketplace_utxo_url=nig_hostname+'/smart_contract';
  }
  else{
    step2_error=true;}
    ;
  };



  //purchase step3
  if (action=="purchase_step3"){
    print("*******marketplace_step 3");
    account_temp_input=true;
    account_temp_output=true;
    marketplace_step=3;
    //requester_public_key_hash=sender_public_key_hash;

    // Extraction of Smart Contract details
    //STEP 3-2 - retrieval of request information to make signature
    var marketplace_api_utxo_url=null;
    marketplace_api_utxo_url=nig_hostname+'/smart_contract_api/'+smart_contract_ref;
    var marketplace_api_utxo_response = await http.get(Uri.parse(marketplace_api_utxo_url));
    if (marketplace_api_utxo_response.statusCode == 503 || marketplace_api_utxo_response.statusCode == 302) {
      //the server is in maintenance
      //let's restart the application
      Restart.restartApp();
    }
    var marketplace_api_utxo_json=jsonDecode(marketplace_api_utxo_response.body);
    var smart_contract_previous_transaction=marketplace_api_utxo_json['smart_contract_previous_transaction'];
    var smart_contract_transaction_hash=marketplace_api_utxo_json['smart_contract_transaction_hash'];

    var marketplace_script3_1="""\r
memory_obj_2_load=['mp_request_step2_done']
mp_request_step2_done.get_mp_details(3)
""";
    print('====marketplace_script3_1=====');
    print(marketplace_script3_1);
    var payload=marketplace_script3_1;
    body = {
      'smart_contract_type': 'source',
      'smart_contract_public_key_hash': smart_contract_ref,
      'sender_public_key_hash': requester_public_key_hash,
      'smart_contract_transaction_hash': smart_contract_transaction_hash,
      'smart_contract_previous_transaction': smart_contract_transaction_hash,
      'payload':payload,
    };
    jsonString = json.encode(body);

    marketplace_utxo_url=nig_hostname+'/smart_contract';
    var marketplace_utxo_response = await http.post(Uri.parse(marketplace_utxo_url),headers: {"Content-Type": "application/json"}, body: jsonString);
    if (marketplace_utxo_response.statusCode == 503 || marketplace_utxo_response.statusCode == 302) {
      //the server is in maintenance
      //let's restart the application
      Restart.restartApp();
    }
    var mp_details=jsonDecode(marketplace_utxo_response.body)['smart_contract_result'];
    //seller_safety_coef management
    transaction_amount=mp_details[5]*mp_details[6];


    //STEP 3-3 - signature generation
    var account_private_key = await GetAccountPrivateKey();
    
    print('====mp_details=====');
    print(json.encode(mp_details));

    var controller2 = await rootBundle.loadString('assets/nig_decrypt.py');
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
    print('====mp_request_signature=====');
    print(mp_request_signature);
    print('====mp_details2=====');
    print(account2['mp_details']);

    var marketplace_script3_2="""\r
memory_obj_2_load=['mp_request_step2_done']
mp_request_step2_done.step3("$mp_request_signature")
mp_request_step2_done.validate_step()
memory_list.add([mp_request_step2_done,mp_request_step2_done.mp_request_name,['account','step','timestamp','requested_amount',
  'requested_currency','requested_deposit','buyer_public_key_hash','timestamp_step1_sell','timestamp_step1_buy','timestamp_step15','timestamp_step2','timestamp_step3','timestamp_step4','requested_gap',
  'buyer_public_key_hex','requested_nig','timestamp_nig','recurrency_flag','recurrency_duration','seller_public_key_hex','seller_public_key_hash','encrypted_account','buyer_reput_trans','buyer_reput_reliability','seller_reput_trans','seller_reput_reliability',
  'mp_request_signature','mp_request_id','previous_mp_request_name','mp_request_name','seller_safety_coef','smart_contract_ref','new_user_flag','reputation_buyer','reputation_seller']])
123456
""";

    payload=marketplace_script3_2;
    body = {
      'smart_contract_type': 'source',
      'smart_contract_public_key_hash': smart_contract_ref,
      'sender_public_key_hash': requester_public_key_hash,
      'smart_contract_transaction_hash': smart_contract_transaction_hash,
      'smart_contract_previous_transaction': smart_contract_transaction_hash,
      'payload':payload,
    };
    jsonString = json.encode(body);
    request_type="post";
    marketplace_utxo_url=nig_hostname+'/smart_contract';



  };
  //purchase step4
  if (action=="purchase_step4" || action=="purchase_step45"){
    print("*******marketplace_step 4 ou 45");
    marketplace_step=4;
    account_temp_input=true;
    account_temp_output=false;
    //requester_public_key_hash=sender_public_key_hash;
    
    // Extraction of Smart Contract details
    var marketplace_api_utxo_url=null;
    marketplace_api_utxo_url=nig_hostname+'/smart_contract_api/'+smart_contract_ref;
    var marketplace_api_utxo_response = await http.get(Uri.parse(marketplace_api_utxo_url));
    if (marketplace_api_utxo_response.statusCode == 503 || marketplace_api_utxo_response.statusCode == 302) {
      //the server is in maintenance
      //let's restart the application
      Restart.restartApp();
    }
    var marketplace_api_utxo_json=jsonDecode(marketplace_api_utxo_response.body);
    var smart_contract_previous_transaction=marketplace_api_utxo_json['smart_contract_previous_transaction'];
    var smart_contract_transaction_hash=marketplace_api_utxo_json['smart_contract_transaction_hash'];

    //STEP 4-1 - retrieval of request information to make signature
    var marketplace_script4_1="""\r
memory_obj_2_load=['mp_request_step2_done']
mp_request_step2_done.get_mp_details(4)
""";
    print('====marketplace_script4_1=====');
    print(marketplace_script4_1);
    var payload=marketplace_script4_1;
    body = {
      'smart_contract_type': 'source',
      'smart_contract_public_key_hash': smart_contract_ref,
      'sender_public_key_hash': requester_public_key_hash,
      'smart_contract_transaction_hash': smart_contract_transaction_hash,
      'smart_contract_previous_transaction': smart_contract_transaction_hash,
      'payload':payload,
    };
    jsonString = json.encode(body);
    marketplace_utxo_url=nig_hostname+'/smart_contract';
    var marketplace_utxo_response = await http.post(Uri.parse(marketplace_utxo_url),headers: {"Content-Type": "application/json"}, body: jsonString);
    if (marketplace_utxo_response.statusCode == 503 || marketplace_utxo_response.statusCode == 302) {
      //the server is in maintenance
      //let's restart the application
      Restart.restartApp();
    }
    var mp_details=jsonDecode(marketplace_utxo_response.body)['smart_contract_result'];
    //seller_safety_coef management
    transaction_amount=mp_details[5]*mp_details[6];
    seller_public_key_hash=mp_details[8];
    step4_requested_deposit=mp_details[9].toDouble();

    //STEP 4-2 - check if the buyer is a new user
    var marketplace_script4_2="""\r
memory_obj_2_load=['mp_request_step2_done']
mp_request_step2_done.get_new_user_flag()
""";
        print('====marketplace_script2_0=====');
        body = {
          'smart_contract_type': 'api',
          'smart_contract_public_key_hash': smart_contract_ref,
          'sender_public_key_hash': requester_public_key_hash,
          'payload':marketplace_script4_2,
        };
        jsonString = json.encode(body);
        marketplace_utxo_url=nig_hostname+'/smart_contract';
        marketplace_utxo_response = await http.post(Uri.parse(marketplace_utxo_url), headers: {"Content-Type": "application/json"}, body: jsonString);
        if (marketplace_utxo_response.statusCode == 503 || marketplace_utxo_response.statusCode == 302) {
          //the server is in maintenance
          //let's restart the application
          Restart.restartApp();
        }
        var new_user_flag=jsonDecode(marketplace_utxo_response.body)['smart_contract_result'];
        print('====new_user_flag=====');
        print(new_user_flag);

        if (new_user_flag=="True" || new_user_flag=="true" || new_user_flag== true){
          step4_requested_deposit=0.0;
          }


    //STEP 4-3 - signature generation
    var account_private_key = await GetAccountPrivateKey();
    
    print('====mp_details=====');
    print(json.encode(mp_details));

    var controller2 = await rootBundle.loadString('assets/nig_decrypt.py');
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
    print('====mp_request_signature=====');
    print(mp_request_signature);
    print('====mp_details2=====');
    print(account2['mp_details']);

    var marketplace_script4_3="";
    if (action=="purchase_step4"){
      marketplace_script4_3="""\r
memory_obj_2_load=['mp_request_step2_done']
mp_request_step2_done.step4("$mp_request_signature")
mp_request_step2_done.validate_step()
memory_list.add([mp_request_step2_done,mp_request_step2_done.mp_request_name,['account','step','timestamp','requested_amount',
  'requested_currency','requested_deposit','buyer_public_key_hash','timestamp_step1_sell','timestamp_step1_buy','timestamp_step15','timestamp_step2','timestamp_step3','timestamp_step4','requested_gap',
  'buyer_public_key_hex','requested_nig','timestamp_nig','recurrency_flag','recurrency_duration','seller_public_key_hex','seller_public_key_hash','encrypted_account','buyer_reput_trans','buyer_reput_reliability','seller_reput_trans','seller_reput_reliability',
  'mp_request_signature','mp_request_id','previous_mp_request_name','mp_request_name','seller_safety_coef','smart_contract_ref','new_user_flag','reputation_buyer','reputation_seller']])

123456
""";
    }
    if (action=="purchase_step45"){
      marketplace_script4_3="""\r
memory_obj_2_load=['mp_request_step2_done']
mp_request_step2_done.step45("$mp_request_signature")
mp_request_step2_done.validate_step()
memory_list.add([mp_request_step2_done,mp_request_step2_done.mp_request_name,['account','step','timestamp','requested_amount',
  'requested_currency','requested_deposit','buyer_public_key_hash','timestamp_step1_sell','timestamp_step1_buy','timestamp_step15','timestamp_step2','timestamp_step3','timestamp_step4','requested_gap',
  'buyer_public_key_hex','requested_nig','timestamp_nig','recurrency_flag','recurrency_duration','seller_public_key_hex','seller_public_key_hash','encrypted_account','buyer_reput_trans','buyer_reput_reliability','seller_reput_trans','seller_reput_reliability',
  'mp_request_signature','mp_request_id','previous_mp_request_name','mp_request_name','seller_safety_coef','smart_contract_ref','new_user_flag','reputation_buyer','reputation_seller']])

123456
""";
    }


    
    payload=marketplace_script4_3;
    body = {
      'smart_contract_type': 'source',
      'smart_contract_public_key_hash': smart_contract_ref,
      'sender_public_key_hash': requester_public_key_hash,
      'smart_contract_transaction_hash': smart_contract_transaction_hash,
      'smart_contract_previous_transaction': smart_contract_transaction_hash,
      'payload':payload,
    };
    jsonString = json.encode(body);
    request_type="post";
    marketplace_utxo_url=nig_hostname+'/smart_contract';

    
  };


  if (step1_buy_error!=true && step2_error!=true && step1_sell_error!=true ){
  var smart_contract_account=null;
  var smart_contract_sender=null;
  var smart_contract_new=false;
  var smart_contract_flag=null;
  var smart_contract_gas=null;
  var smart_contract_memory=null;
  var smart_contract_memory_size=null;
  var smart_contract_type=null;
  var smart_contract_payload=null;
  var smart_contract_result=null;
  
 
  // Extraction of the utxo
  var utxo_url=null;
  if (action!="transfer"){
    var marketplace_utxo_response=null;
    if (request_type=="post"){
      print("===body2");
      print(jsonString);
      marketplace_utxo_response = await http.post(Uri.parse(marketplace_utxo_url),headers: {"Content-Type": "application/json"}, body: jsonString);
      if (marketplace_utxo_response.statusCode == 503 || marketplace_utxo_response.statusCode == 302) {
        //the server is in maintenance
        //let's restart the application
        Restart.restartApp();
      }
    }
    else{
      marketplace_utxo_response = await http.get(Uri.parse(marketplace_utxo_url));
      if (marketplace_utxo_response.statusCode == 503 || marketplace_utxo_response.statusCode == 302) {
        //the server is in maintenance
        //let's restart the application
        Restart.restartApp();
      }
    };
    print('=>>marketplace_utxo_response');
    print(marketplace_utxo_url);
    print(marketplace_utxo_response.body);
    
    var marketplace_utxo_json=jsonDecode(marketplace_utxo_response.body);

    var smart_contract_error_flag=marketplace_utxo_json['smart_contract_error_flag'];

    print("===smart_contract_error_flag");
    print(smart_contract_error_flag);

    if (smart_contract_error_flag==true){
      //there is an error when processing the SmartContract
      result_status=false;
      result_statusCode=marketplace_utxo_json['smart_contract_error_code'];
      return Result(status: result_status, statusCode: result_statusCode);
    }
    else{
      print("*******smart_contract_new");
    print(marketplace_utxo_json['smart_contract_new']);
    print("*******marketplace_utxo_json");

    print(marketplace_utxo_json);
    smart_contract_account=marketplace_utxo_json['smart_contract_account'];
    smart_contract_sender=marketplace_utxo_json['smart_contract_sender'];
    smart_contract_new=marketplace_utxo_json['smart_contract_new'];
    smart_contract_flag=marketplace_utxo_json['smart_contract_flag'];;
    smart_contract_gas=marketplace_utxo_json['smart_contract_gas'];
    smart_contract_memory=marketplace_utxo_json['smart_contract_memory'];
    smart_contract_memory_size=marketplace_utxo_json['smart_contract_memory_size'];
    smart_contract_type=marketplace_utxo_json['smart_contract_type'];
    smart_contract_payload=marketplace_utxo_json['smart_contract_payload'];
    smart_contract_result=marketplace_utxo_json['smart_contract_result'];
    smart_contract_previous_transaction=marketplace_utxo_json['smart_contract_previous_transaction'];
    smart_contract_transaction_hash=marketplace_utxo_json['smart_contract_transaction_hash'];
    
    if(marketplace_step==0 || marketplace_step==-1){
      utxo_url=nig_hostname+'/utxo/'+marketplace_public_key_hash;
      print("==check marketplace_step -1 or 0");
    }
    else {
      if(marketplace_step==2 || marketplace_step == 1 || marketplace_step == 15){
        var public_key_data = await ActiveAccount();
        var account_public_key_hash=public_key_data["public_key_hash"];
        utxo_url=nig_hostname+'/utxo/'+account_public_key_hash;
        print("==check marketplace_step 1 or 15 or 2");
        print(utxo_url);
      }
      else {
          utxo_url=nig_hostname+'/utxo/'+smart_contract_ref;
          print("==check marketplace_step 3 or 4");
        }
      }
    };

  }else{
    utxo_url=nig_hostname+'/utxo/'+sender_public_key_hash;
    print("==Nig Transfer");
  };

  var utxo_json=null;
  print("======utxo_url======");
  print(utxo_url);
  var utxo_response = await http.get(Uri.parse(utxo_url));
  if (utxo_response.statusCode == 503 || utxo_response.statusCode == 302) {
      //the server is in maintenance
      //let's restart the application
      Restart.restartApp();
    }
  utxo_json=jsonDecode(utxo_response.body);
  print('====utxo_response=====');
  print(utxo_json.toString());
  print(utxo_json.values);
  print("======utxo_json======");
  print(utxo_json);

  

  //specific process for Marketplace step 15 & 2 to ensure continuity in the marketplace blockchain
  var utxo_json_marketplace=null;
  if(marketplace_step == 15 || marketplace_step==2){
    var utxo_response_marketplace = await http.get(Uri.parse(nig_hostname+'/utxo/'+smart_contract_ref));
    if (utxo_response_marketplace.statusCode == 503 || utxo_response_marketplace.statusCode == 302) {
      //the server is in maintenance
      //let's restart the application
      Restart.restartApp();
    }
    utxo_json_marketplace=jsonDecode(utxo_response_marketplace.body);
    print("=========utxo_json_marketplace============");
    print(utxo_json_marketplace);
  };

  var param='';
  print("utxo_json['total']");
  print(utxo_json['total']);
  print("transaction_amount");
  print(transaction_amount);
  if (transaction_amount>utxo_json['total'] && (marketplace_step==2 || action=="transfer") ){
    //transaction amount is exceeding wallet total except for marketplace_step3 where only the payment is made outside of NIG
    print("error => transaction amount is exceeding wallet total");
    print("transaction_amount");
    print(transaction_amount);
    print(utxo_json['total']);
    result_status=false;
    result_statusCode = "transaction amount is exceeding wallet total";
    
  } else {
    //wallet total is exceeding transaction amount
    
    //only utxo['total']>0 needs to be considered after marketplace_step 2
    //to avoid having duplicate record on the SmartContract 
    //as the Transaction with marketplace_step 2 is not linked to the previous transaction in the Smart Contract

    //construction of the transaction
    var controller = await rootBundle.loadString('assets/nig_script.py');

    //Buyer deposit management
    var requested_deposit_raw = 0.0;
    if(marketplace_step==1 || marketplace_step==15){
      transaction_amount= smart_contract_result;
    }
    else if (marketplace_step==2){
      requested_deposit_raw=step2_requested_deposit;}
    
    else if (marketplace_step==4){
      requested_deposit_raw=step4_requested_deposit;
    }
    
    print("======requested_deposit_raw======");
    print(requested_deposit_raw);

    
    param = "action_raw="""+json.encode(action)+"""\r"""+
    "transaction_amount_raw="""+json.encode(transaction_amount)+"""\r"""+
    "account_temp_input_raw="""+json.encode(account_temp_input)+"""\r"""+
    "account_temp_output_raw="""+json.encode(account_temp_output)+"""\r"""+
    "marketplace_step_raw="""+json.encode(marketplace_step)+"""\r"""+
    "interface_public_key_hash_raw="""+json.encode(interface_public_key_hash)+"""\r"""+
    "receiver_public_key_hash_raw="""+json.encode(receiver_public_key_hash)+"""\r"""+
    "requester_public_key_hash_raw="""+json.encode(requester_public_key_hash)+"""\r"""+
    "requester_public_key_hex_raw="""+json.encode(requester_public_key_hex)+"""\r"""+

    
    "requested_amount_raw="""+json.encode(requested_amount)+"""\r"""+
    "timestamp_nig_raw="""+json.encode(timestamp_nig)+"""\r"""+
    "payment_ref_raw="""+json.encode(payment_ref)+"""\r"""+
    "requested_nig_raw="""+json.encode(requested_nig)+"""\r"""+
    "requested_currency_raw="""+json.encode(requested_currency)+"""\r"""+
    "requested_deposit_raw="""+json.encode(requested_deposit_raw)+"""\r"""+
    "private_key_raw="""+json.encode(private_key)+"""\r"""+
    "utxo_json_raw="""+json.encode(utxo_json['utxos'])+"""\r"""+
    "utxo_json_marketplace_raw="""+json.encode(utxo_json_marketplace)+"""\r"""+


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

    "seller_public_key_hash_raw="""+json.encode(seller_public_key_hash)+"""\r"""+

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
    transaction_amount = data['transaction_amount'];

    
    //test to POST a transaction
    var url =nig_hostname+'/transactions';
    //encode Map to JSON
    data.removeWhere((key, value) => key == "transaction_amount");
    print("===check transaction_amount===");
    print(transaction_amount);
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
    print('====response1=====');
    log(response_post.statusCode.toString());
    print('====response2=====');
    print("${response_post.statusCode}");
    print("${response_post.body}");
    if (response_post.statusCode == 200) {
      // If the server did return a 200 OK response,
      // then parse the JSON.
      result_status=true;
      if (action=="purchase_step4" || action=="purchase_step45" || action=="transfer"){
        //refresh the score of the requester and receiver
        //var requester_refresh_url=nig_hostname+'/participant_refresh_score/'+requester_public_key_hash;
        //await http.get(Uri.parse(requester_refresh_url));
        //var receiver_refresh_url=nig_hostname+'/participant_refresh_score/'+receiver_public_key_hash;
        //await http.get(Uri.parse(receiver_refresh_url));
      };
      if (action=="purchase_step4" || action=="purchase_step45"){
        //refresh the reputation of the requester and receiver
        //var requester_refresh_url=nig_hostname+'/refresh_reputation/'+requester_public_key_hash;
        //await http.get(Uri.parse(requester_refresh_url));
        //var receiver_refresh_url=nig_hostname+'/refresh_reputation/'+receiver_public_key_hash;
        //await http.get(Uri.parse(receiver_refresh_url));
      };
      
    } 
    else if (response_post.statusCode == 503 || response_post.statusCode == 302) {
      //the server is in maintenance
      //let's restart the application
      Restart.restartApp();
    }
    else {
      // If the server did not return a 200 OK response,
      // then throw an exception.
      //throw Exception('Failed to load Account');
      result_status=false;
      result_statusCode = response_post.statusCode;
      
    }
    if (transaction_amount == 0){
      print("=====bingo break ");
      
    }else{
      print("=====bingo check ");
      print(transaction_amount);
    }    


  };
}else{
  result_status=false;
  if (step1_sell_error==true){
  result_statusCode = "Pas assez de NIG sur le compte !";
  }
  if (step1_buy_error==true){
  result_statusCode = "Pas assez de NIG pour la caution !";
  }
  if (step2_error==true){
  result_statusCode = "Déjà vendu!";
  }
};
  
  return Result(status: result_status, statusCode: result_statusCode);
}

class Result {
  final bool status;
  final String statusCode;

  const Result({
    required this.status,
    required this.statusCode,
  });
   factory Result.fromJson(Map<String, dynamic> json) {
    return Result(
      status: json['status'],
      statusCode: json['statusCode'],
    );
  }


}
