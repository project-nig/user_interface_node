// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:restart_app/restart_app.dart';

import 'item_contest.dart';
import 'page_contest.dart';
import '../parameters.dart';

import '../account_getactive.dart';

const catalogLength = 3;

/// This function emulates a REST API call. You can imagine replacing its
/// contents with an actual network call, keeping the signature the same.
///
/// It will fetch a page of items from [startingIndex].
Future<ItemPage> fetchPage(int startingIndex) async {
  List<Item> fetched_account_list =[] ;
  final response = await http.get(Uri.parse(nig_hostname+'/contest_refresh_ranking'));
  if (response.statusCode == 200) {
  // If the server did return a 200 OK response,
  // then parse the JSON.
  try{
    var fetched_account = FetchedAccount.fromJson(jsonDecode(response.body));
    for (var elem in fetched_account.ranking) {

      fetched_account_list.add(Item(
        position: elem[0],
        name: elem[1],
        score: elem[2],
      ));
    };
  }
  catch(e) {};
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
  final List ranking;

  const FetchedAccount({
    required this.ranking,
  });

  factory FetchedAccount.fromJson(Map<String, dynamic> json) {
    return FetchedAccount(
      ranking: json['ranking'],
    );
  }
}