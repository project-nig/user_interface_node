// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:restart_app/restart_app.dart';

import 'item.dart';
import 'page.dart';
import '../parameters.dart';

import '../account_getactive.dart';

const catalogLength = 3;

/// This function emulates a REST API call. You can imagine replacing its
/// contents with an actual network call, keeping the signature the same.
///
/// It will fetch a page of items from [startingIndex].
Future<ItemPage> fetchPage(int startingIndex) async {

  // Extraction of the pulic key
  //final String public_key_response = await rootBundle.loadString('assets/nig_data.json');
  //final public_key_data = await json.decode(public_key_response);
  final public_key_data = await ActiveAccount();
  var public_key=public_key_data["public_key_hash"];
  List<Item> fetched_account_list =[] ;
  print("public_key_hash");
  print(public_key);
  final response = await http.get(Uri.parse(nig_hostname+'/utxo_balance/'+public_key));
  if (response.statusCode == 200) {
  // If the server did return a 200 OK response,
  // then parse the JSON.
  var fetched_account = FetchedAccount.fromJson(jsonDecode(response.body));
  for (var elem in fetched_account.utxos) {
    var balance=elem['balance'];
    var amount=elem['amount'];
    var color=Colors.grey;
    if (balance=="debit"){
      color=Colors.red;
      amount=-amount;};
    if (balance=="credit"){color=Colors.green;};

    fetched_account_list.add(Item(
      color: color,
      name: elem['user'],
      price: elem['amount'],
    ));
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

  // If the [startingIndex] is beyond the bounds of the catalog, an
  // empty page will be returned.
  if (startingIndex > catalogLength) {
    return ItemPage(
      items: [],
      startingIndex: startingIndex,
      hasNext: false,
    );
  }

  // The page of items is generated here.
  return ItemPage(
    items: fetched_account_list,
    startingIndex: startingIndex,
    // Returns `false` if we've reached the [catalogLength].
    hasNext: startingIndex + itemsPerPage < catalogLength,
  );
}

class FetchedAccount {
  final dynamic total_credit;
  final dynamic total_debit;
  final List utxos;

  const FetchedAccount({
    required this.total_credit,
    required this.total_debit,
    required this.utxos,
  });

  factory FetchedAccount.fromJson(Map<String, dynamic> json) {
    return FetchedAccount(
      total_credit: json['total_credit'],
      total_debit: json['total_debit'],
      utxos: json['utxos'],
    );
  }
}