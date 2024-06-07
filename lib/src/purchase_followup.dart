import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'package:chaquopy/chaquopy.dart';

import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:window_size/window_size.dart';

import 'purchase_followup_catalog.dart';
import 'purchase_followup_item_tile.dart';

import 'package:shared_preferences/shared_preferences.dart';


class Purchase_followupHome extends StatelessWidget {
  final SharedPreferences prefs;

  const Purchase_followupHome({
    required this.prefs,
    super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<PurchaseFollowUpCatalog>(
      create: (context) => PurchaseFollowUpCatalog(),
      child:  MaterialApp(
        title: 'Suivi des achats',
        home: Purchase_followup(prefs: prefs),
      ),
    );
  }
}

class Purchase_followup extends StatefulWidget {
  final SharedPreferences prefs;

  const Purchase_followup({
    required this.prefs,
    super.key});

  @override
  State<Purchase_followup> createState() => _Purchase_followuState();
}


class _Purchase_followuState extends State<Purchase_followup> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Suivi des achats'),
      ),
      body: Selector<PurchaseFollowUpCatalog, int?>(
        // Selector is a widget from package:provider. It allows us to listen
        // to only one aspect of a provided value. In this case, we are only
        // listening to the catalog's `itemCount`, because that's all we need
        // at this level.
        selector: (context, catalog) => catalog.itemCount,
        builder: (context, itemCount, child) => ListView.builder(
          // When `itemCount` is null, `ListView` assumes an infinite list.
          // Once we provide a value, it will stop the scrolling beyond
          // the last element.
          itemCount: itemCount,
          padding: const EdgeInsets.symmetric(vertical: 18),
          itemBuilder: (context, index) {
            // Every item of the `ListView` is individually listening
            // to the catalog.
            var catalog = Provider.of<PurchaseFollowUpCatalog>(context);

            // Catalog provides a single synchronous method for getting
            // the current data.
            var item = catalog.getByIndex(index);

            if (item.isLoading) {
              return const LoadingItemTile();
            }

            return ItemTile(item: item,prefs: widget.prefs);
          },
        ),
      ),
    );
  }
}


