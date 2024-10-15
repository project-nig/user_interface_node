// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

class Marketplace1_sellItem {
  final Color color;
  final double requested_amount;
  final double requested_nig;
  final double requested_gap;
  final String requester_public_key_hash;
  final double timestamp;
  final String payment_ref;
  final String smart_contract_ref;
  final bool readonly_flag;
  final int seller_reput_trans;
  final double seller_reput_reliability;

  Marketplace1_sellItem({
    required this.color,
    required this.requester_public_key_hash,
    required this.requested_amount,
    required this.requested_nig,
    required this.requested_gap,
    required this.timestamp,
    required this.payment_ref,
    required this.smart_contract_ref,
    required this.readonly_flag,
    required this.seller_reput_trans,
    required this.seller_reput_reliability,
  });

  Marketplace1_sellItem.loading() : this(color: Colors.grey, requester_public_key_hash: '...', requested_nig: 0, requested_amount:0, requested_gap: 0,timestamp:0, payment_ref:"", smart_contract_ref:"",readonly_flag:false,seller_reput_trans:0,seller_reput_reliability:0.0);

  bool get isLoading => requester_public_key_hash == '...';
}