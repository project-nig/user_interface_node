// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import 'api/item_contest.dart';

/// This is the widget responsible for building the item in the list,
/// once we have the actual data [item].
class ItemTile extends StatelessWidget {
  final Item item;

  const ItemTile({required this.item, super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ListTile(
        leading: AspectRatio(
          aspectRatio: 1,
          child: Container(
  constraints: BoxConstraints.expand(
    height: Theme.of(context).textTheme.headlineMedium!.fontSize! * 1 + 200.0,
  ),
  padding: const EdgeInsets.all(8.0),
  color: Colors.green[600],
  alignment: Alignment.center,
  transform: Matrix4.rotationZ(0.1),
  child: Text(item.position.toString(),
    style: Theme.of(context)
        .textTheme
        .titleLarge!
        .copyWith(color: Colors.white)),
)
        ),
        title: Text(item.name, style: Theme.of(context).textTheme.titleLarge),
        trailing: Text('${(item.score / 1).toStringAsFixed(0)} \pts'),
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