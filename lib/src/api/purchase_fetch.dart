// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:restart_app/restart_app.dart';

import 'purchase_item.dart';
import 'purchase_page.dart';
import '../parameters.dart';
import '../account_getactive.dart';
import '../account_file.dart';

const catalogLength = 3;

/// This function emulates a REST API call. You can imagine replacing its
/// contents with an actual network call, keeping the signature the same.
///
/// It will fetch a page of items from [startingIndex].
Future<Marketplace1_sellItemPage> fetchPage(int startingIndex) async {

  // Extraction of the pulic key
  //final String public_key_response = await rootBundle.loadString('assets/nig_data.json');
  //final public_key_data = await json.decode(public_key_response);
  var public_key_data = await ActiveAccount();
  var user_public_key_hash=public_key_data["public_key_hash"];
  List<Marketplace1_sellItem> fetched_marketplace1_list =[] ;
  print("user_public_key_hash");
  print(user_public_key_hash);
  var purchase_amount=await readPurchaseAmount();
  var response = await http.get(Uri.parse(nig_hostname+'/marketplace_step/-1/'+user_public_key_hash+'/'+purchase_amount.toString()));
    if (response.statusCode == 200) {
    // If the server did return a 200 OK response,
    // then parse the JSON.
    var fetched_results = FetchedMarketplace1.fromJson(jsonDecode(response.body));

    for (var elem in fetched_results.results) {
      if (elem['readonly_flag']==false){
        var color=Colors.grey;
        fetched_marketplace1_list.add(Marketplace1_sellItem(
          color: color,
          requester_public_key_hash: elem['seller_public_key_hash'],
          requested_amount: elem['requested_amount'],
          requested_nig: elem['requested_nig'],
          requested_gap: elem['requested_gap'],
          timestamp: elem['timestamp_nig'],
          payment_ref: elem['payment_ref'],
          smart_contract_ref: elem['smart_contract_ref'],
          readonly_flag: elem['readonly_flag'],
          seller_reput_trans: elem['seller_reput_trans'],
          seller_reput_reliability: elem['seller_reput_reliability'].toDouble(),
        ));
        }
    };
  } else if (response.statusCode == 503 || response.statusCode == 302) {
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
    return Marketplace1_sellItemPage(
      items: [],
      startingIndex: startingIndex,
      hasNext: false,
    );
  }

  // The page of items is generated here.
  return Marketplace1_sellItemPage(
    items: fetched_marketplace1_list,
    startingIndex: startingIndex,
    // Returns `false` if we've reached the [catalogLength].
    hasNext: startingIndex + itemsPerPage < catalogLength,
  );
}

class FetchedMarketplace1 {
  final List results;

  const FetchedMarketplace1({
    required this.results,
  });

  factory FetchedMarketplace1.fromJson(Map<String, dynamic> json) {
    return FetchedMarketplace1(
      results: json['results'],
    );
  }
}