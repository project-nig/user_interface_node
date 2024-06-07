import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'package:chaquopy/chaquopy.dart';
import 'package:restart_app/restart_app.dart';
import 'account_getactive.dart';

import 'dart:developer';
import 'parameters.dart';
import 'account_file.dart';




Future <Result> launchNigContest(var requester_public_key_hash,var requested_name) async  {
  print('====launchNigContest=====');
  var result_status=true;
  dynamic result_statusCode='200';
  var marketplace_public_key_hash = "31f2ac8088005412c7b031a6e342b17a65a48d01";
  //STEP 0 -Ensure that participant is not yet registered to contest
  var marketplace_api_utxo_url=null;
  marketplace_api_utxo_url=nig_hostname+'/smart_contract_api/'+CONTEST_PUBLIC_KEY_HASH;
  var marketplace_api_utxo_response = await http.get(Uri.parse(marketplace_api_utxo_url));
  if (marketplace_api_utxo_response.statusCode == 503 || marketplace_api_utxo_response.statusCode == 302) {
      //the server is in maintenance
      //let's restart the application
      Restart.restartApp();
    }
  var marketplace_api_utxo_json=jsonDecode(marketplace_api_utxo_response.body);
  var smart_contract_previous_transaction=marketplace_api_utxo_json['smart_contract_previous_transaction'];
  var smart_contract_transaction_hash=marketplace_api_utxo_json['smart_contract_transaction_hash'];


  var participant_script3="""\r
memory_obj_2_load=['contest']
contest.check_participant('$requester_public_key_hash')
""";

  var payload=participant_script3;
  var marketplace_utxo_url=nig_hostname+'/smart_contract';
  print('====marketplace_utxo_url=====');
  print(marketplace_utxo_url);

  print('====payload=====');
  print(participant_script3);

  var body = {
      'smart_contract_type': 'api',
      'smart_contract_public_key_hash': CONTEST_PUBLIC_KEY_HASH,
      'sender_public_key_hash': 'sender_public_key_hash',
      'smart_contract_transaction_hash': smart_contract_transaction_hash,
      'smart_contract_previous_transaction': smart_contract_transaction_hash,
      'payload':payload,
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
  var smart_contract_error_flag=marketplace_utxo_json['smart_contract_error_flag'];
  var check_already_exist=marketplace_utxo_json['smart_contract_result'];

  if (smart_contract_error_flag == false ) {
    if (check_already_exist == false) {



      //STEP 1 - creation of a new Smart Contract address
      var response_total_create_smart_contract_account = await http.get(Uri.parse(nig_hostname+'/create_smart_contract_account'));
      var smart_contract_ref=jsonDecode(response_total_create_smart_contract_account.body);
      print("smart_contract_ref");
      print(smart_contract_ref);

      //STEP 2 - creation of a new Smart Contract for the participant
      var participant_script1="""\r
###VERSION:1
###END
class Participant:
    def __init__(self,smart_contract_account,public_key_hash,name):
        if smart_contract_account is None or smart_contract_account=='None':raise ValueError('smart_contract_account is missing')
        else:self.smart_contract_account=smart_contract_account
        if public_key_hash is None or public_key_hash=='None':raise ValueError('public_key_hash is missing')
        else:self.public_key_hash=public_key_hash
        if name is None or name=='None':raise ValueError('name is missing')
        else:self.name=name
        self.score=0
        self.total_debit=0
        self.profit=0

    def get_score_data(self):
        self.score=int(round(self.profit*self.total_debit, 0)/10000)
        return [self.name,self.score]

    def refresh_score(self):
        try:
            utxo=GET_UTXO(self.public_key_hash)
            total_euro=normal_round(utxo['total']*NIG_RATE(),ROUND_VALUE_DIGIT)
            total_debit=0
            for key in utxo['balance']['debit'].keys():
                total_debit+=utxo['balance']['debit'][key]['amount']*NIG_RATE(timestamp=utxo['balance']['debit'][key]['timestamp'])
            self.total_debit=total_debit
            total_credit=0
            for key in utxo['balance']['credit'].keys():
                total_credit+=utxo['balance']['credit'][key]['amount']*NIG_RATE(timestamp=utxo['balance']['credit'][key]['timestamp'])
            self.profit=total_euro+(total_credit-total_debit)
            self.score=int(round(self.profit*self.total_debit, 0)/10000)
        except Exception as e:
            logging.info(f"###INFO refresh_score issue: {e}")
            logging.exception(e)

""";
        
        var participant_script2="""\r
participant=Participant('$smart_contract_ref','$requester_public_key_hash','$requested_name')
memory_list.add([participant,'participant',['public_key_hash','name','score','total_debit','profit']])
123456
""";

      payload=participant_script1+participant_script2;
      marketplace_utxo_url=nig_hostname+'/smart_contract_creation';
      print('====marketplace_utxo_url=====');
      print(marketplace_utxo_url);

      print('====payload=====');
      print(participant_script2);

      body = {
        'smart_contract_public_key_hash': smart_contract_ref,
        'sender_public_key_hash': 'sender_public_key_hash',
        'payload':payload,
      };
      jsonString = json.encode(body);
      print('====jsonString=====');
      print(jsonString);

      marketplace_utxo_response = await http.post(Uri.parse(marketplace_utxo_url),headers: {"Content-Type": "application/json"}, body: jsonString);
      if (marketplace_utxo_response.statusCode == 503 || marketplace_utxo_response.statusCode == 302) {
        //the server is in maintenance
        //let's restart the application
        Restart.restartApp();
      }

      var utxo_url=nig_hostname+'/utxo/'+marketplace_public_key_hash;
      var utxo_response = await http.get(Uri.parse(utxo_url));
      if (utxo_response.statusCode == 503 || utxo_response.statusCode == 302) {
        //the server is in maintenance
        //let's restart the application
        Restart.restartApp();
      }
      var utxo_json=jsonDecode(utxo_response.body);

      print('====utxo_json=====');
      print(utxo_json);

      marketplace_utxo_json=jsonDecode(marketplace_utxo_response.body);
      //print("*******smart_contract_new");
      //print(marketplace_utxo_json['smart_contract_new']);
      //print("*******marketplace_utxo_json");

      if (marketplace_utxo_json['smart_contract_error_flag']==false ) {

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
        smart_contract_previous_transaction=marketplace_utxo_json['smart_contract_previous_transaction'];
        smart_contract_transaction_hash=marketplace_utxo_json['smart_contract_transaction_hash'];

        //construction of the transaction
        var action = "smart_contract_creation";
        var controller = await rootBundle.loadString('assets/nig_script.py');
        var account_temp_input=false;
        var account_temp_output=true;
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
        "private_key_raw="""+json.encode("")+"""\r"""+
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

        print('====transaction_data11=====');
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


        var body2 = json.encode(data);
        //var body = data;
        print('====body2=====');
        log(body2);

        var response_post = await http.post(Uri.parse(url),
            headers: {"Content-Type": "application/json"},
            body: body2
        );
        if (response_post.statusCode == 503 || response_post.statusCode == 302) {
          //the server is in maintenance
          //let's restart the application
          Restart.restartApp();
        }

        print('====STEP 3 - add the participant to the contest=====');
        //STEP 3 - add the participant to the contest
        marketplace_api_utxo_url=null;
        marketplace_api_utxo_url=nig_hostname+'/smart_contract_api/'+CONTEST_PUBLIC_KEY_HASH;
        marketplace_api_utxo_response = await http.get(Uri.parse(marketplace_api_utxo_url));
        if (marketplace_api_utxo_response.statusCode == 503 || marketplace_api_utxo_response.statusCode == 302) {
          //the server is in maintenance
          //let's restart the application
          Restart.restartApp();
        }
        marketplace_api_utxo_json=jsonDecode(marketplace_api_utxo_response.body);
        smart_contract_previous_transaction=marketplace_api_utxo_json['smart_contract_previous_transaction'];
        smart_contract_transaction_hash=marketplace_api_utxo_json['smart_contract_transaction_hash'];

        
        participant_script3="""\r
memory_obj_2_load=['contest']
contest.add_participant('$requester_public_key_hash','$smart_contract_ref')
memory_list.add([contest,'contest',['participant_list','ranking']])
123456
""";

        payload=participant_script3;
        marketplace_utxo_url=nig_hostname+'/smart_contract';
        print('====marketplace_utxo_url=====');
        print(marketplace_utxo_url);

        print('====payload=====');
        print(participant_script3);

        body = {
            'smart_contract_type': 'source',
            'smart_contract_public_key_hash': CONTEST_PUBLIC_KEY_HASH,
            'sender_public_key_hash': 'sender_public_key_hash',
            'smart_contract_transaction_hash': smart_contract_transaction_hash,
            'smart_contract_previous_transaction': smart_contract_transaction_hash,
            'payload':payload,
          };
        jsonString = json.encode(body);
        print('====jsonString=====');
        print(jsonString);

        marketplace_utxo_response = await http.post(Uri.parse(marketplace_utxo_url),headers: {"Content-Type": "application/json"}, body: jsonString);
        if (marketplace_utxo_response.statusCode == 503 || marketplace_utxo_response.statusCode == 302) {
          //the server is in maintenance
          //let's restart the application
          Restart.restartApp();
        }
        utxo_url=nig_hostname+'/utxo/'+CONTEST_PUBLIC_KEY_HASH;
        utxo_response = await http.get(Uri.parse(utxo_url));
        if (utxo_response.statusCode == 503 || utxo_response.statusCode == 302) {
          //the server is in maintenance
          //let's restart the application
          Restart.restartApp();
        }
        utxo_json=jsonDecode(utxo_response.body);
        print('====utxo_json=====');
        print(utxo_json);

        marketplace_utxo_json=jsonDecode(marketplace_utxo_response.body);
        //print("*******smart_contract_new");
        //print(marketplace_utxo_json['smart_contract_new']);
        //print("*******marketplace_utxo_json");

        //print(marketplace_utxo_json);
        
        if (marketplace_utxo_json['smart_contract_error_flag']==false ) {

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

            //construction of the transaction
            action = "smart_contract_update";
            var controller2 = await rootBundle.loadString('assets/nig_script.py');
            account_temp_input=false;
            account_temp_output=true;
            interface_public_key_hash ="1f8da1bae39c78bf4d8f9f3b8727e50001eed5ae";
            
            param = "action_raw="""+json.encode(action)+"""\r"""+
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
            "private_key_raw="""+json.encode("")+"""\r"""+
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

            "smart_contract_ref_raw="""+json.encode(CONTEST_PUBLIC_KEY_HASH)+"""\r"""+

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

              

            param1=param.replaceAll('false', "False");
            param2=param1.replaceAll('null', "None");
            param3=param2.replaceAll('true', "True");

            print("===param");
            log(param3);
            
            transaction_data = await Chaquopy.executeCode(param3+controller2);

            print('====transaction_data=====');
            log(transaction_data['textOutputOrError']);
            Map data2 = jsonDecode(transaction_data['textOutputOrError']);

            
            //test to POST a transaction
            url =nig_hostname+'/transactions';
            //encode Map to JSON
            data2.removeWhere((key, value) => key == "transaction_amount");
            print("===transaction details===");
            

            body2 = json.encode(data2);
            // body = data;
            print('====body2=====');
            log(body2);

            response_post = await http.post(Uri.parse(url),
                headers: {"Content-Type": "application/json"},
                body: body2
            );
            if (response_post.statusCode == 503 || response_post.statusCode == 302) {
              //the server is in maintenance
              //let's restart the application
              Restart.restartApp();
            }

            print('====response_post=====');
            //print(response_post.body);
            if (response_post.statusCode == 200) {
              // If the server did return a 200 OK response,
              result_status=true;
              //STEP 4 - refresh the score of the participant
              //var participant_refresh_url=nig_hostname+'/participant_refresh_score/'+requester_public_key_hash;
              //await http.get(Uri.parse(participant_refresh_url));
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
          }
            else {
          // Issue when creating the Participant SmartContract
          result_status=false;
          result_statusCode = marketplace_utxo_json['smart_contract_error_code'];}
        }
      else {
        // Issue when creating the Participant SmartContract
        result_status=false;
        result_statusCode = marketplace_utxo_json['smart_contract_error_code'];}
      }
      else {
        // The participant is already registered to the contest
        result_status=false;
        result_statusCode = "already subscribed";}
  }
  else {
      // Issue when creating the Participant SmartContract
      result_status=false;
      result_statusCode = marketplace_utxo_json['smart_contract_error_code'];}
  
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


