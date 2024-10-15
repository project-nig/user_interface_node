// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'purchase_item.dart';

const int itemsPerPage = 20;

class Marketplace1_sellItemPage {
  final List<Marketplace1_sellItem> items;

  final int startingIndex;

  final bool hasNext;

  Marketplace1_sellItemPage({
    required this.items,
    required this.startingIndex,
    required this.hasNext,
  });
}