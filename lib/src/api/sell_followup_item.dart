// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

class Marketplace3Item {
  final Color color;
  final double requested_amount;
  final double requested_nig;
  final String requested_currency;
  final String requester_public_key_hash;
  final double timestamp;
  final String payment_ref;
  final String smart_contract_ref;
  final bool readonly_flag;

  Marketplace3Item({
    required this.color,
    required this.requester_public_key_hash,
    required this.requested_amount,
    required this.requested_nig,
    required this.requested_currency,
    required this.timestamp,
    required this.payment_ref,
    required this.smart_contract_ref,
    required this.readonly_flag,
  });

  Marketplace3Item.loading() : this(color: Colors.grey, requester_public_key_hash: '...', requested_nig: 0,requested_currency: "", requested_amount:0, timestamp:0, payment_ref:"",smart_contract_ref:"",readonly_flag:false);

  bool get isLoading => requester_public_key_hash == '...';
}