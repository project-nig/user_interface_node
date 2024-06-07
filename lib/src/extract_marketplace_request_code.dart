import 'package:http/http.dart' as http;
import 'parameters.dart';
import 'dart:convert';
import 'package:restart_app/restart_app.dart';

extract_marketplace_request_code(script) async {
  var payload=null;
  var smart_contract_account="None";
  if (script=="marketplace_script1_3"){
    smart_contract_account=MARKETPLACE_CODE_PUBLIC_KEY_HASH;
    payload="""\r
memory_obj_2_load=['marketplace_request_code']
return marketplace_request_code.code
""";
  }
  if (script=="reputation_script"){
    smart_contract_account=REPUTATION_CODE_PUBLIC_KEY_HASH;
    
    payload="""\r
memory_obj_2_load=['reputation_code']
return reputation_code.code
""";
  }
  var body = {
        'smart_contract_type': 'api',
        'smart_contract_public_key_hash': smart_contract_account,
        'sender_public_key_hash': 'sender_public_key_hash',
        'payload':payload,
      };
  var jsonString = json.encode(body);
  var marketplace_request_code_response = await http.post(Uri.parse(nig_hostname+'/smart_contract'),headers: {"Content-Type": "application/json"}, body: jsonString);
  if (marketplace_request_code_response.statusCode == 503 || marketplace_request_code_response.statusCode == 302) {
      //the server is in maintenance
      //let's restart the application
      Restart.restartApp();
    }
  else {
    return jsonDecode(marketplace_request_code_response.body)['smart_contract_result'];
    }
  return "null";
  }

