import 'dart:async';

import 'account_file.dart';


Future <Map> ActiveAccount() async  {
  print('====ActiveAccount=====');
  var account = new Map();
  final AccountList = await readAccountList();
  //print("==AccountList==");
  //print(AccountList.account_list);
  for (var other_account in AccountList.account_list) {
    if (other_account['active']==true){
      account=other_account;
      break;
    }
  }
  return account;
}
