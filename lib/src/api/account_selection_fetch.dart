// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'dart:convert';

import 'account_selection_item.dart';
import 'account_selection_page.dart';

import '../account_file.dart';

const catalogLength = 3;

/// This function emulates a REST API call. You can imagine replacing its
/// contents with an actual network call, keeping the signature the same.
///
/// It will fetch a page of items from [startingIndex].
Future<AccountSelectionItemPage> fetchPage(int startingIndex) async {

  final AccountList = await readAccountList();
  List<AccountSelectionItem> fetched_accountselection_list =[] ;
    

  for (var elem in AccountList.account_list) {
    var color=Colors.grey;

    fetched_accountselection_list.add(AccountSelectionItem(
      color: color,
      name: elem['name'],
      active: elem['active'],
      public_key_hash: elem['public_key_hash'],
    ));
  };



  // If the [startingIndex] is beyond the bounds of the catalog, an
  // empty page will be returned.
  if (startingIndex > catalogLength) {
    return AccountSelectionItemPage(
      items: [],
      startingIndex: startingIndex,
      hasNext: false,
    );
  }

  // The page of items is generated here.
  return AccountSelectionItemPage(
    items: fetched_accountselection_list,
    startingIndex: startingIndex,
    // Returns `false` if we've reached the [catalogLength].
    hasNext: startingIndex + itemsPerPage < catalogLength,
  );
}

class FetchedAccountSelection {
  final List account_list;

  const FetchedAccountSelection({
    required this.account_list,
  });

  factory FetchedAccountSelection.fromJson(Map<String, dynamic> json) {
    return FetchedAccountSelection(
      account_list: json['account_list'],
    );
  }
}