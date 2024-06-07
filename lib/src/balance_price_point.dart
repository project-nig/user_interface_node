import 'package:collection/collection.dart';

import 'package:http/http.dart' as http;
import 'parameters.dart';
import 'dart:convert';
import 'account_getactive.dart';

class PricePoint {
  final double x;
  final double y;

  PricePoint({required this.x, required this.y});

  factory PricePoint.fromJson(Map<String, dynamic> json) {
    return PricePoint(
      x: json['x'],
      y: json['y'],
    );
  }
}

Future<List<PricePoint>> pricePoints_year() async {
  final public_key_data = await ActiveAccount();
  var public_key=public_key_data["public_key_hash"];
  var response_total = await http.get(Uri.parse(nig_hostname+'/utxo/'+public_key));
  var result_total= jsonDecode(response_total.body);
  var response = await http.get(Uri.parse(nig_hostname+'/nig_value_projection_year/'+result_total['total'].toString()));
  var result= jsonDecode(response.body);
  final randomNumbers = <double>[];
  for (var i = 0; i <= 5; i++) {
    randomNumbers.add(double.parse(result[i]));
  }
  return randomNumbers
      .mapIndexed(
          (index, element) => PricePoint(x: index.toDouble(), y: element))
      .toList();
  } 

Future<List<PricePoint>> pricePoints_future() async {
  final public_key_data = await ActiveAccount();
  var public_key=public_key_data["public_key_hash"];
  var response_total = await http.get(Uri.parse(nig_hostname+'/utxo/'+public_key));
  var result_total= jsonDecode(response_total.body);
  var response = await http.get(Uri.parse(nig_hostname+'/nig_value_projection_future/'+result_total['total'].toString()));
  var result= jsonDecode(response.body);
  final randomNumbers = <double>[];
  for (var i = 0; i <= 5; i++) {
    randomNumbers.add(double.parse(result[i]));
  }
  return randomNumbers
      .mapIndexed(
          (index, element) => PricePoint(x: index.toDouble(), y: element))
      .toList();
  } 

