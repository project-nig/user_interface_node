// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'purchase_followup_item.dart';

const int itemsPerPage = 20;

class Marketplace2ItemPage {
  final List<Marketplace2Item> items;

  final int startingIndex;

  final bool hasNext;

  Marketplace2ItemPage({
    required this.items,
    required this.startingIndex,
    required this.hasNext,
  });
}