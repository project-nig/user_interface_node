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


// Graph
import 'package:fl_chart/fl_chart.dart';
import 'balance_price_point.dart';


class LineChartWidget_year extends StatefulWidget {
  const LineChartWidget_year({Key? key, required this.points}) : super(key: key);

  final List<PricePoint> points;

  @override
  State<LineChartWidget_year> createState() => _LineChartWidget_yearState(points: this.points);
}

class _LineChartWidget_yearState extends State<LineChartWidget_year> {
  final List<PricePoint> points;
  late int showingTooltipSpot;
  

  _LineChartWidget_yearState({required this.points});

  @override
  void initState() {
    showingTooltipSpot = -1;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final _lineBarsData = [
      LineChartBarData(
        spots: points.map((point) => FlSpot(point.x, point.y)).toList(),
        isCurved: false,
        dotData: FlDotData(
          show: false,
        ),
        color: Colors.red
      ),
    ];
    return AspectRatio(
      aspectRatio: 2,
      child: LineChart(
        LineChartData(
            lineBarsData: _lineBarsData,
            borderData: FlBorderData(
                border: const Border(bottom: BorderSide(), left: BorderSide())),
            gridData: FlGridData(show: false),
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(sideTitles: _bottomTitles_year),
              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            showingTooltipIndicators: showingTooltipSpot != -1 ? [ShowingTooltipIndicators([
                LineBarSpot(_lineBarsData[0], showingTooltipSpot,
                    _lineBarsData[0].spots[showingTooltipSpot]),
              ])] : [],
            lineTouchData: LineTouchData(
                enabled: true,
                touchSpotThreshold: 20,
                touchTooltipData: LineTouchTooltipData(
                  tooltipBgColor: Colors.blue,
                  tooltipRoundedRadius: 20.0,
                  fitInsideHorizontally: true,
                  tooltipMargin: 0,
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map(
                      (LineBarSpot touchedSpot) {
                        const textStyle = TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        );
                        return LineTooltipItem(
                          points[touchedSpot.spotIndex].y.toStringAsFixed(0),
                          textStyle,
                        );
                      },
                    ).toList();
                  },
                ),
                handleBuiltInTouches: false,
                touchCallback: (event, response) {
                  if (response?.lineBarSpots != null && event is FlTapUpEvent) {
                    setState(() {
                      final spotIndex = response?.lineBarSpots?[0].spotIndex ?? -1;
                      if(spotIndex == showingTooltipSpot) {
                        showingTooltipSpot = -1;
                      }
                      else {
                        showingTooltipSpot = spotIndex;
                      }
                    });
                  }
                },
              ),
          ),
      ),
    );
  }

  SideTitles get _bottomTitles_year => SideTitles(
    showTitles: true,
    getTitlesWidget: (value, meta) {
      String text = '';
      switch (value.toInt()) {
        case 0:
          text = '1';
          break;
        case 1:
          text = '2';
          break;
        case 2:
          text = '3';
          break;
        case 3:
          text = '6';
          break;
        case 4:
          text = '9';
          break;
        case 5:
          text = '12';
          break;
      }

      return Text(text);
    },
  );
}

class LineChartWidget_future extends StatefulWidget {
  const LineChartWidget_future({Key? key, required this.points}) : super(key: key);

  final List<PricePoint> points;

  @override
  State<LineChartWidget_future> createState() => _LineChartWidget_futureState(points: this.points);
}

class _LineChartWidget_futureState extends State<LineChartWidget_future> {
  final List<PricePoint> points;
  late int showingTooltipSpot;
  

  _LineChartWidget_futureState({required this.points});

  @override
  void initState() {
    showingTooltipSpot = -1;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final _lineBarsData = [
      LineChartBarData(
        spots: points.map((point) => FlSpot(point.x, point.y)).toList(),
        isCurved: false,
        dotData: FlDotData(
          show: false,
        ),
        color: Colors.red
      ),
    ];
    return AspectRatio(
      aspectRatio: 2,
      child: LineChart(
        LineChartData(
            lineBarsData: _lineBarsData,
            borderData: FlBorderData(
                border: const Border(bottom: BorderSide(), left: BorderSide())),
            gridData: FlGridData(show: false),
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(sideTitles: _bottomTitles_year),
              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            showingTooltipIndicators: showingTooltipSpot != -1 ? [ShowingTooltipIndicators([
                LineBarSpot(_lineBarsData[0], showingTooltipSpot,
                    _lineBarsData[0].spots[showingTooltipSpot]),
              ])] : [],
            lineTouchData: LineTouchData(
                enabled: true,
                touchSpotThreshold: 20,
                touchTooltipData: LineTouchTooltipData(
                  tooltipBgColor: Colors.blue,
                  tooltipRoundedRadius: 20.0,
                  fitInsideHorizontally: true,
                  tooltipMargin: 0,
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map(
                      (LineBarSpot touchedSpot) {
                        const textStyle = TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        );
                        return LineTooltipItem(
                          points[touchedSpot.spotIndex].y.toStringAsFixed(0),
                          textStyle,
                        );
                      },
                    ).toList();
                  },
                ),
                handleBuiltInTouches: false,
                touchCallback: (event, response) {
                  if (response?.lineBarSpots != null && event is FlTapUpEvent) {
                    setState(() {
                      final spotIndex = response?.lineBarSpots?[0].spotIndex ?? -1;
                      if(spotIndex == showingTooltipSpot) {
                        showingTooltipSpot = -1;
                      }
                      else {
                        showingTooltipSpot = spotIndex;
                      }
                    });
                  }
                },
              ),
          ),
      ),
    );
  }

  SideTitles get _bottomTitles_year => SideTitles(
    showTitles: true,
    getTitlesWidget: (value, meta) {
      String text = '';
      switch (value.toInt()) {
        case 0:
          text = '1';
          break;
        case 1:
          text = '2';
          break;
        case 2:
          text = '3';
          break;
        case 3:
          text = '5';
          break;
        case 4:
          text = '7';
          break;
        case 5:
          text = '10';
          break;
      }

      return Text(text);
    },
  );


  
}


Future<Account> fetchAccount(context) async {
  // Extraction of the public key
  //final String public_key_response = await rootBundle.loadString('assets/nig_data.json');
  final public_key_data = await ActiveAccount();
  //final public_key_data = await json.decode(public_key_response);
  var public_key=public_key_data["public_key_hash"];
  var response = await http.get(Uri.parse(nig_hostname+'/utxo/'+public_key));

  if (response.statusCode == 200) {
    // If the server did return a 200 OK response,
    // then parse the JSON.
    print("response.body");
    log(response.body);
    return Account.fromJson(jsonDecode(response.body));
  } else {
    // If the server did not return a 200 OK response,
    if (response.statusCode == 503 || response.statusCode == 302) {
      //the server is in maintenance
      //let's restart the application
      Restart.restartApp();
    }
    // then throw an exception.
    throw Exception('Failed to load Account');
  }
}

class Account {
  final double total;
  final double total_euro;
  final double marketplace_profit;
  final double marketplace_total_debit_eur;
  final double marketplace_total_credit_eur;
  final String user;
  final List utxos;

  const Account({
    required this.total,
    required this.total_euro,
    required this.marketplace_profit,
    required this.marketplace_total_debit_eur,
    required this.marketplace_total_credit_eur,
    required this.user,
    required this.utxos,
  });

  factory Account.fromJson(Map<String, dynamic> json) {
    return Account(
      total: json['total'],
      total_euro: json['total_euro'],
      marketplace_profit : json['marketplace_profit'],
      marketplace_total_debit_eur : json['marketplace_total_debit_eur'],
      marketplace_total_credit_eur : json['marketplace_total_credit_eur'],
      user: json['user'],
      utxos: json['utxos'],
    );
  }
}

class BalanceDemo extends StatefulWidget {
  const BalanceDemo({super.key});

  @override
  State<BalanceDemo> createState() => _BalanceDemoState();
}

class _BalanceDemoState extends State<BalanceDemo> {
    late Future<Account> futureAccount;
    late Future<List<PricePoint>> futurePricePoint_year;
    late Future<List<PricePoint>> futurePricePoint_future;

  @override
  void initState() {
    super.initState();
    futureAccount = fetchAccount(context);
    futurePricePoint_year = pricePoints_year();
    futurePricePoint_future = pricePoints_future();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Balance'),
        ),
        body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 48.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
                FutureBuilder<Account>(
                future: futureAccount,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return DataTable(
                      columns: <DataColumn>[
                        DataColumn(
                          label: Expanded(
                            child: Text(
                              'Solde',
                              style: TextStyle(fontStyle: FontStyle.italic, fontSize: 30),
                            ),
                          ),
                        ),
                      ],
                      rows: <DataRow>[
                        DataRow(
                          cells: <DataCell>[
                            DataCell(Text('${snapshot.data!.total_euro.toString()+" €"}',style: TextStyle(fontSize: 24),)),
                          ],
                        ),
                        DataRow(
                          cells: <DataCell>[
                            DataCell(Text('${snapshot.data!.total.toString()+" NIG"}',style: TextStyle(fontSize: 18),)),
                          ],
                        ),
                        DataRow(
                          cells: <DataCell>[
                            DataCell(Text('Gains:    ${snapshot.data!.marketplace_profit.toString()+" €"}')),
                          ],
                        ),
                        DataRow(
                          cells: <DataCell>[
                            DataCell(Text('Achats:    ${snapshot.data!.marketplace_total_credit_eur.toString()+" €"}')),
                          ],
                        ),
                        DataRow(
                          cells: <DataCell>[
                            DataCell(Text('Ventes:    ${snapshot.data!.marketplace_total_debit_eur.toString()+" €"}')),
                          ],
                        ),
                      ],
                    );
                  } else if (snapshot.hasError) {
                    return Text('${snapshot.error}');
                  }

                  // By default, show a loading spinner.
                  return const CircularProgressIndicator();
                },
              ),

              FutureBuilder<List<PricePoint>>(
                future: futurePricePoint_year,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return LineChartWidget_year(points:snapshot.data!);
                    
                  } else if (snapshot.hasError) {
                    return Text('${snapshot.error}');
                  }

                  // By default, show a loading spinner.
                  return const CircularProgressIndicator();
                },
              ),
              Text("Projection sur l'année en € (mois) en €\n\n",style: TextStyle(fontSize: 20),),
              FutureBuilder<List<PricePoint>>(
                future: futurePricePoint_future,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return LineChartWidget_future(points:snapshot.data!);
                    
                  } else if (snapshot.hasError) {
                    return Text('${snapshot.error}');
                  }

                  // By default, show a loading spinner.
                  return const CircularProgressIndicator();
                },
              ),
              
              
              
              Text("Projection sur 10 ans en € (années)\n",style: TextStyle(fontSize: 20),),
              const Padding(padding: EdgeInsets.all(60)),
            ],
            
          ),
        ),
        
      )
    );
}

}

