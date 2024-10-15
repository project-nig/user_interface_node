// Copyright 2020, the Flutter project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:chaquopy/chaquopy.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import 'dart:developer';


// Demonstrates how to use autofill hints. The full list of hints is here:
// https://github.com/flutter/engine/blob/master/lib/web_ui/lib/src/engine/text_editing/autofill_hint.dart



Future<String> get _localPath async {
  final directory = await getApplicationDocumentsDirectory();
  print("directory.path");
  print(directory.path);
  return directory.path;
}

Future<File> get _localFile async {
  final path = await _localPath;
  try {return File('$path/account.txt');
  } catch (e) {
    // the file is not existing
    print("===info no account file");
    print(e);
    return new File('$path/account.txt');
  }
  
}

Future<File> writeAccount(String account_list) async {
  final file = await _localFile;
  // Write the file
  print("===check writeAccount");
  print(account_list);
  return file.writeAsString('$account_list');
}

class AccountList {
  final List account_list;

  const AccountList({
    required this.account_list,
  });

  factory AccountList.fromJson(Map<String, dynamic> json) {
    return AccountList(
      account_list: json['account_list'],
    );
  }
}

Future<AccountList> readAccountList() async {
  try {
    final file = await _localFile;

    //deletion of the file
    //file.deleteSync();

    // Read the file
    var account_list = await file.readAsString();
    print("===check account_list");
    log(account_list);
    // bug fixing with end of string
    if (account_list.endsWith(']}}')){
      account_list = account_list.substring(0, account_list.length - 1);
    };

    return AccountList.fromJson(jsonDecode(account_list));
  } catch (e) {
    print("===erreur with AccountList");
    print(e);
    // If encountering an error, return 0
    return AccountList(account_list:[]);
  }
}

Future<bool> SetAccountActive(String public_key_hash) async {
  // Read the file
  final AccountList = await readAccountList();
  
  //select the right account
  for (var elem in AccountList.account_list) {
    if (elem['public_key_hash']==public_key_hash){
      elem['active']=true;
    } else {
      elem['active']=false;
    };
  // Write the file
  var account_2_save = new Map();
  print("******SetAccountActive***");
  //print(AccountList.account_list);
  account_2_save['account_list']=AccountList.account_list;
  var account_2_save_json=json.encode(account_2_save);
  print(account_2_save_json);
  writeAccount(account_2_save_json);
  //writeAccount('account_2_save_json');
}
return true;
}

Future<String> GetAccountPrivateKey() async {
  // Read the file
  final AccountList = await readAccountList();
  String private_key='Null';
  
  //select the right account
  for (var elem in AccountList.account_list) {
    if (elem['active']==true){
      //this is the active account
      private_key=elem['private_key_str'];
      break;
    } 
}
return private_key;
}

//Notification management

Future<File> get _localNotificationFile async {
  final path = await _localPath;
  try {return File('$path/notification.txt');
  } catch (e) {
    // the file is not existing
    print("===info no notification file");
    print(e);
    return new File('$path/notification.txt');
  }
}


class NotificationList {
  final List notification_list;

  const NotificationList({
    required this.notification_list,
  });

  factory NotificationList.fromJson(Map<String, dynamic> json) {
    return NotificationList(
      notification_list: json['notification_list'],
    );
  }
}



Future<Map> readNotificationList(requester_public_key_hash) async {
  if (requester_public_key_hash != null){
    var now_str=1;
    var default_notification_timestamp_user_dict=new Map();
    default_notification_timestamp_user_dict['1']=now_str;
    default_notification_timestamp_user_dict['2']=now_str;
    default_notification_timestamp_user_dict['3']=now_str;
    default_notification_timestamp_user_dict['4']=now_str;
    default_notification_timestamp_user_dict['45']=now_str;
    default_notification_timestamp_user_dict['66']=now_str;
    default_notification_timestamp_user_dict['98']=now_str;
    default_notification_timestamp_user_dict['99']=now_str;
    try{
      final file = await _localNotificationFile;
      // Read the file
      String contents = await file.readAsString();
      var notification_timestamp_dict = jsonDecode(contents);
      //notification_timestamp_dict is existing
      //there is value for requester_public_key_hash
      var notification_timestamp_user_dict = notification_timestamp_dict[requester_public_key_hash];
      if (notification_timestamp_user_dict!=null){
        print("=== check notification_timestamp_dict 1");
        log(notification_timestamp_dict.toString());
        return notification_timestamp_dict;
      }
      else{
        //notification_timestamp_dict is not existing
        //creation of a default_notification_timestamp_user_dict for the user
        notification_timestamp_dict[requester_public_key_hash]=default_notification_timestamp_user_dict;
        if (notification_timestamp_dict[requester_public_key_hash]!=null) {
          print("=== check notification_timestamp_dict 2");
          log(notification_timestamp_dict.toString());
          return notification_timestamp_dict;
        }
        else{
          //notification_timestamp_dict is not existing
          //let's create a default one
          var notification_timestamp_dict_default=new Map();
          notification_timestamp_dict_default[requester_public_key_hash]=default_notification_timestamp_user_dict;
          print("=== check notification_timestamp_dict 3");
          log(notification_timestamp_dict_default.toString());
          return notification_timestamp_dict_default;
        }
      }
        
      
    }
    catch (e) {
      print("====>errror");
      print(e);
      //there is an unknow issue when reading the file
      //notification_timestamp_dict is not existing
      //let's create a default one
      var notification_timestamp_dict_default=new Map();
      notification_timestamp_dict_default[requester_public_key_hash]=default_notification_timestamp_user_dict;
      print("=== check notification_timestamp_dict 4");
      log(notification_timestamp_dict_default.toString());
      UpdateNotificationTimeStamp(notification_timestamp_dict_default);
      return notification_timestamp_dict_default;
    }
  };
  return new Map();
}

Future<File> UpdateNotificationTimeStamp(notification_timestamp_dict) async {
  final file = await _localNotificationFile;
  // Write the file
  return file.writeAsString(json.encode(notification_timestamp_dict));
}

//management of Purchase Amount
Future<File> get _localPurchaseAmount async {
  final path = await _localPath;
  return File('$path/purchase_amount.txt');
}

Future<File> UpdatePurchaseAmount(purchase_amount) async {
  final file = await _localPurchaseAmount;
  // Write the file
  return file.writeAsString(json.encode(purchase_amount));
}

readPurchaseAmount() async {
  try {
    final file = await _localPurchaseAmount;
    // Read the file
    var purchase_amount = await file.readAsString();
    print("===check purchase_amount");
    log(purchase_amount);
    return jsonDecode(purchase_amount);
  } catch (e) {
    print("===erreur with readPurchaseAmount");
    print(e);
    // If encountering an error, return 0
    return 888888;
  }
}

//management of Sell Amount
Future<File> get _localSellAmount async {
  final path = await _localPath;
  return File('$path/sell_amount.txt');
}

Future<File> UpdateSellAmount(sell_amount) async {
  final file = await _localSellAmount;
  // Write the file
  return file.writeAsString(json.encode(sell_amount));
}

readSellAmount() async {
  try {
    final file = await _localSellAmount;
    // Read the file
    var sell_amount = await file.readAsString();
    print("===check sell_amount");
    log(sell_amount);
    return jsonDecode(sell_amount);
  } catch (e) {
    print("===erreur with readSellAmount");
    print(e);
    // If encountering an error, return 0
    return 888888;
  }
}