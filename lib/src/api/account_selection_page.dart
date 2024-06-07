// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'account_selection_item.dart';

const int itemsPerPage = 20;

class AccountSelectionItemPage {
  final List<AccountSelectionItem> items;

  final int startingIndex;

  final bool hasNext;

  AccountSelectionItemPage({
    required this.items,
    required this.startingIndex,
    required this.hasNext,
  });
}