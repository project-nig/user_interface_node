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

import 'package:shared_preferences/shared_preferences.dart';

import 'purchase_catalog.dart';
import 'purchase_item_tile.dart';
import 'account_file.dart';

import 'purchase_request.dart';


class PurchaseHome extends StatelessWidget {
  final SharedPreferences prefs;
  final double amount ;
  
  const PurchaseHome({
    required this.prefs,
    required this.amount,
    super.key});
  
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<PurchaseCatalog>(
      create: (context) => PurchaseCatalog(),
      child: MaterialApp(
        title: 'Achat de NIG',
        home: Purchase(prefs: prefs, amount:amount),
      ),
    );
  }
}

class Purchase extends StatefulWidget {
  final SharedPreferences prefs;
  final double amount ;
  
  const Purchase({
    required this.prefs,
    required this.amount,
    super.key});

  @override
  State<Purchase> createState() => _PurchaseState();
}


class _PurchaseState extends State<Purchase> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Achat de NIG'),
      ),
      body: Column(
        children: <Widget>[
          TextButton(
              child: const Text("Créer une demande d'achat"),
              onPressed: () async {
                Navigator.of(context).push(MaterialPageRoute(builder: (context) => PurchaseRequest(prefs: widget.prefs)));
              },
              ),
          Flexible(
            child: Container(
              child:
                Selector<PurchaseCatalog, int?>(
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
                      var catalog = Provider.of<PurchaseCatalog>(context);

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
            )
          )
        ]
      )
    );

  }
}


