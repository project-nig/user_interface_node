// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:restart_app/restart_app.dart';

import 'sell_followup_item.dart';
import 'sell_followup_page.dart';
import '../parameters.dart';
import '../account_getactive.dart';

const catalogLength = 3;

/// This function emulates a REST API call. You can imagine replacing its
/// contents with an actual network call, keeping the signature the same.
///
/// It will fetch a page of items from [startingIndex].
Future<Marketplace3ItemPage> fetchPage(int startingIndex) async {

  // Extraction of the pulic key
  //final String public_key_response = await rootBundle.loadString('assets/nig_data.json');
  //final public_key_data = await json.decode(public_key_response);
  var public_key_data = await ActiveAccount();
  var user_public_key_hash=public_key_data["public_key_hash"];
  List<Marketplace3Item> fetched_marketplace2_list =[] ;
  print("user_public_key_hash");
  print(user_public_key_hash);
  var response = await http.get(Uri.parse(nig_hostname+'/marketplace_step/3/'+user_public_key_hash));
    if (response.statusCode == 200) {
    // If the server did return a 200 OK response,
    // then parse the JSON.
    var fetched_results = FetchedMarketplace2.fromJson(jsonDecode(response.body));

    for (var elem in fetched_results.results) {
      var color=Colors.grey;

      fetched_marketplace2_list.add(Marketplace3Item(
        color: color,
        requester_public_key_hash: elem['requester_public_key_hash'],
        requested_amount: elem['requested_amount'],
        requested_nig: elem['requested_nig'],
        requested_gap: elem['requested_gap'],
        requested_currency: elem['requested_currency'],
        timestamp: elem['timestamp_nig'],
        payment_ref: elem['payment_ref'],
        smart_contract_ref: elem['smart_contract_ref'],
        readonly_flag: elem['readonly_flag'],
      ));
    };
  
  } 
  else if (response.statusCode == 503 || response.statusCode == 302 ) {
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
    return Marketplace3ItemPage(
      items: [],
      startingIndex: startingIndex,
      hasNext: false,
    );
  }

  // The page of items is generated here.
  return Marketplace3ItemPage(
    items: fetched_marketplace2_list,
    startingIndex: startingIndex,
    // Returns `false` if we've reached the [catalogLength].
    hasNext: startingIndex + itemsPerPage < catalogLength,
  );
}

class FetchedMarketplace2 {
  final List results;

  const FetchedMarketplace2({
    required this.results,
  });

  factory FetchedMarketplace2.fromJson(Map<String, dynamic> json) {
    return FetchedMarketplace2(
      results: json['results'],
    );
  }
}