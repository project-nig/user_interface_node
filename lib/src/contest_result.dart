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

import 'catalog_contest.dart';
import 'item_tile_contest.dart';


class ContestResultHome extends StatelessWidget {
  const ContestResultHome({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<Catalog>(
      create: (context) => Catalog(),
      child: const MaterialApp(
        title: 'Classememt',
        home: ContestResult(),
      ),
    );
  }
}

class ContestResult extends StatefulWidget {
  const ContestResult({super.key});
  @override
  State<ContestResult> createState() => _ContestResultState();
}

class _ContestResultState extends State<ContestResult> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Classement'),
      ),
      body: Selector<Catalog, int?>(
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
            var catalog = Provider.of<Catalog>(context);

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


