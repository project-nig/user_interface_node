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

import 'account_selection_catalog.dart';
import 'account_selection_item_tile.dart';


class AccountSelectionHome extends StatelessWidget {
  const AccountSelectionHome({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AccountSelectionCatalog>(
      create: (context) => AccountSelectionCatalog(),
      child: const MaterialApp(
        title: "Selection d'un compte",
        home: AccountSelection(),
      ),
    );
  }
}

class AccountSelection extends StatefulWidget {
  const AccountSelection({super.key});

  @override
  State<AccountSelection> createState() => _AccountSelectionState();
}


class _AccountSelectionState extends State<AccountSelection> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Selection d'un compte"),
      ),
      body: Selector<AccountSelectionCatalog, int?>(
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
            var catalog = Provider.of<AccountSelectionCatalog>(context);

            // Catalog provides a single synchronous method for getting
            // the current data.
            var item = catalog.getByIndex(index);

            if (item.isLoading) {
              return const LoadingItemTile();
            }

            return ItemTile(item: item);
          },
        ),
      ),
    );
  }
}


