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
import 'package:restart_app/restart_app.dart';

import 'catalog.dart';
import 'item_tile.dart';
import 'account_getactive.dart';

import 'dart:developer';
import 'parameters.dart';




import 'package:flutter/material.dart';
import 'ethereum_service.dart';



class BalanceDemo extends StatefulWidget {
  const BalanceDemo({super.key});
  @override
  _BalanceDemoState createState() => _BalanceDemoState();
}

class _BalanceDemoState extends State<BalanceDemo> {
  final EthereumService _ethereumService = EthereumService();
  String _value = "Loading...";

  @override
  void initState() {
    super.initState();
    fetchValueFromContract();
  }

  Future<void> fetchValueFromContract() async {
    try {
      final result = await _ethereumService.query("getCurrentPrice", []);
      setState(() {
        _value = result[0].toString(); // Assume the value is a single number
      });
    } catch (e) {
      setState(() {
        _value = "Error: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Smart Contract Value"),
      ),
      body: Center(
        child: Text(
          "Value from Contract: $_value",
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}





