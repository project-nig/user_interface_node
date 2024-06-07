// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.


import 'package:flutter/material.dart';

class AccountSelectionItem {
  final Color color;
  final String name;
  final bool active;
  final String public_key_hash;

  AccountSelectionItem({
    required this.color,
    required this.name,
    required this.active,
    required this.public_key_hash,
  });

  AccountSelectionItem.loading() : this(color: Colors.grey, name: '...', active: false, public_key_hash: "");

  bool get isLoading => public_key_hash == '';
}