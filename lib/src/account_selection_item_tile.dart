// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:form_app/src/api/item.dart';
import 'package:json_annotation/json_annotation.dart';
import 'api/account_selection_item.dart';
import 'nig_engine.dart';
import 'package:chaquopy/chaquopy.dart';
import 'package:flutter/services.dart';
import 'dart:convert';

import 'account_file.dart';


Future<Account> fetchAccount(var item) async {
  final account_private_key = await GetAccountPrivateKey();
  final String controller = await rootBundle.loadString('assets/nig_decrypt.py');
  final param = "account_raw="""+json.encode(item.account)+"""\r"""+
  "action_raw="""+json.encode('account')+"""\r"""+
  "pin_encrypted_raw="""+json.encode('')+"""\r"""+
  "account_private_key_raw="""+json.encode(account_private_key)+"""\r""";
  print('====param=====');
  print(param);
  final transaction_data = await Chaquopy.executeCode(param+controller);
  print('====transaction_data=====');
  debugPrint(transaction_data['textOutputOrError']);
  Map data = jsonDecode(transaction_data['textOutputOrError']);
  var decrypt = data['decrypted_account'];
  return Account(name: decrypt['name'],iban: decrypt['iban'],bic: decrypt['bic'],email: decrypt['email'],phone: decrypt['phone'],country: decrypt['country'],pin: decrypt['pin'],requested_amount:item.requested_amount,requested_nig:item.requested_nig,requested_currency:item.requested_currency,requester_public_key_hash:item.requester_public_key_hash,account:item.account,timestamp:item.timestamp,payment_ref:item.payment_ref,smart_contract_ref:item.smart_contract_ref);
}

class Account {
  final String name;
  final String iban;
  final String bic;
  final String email;
  final String phone;
  final String country;
  final int pin;
  final double requested_amount;
  final double requested_nig;
  final String requested_currency;
  final String requester_public_key_hash;
  final String account;
  final double timestamp;
  final String payment_ref;
  final String smart_contract_ref;

  const Account({
    required this.name,
    required this.iban,
    required this.bic,
    required this.email,
    required this.phone,
    required this.country,
    required this.pin,
    required this.requested_amount,
    required this.requested_nig,
    required this.requested_currency,
    required this.requester_public_key_hash,
    required this.account,
    required this.timestamp,
    required this.payment_ref,
    required this.smart_contract_ref,
  });

  factory Account.fromJson(Map<String, dynamic> json) {
    return Account(
      name: json['name'],
      iban: json['iban'],
      bic: json['bic'],
      email: json['email'],
      phone: json['phone'],
      country: json['country'],
      pin: json['pin'],
      requested_amount: json['requested_amount'],
      requested_nig: json['requested_nig'],
      requested_currency: json['requested_currency'],
      requester_public_key_hash: json['requester_public_key_hash'],
      account: json['account'],
      timestamp: json['timestamp'],
      payment_ref: json['payment_ref'],
      smart_contract_ref: json['smart_contract_ref'],

    );
  }
}



/// This is the widget responsible for building the item in the list,
/// once we have the actual data [item].
class ItemTile extends StatelessWidget {
  final AccountSelectionItem item;

  const ItemTile({required this.item, super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ListTile(
        leading: AspectRatio(
          aspectRatio: 1,
          child: ElevatedButton(
            child: const Text('Sélectionner'),
            onPressed: () async {
              print("test 1 button");
              SetAccountActive(item.public_key_hash);
              print(item.public_key_hash);
              print("test 2 button");
              
            },
        ),
        ),
        title: Text(item.public_key_hash, style: Theme.of(context).textTheme.titleLarge),
        trailing: Text('\$ ${(item.active )}'),

      ),
    );
  }
}

/// This is the widget responsible for building the "still loading" item
/// in the list (represented with "..." and a crossed square).
class LoadingItemTile extends StatelessWidget {
  const LoadingItemTile({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ListTile(
        leading: const AspectRatio(
          aspectRatio: 1,
          child: Placeholder(),
        ),
        title: Text('...', style: Theme.of(context).textTheme.titleLarge),
        trailing: const Text('\$ ...'),
      ),
    );
  }

}