// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

class Item {
  final int position;
  final String name;
  final int score;
  Item({
    required this.position,
    required this.name,
    required this.score,
  });

  Item.loading() : this(position: 0, name: '...', score: 0);

  bool get isLoading => name == '...';
}