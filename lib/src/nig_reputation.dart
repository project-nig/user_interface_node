import 'dart:convert';
import 'package:http/http.dart' as http;
import 'account_getactive.dart';
import 'package:restart_app/restart_app.dart';
import 'parameters.dart';
import 'package:chaquopy/chaquopy.dart';
import 'package:flutter/services.dart';
import 'extract_marketplace_request_code.dart';
import 'account_file.dart';




Future<String> GetReputationAccount() async{

  var account_public_key_data = await ActiveAccount();
  var account_public_key_hash=account_public_key_data["public_key_hash"];
  var account_api_utxo_url=nig_hostname+'/utxo/'+account_public_key_hash;
  var account_api_utxo_response = await http.get(Uri.parse(account_api_utxo_url));
  if (account_api_utxo_response.statusCode == 503 || account_api_utxo_response.statusCode == 302) {
    //the server is in maintenance
    //let's restart the application
    Restart.restartApp();
  }
  var account_api_utxo_json=jsonDecode(account_api_utxo_response.body);
  var reputation_public_key_hash=account_api_utxo_json['reputation'];
  print("===>reputation_public_key_hash");
  print(reputation_public_key_hash);
  if (reputation_public_key_hash.toString()=="[]"){
    //the Reputation SmartContract needs to be created
    CreateReputationAccount();
  }
  return reputation_public_key_hash.toString();
}

Future<List> GetReputation() async{
  List reputation_value=[0,0];
  var reputation_public_key_hash = await GetReputationAccount();
  if (reputation_public_key_hash=="[]") {
    return reputation_value;
  }
  else {
    var payload="""\r
memory_obj_2_load=['reputation']
reputation.get_reputation()
""";

    var body = {
        'smart_contract_type': 'api',
        'smart_contract_public_key_hash': reputation_public_key_hash,
        'sender_public_key_hash': 'sender_public_key_hash',
        'payload':payload,
      };
    var jsonString = json.encode(body);
    var reputation_url=nig_hostname+'/smart_contract';
    var reputation_response = await http.post(Uri.parse(reputation_url),headers: {"Content-Type": "application/json"}, body: jsonString);
    if (reputation_response.statusCode == 503 || reputation_response.statusCode == 302) {
      //the server is in maintenance
      //let's restart the application
      Restart.restartApp();
    }  
    reputation_value=jsonDecode(reputation_response.body)['smart_contract_result'];
    return reputation_value;
  }
}

Future<String> CreateReputationAccount() async{
  //STEP 1 creation of a new Smart Contract address
  var response_total_create_smart_contract_account = await http.get(Uri.parse(nig_hostname+'/create_smart_contract_account'));
  var smart_contract_ref=jsonDecode(response_total_create_smart_contract_account.body);
  print("smart_contract_ref");
  print(smart_contract_ref);


  var account_private_key = await GetAccountPrivateKey();

  var reputation_script=await extract_marketplace_request_code('reputation_script');
  print("====>reputation_script");
  print(reputation_script);
  var marketplace_utxo_url=nig_hostname+'/smart_contract_creation';
  var body = {
    'smart_contract_public_key_hash': smart_contract_ref,
    'sender_public_key_hash': 'sender_public_key_hash',
    'payload':reputation_script,
  };
  var jsonString = json.encode(body);
  print('====jsonString=====');
  print(jsonString);

  var marketplace_utxo_response = await http.post(Uri.parse(marketplace_utxo_url),headers: {"Content-Type": "application/json"}, body: jsonString);
  if (marketplace_utxo_response.statusCode == 503 || marketplace_utxo_response.statusCode == 302) {
    //the server is in maintenance
    //let's restart the application
    Restart.restartApp();
  }
  var marketplace_utxo_json=jsonDecode(marketplace_utxo_response.body);
  //print("*******smart_contract_new");
  //print(marketplace_utxo_json['smart_contract_new']);
  //print("*******marketplace_utxo_json");

  //print(marketplace_utxo_json);
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
  var action = "reputation_creation";
  var controller = await rootBundle.loadString('assets/nig_script.py');
  var account_temp_input=false;
  var account_temp_output="reputation_creation";
  var interface_public_key_hash ="1f8da1bae39c78bf4d8f9f3b8727e50001eed5ae";
  
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
  "requested_amount_raw="""+json.encode("")+"""\r"""+
  "timestamp_nig_raw="""+json.encode("")+"""\r"""+
  "payment_ref_raw="""+json.encode("")+"""\r"""+
  "requested_nig_raw="""+json.encode("")+"""\r"""+
  "requested_currency_raw="""+json.encode("")+"""\r"""+
  "private_key_raw="""+json.encode(account_private_key)+"""\r"""+
  "utxo_json_raw="""+json.encode("")+"""\r"""+
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
  "smart_contract_transaction_hash_raw="""+json.encode("")+"""\r"""+
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
  print(param3);
  
  var transaction_data = await Chaquopy.executeCode(param3+controller);

  print('====transaction_data=====');
  print(transaction_data['textOutputOrError']);
  Map data = await jsonDecode(transaction_data['textOutputOrError']);

  
  //test to POST a transaction
  var url =nig_hostname+'/transactions';
  //encode Map to JSON
  data.removeWhere((key, value) => key == "transaction_amount");
  print("===transaction details===");
  print(data['transaction']['timestamp']);
  


  var body2 = json.encode(data);
  //var body = data;
  print('====body2=====');
  print(body2);

  var response_post = await http.post(Uri.parse(url),
      headers: {"Content-Type": "application/json"},
      body: body2
  );
  if (response_post.statusCode == 503 || response_post.statusCode == 302) {
    //the server is in maintenance
    //let's restart the application
    Restart.restartApp();
  }

  




  return "None";
}